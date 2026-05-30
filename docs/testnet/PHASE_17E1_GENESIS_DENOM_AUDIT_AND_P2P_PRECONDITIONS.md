# Phase 17E.1 Candidate Genesis Denom Audit And Real P2P Freeze Preconditions

**Date:** 2026-05-30
**Network:** `nexarail-testnet-1`
**Status:** `FREEZE_DEFER`

## Objective

Audit the controlled external-validator genesis candidate for staking/bond denom consistency in response to a NodeSync flag, and record the preconditions that must be satisfied for real CometBFT P2P readiness before the final public genesis can be frozen.

This phase does not launch the network. It is not mainnet. External decentralisation is not claimed. NXRL has no monetary value.

## NodeSync Clarification

NodeSync provided two clarifications after the Phase 17E TCP reachability check returned connection refused:

1. The Phase 17E TCP probe failed because the real `nexaraild` service was not started yet on the NodeSync VPS. This is expected before final genesis distribution.
2. NodeSync briefly bound a simple `nc` listener on port 26656 to demonstrate that the VPS itself is reachable on the wire.
3. NodeSync flagged a possible incorrect `bond_denom` in the candidate/default genesis.

Items 1 and 2 are noted. A `nc` listener proves only that inbound TCP on 26656 is not blocked by network or firewall, and is not evidence of CometBFT readiness. Item 3 required a formal denom audit.

## Denom Audit

### Method

A new script was added:

```text
scripts/testnet/check-genesis-denoms.sh
```

Flags:

```text
--genesis <path>
--expected-denom <denom>   (default: unxrl)
--output <path>            (optional JSON summary)
```

The script checks the following denom fields and scans for suspicious denom strings (`stake`, `uatom`, `atom`, `token`, `nstake`).

Checked paths:

- `app_state.staking.params.bond_denom`
- `app_state.mint.params.mint_denom`
- `app_state.gov.params.min_deposit[].denom` and legacy `gov.deposit_params.min_deposit[].denom`
- `app_state.crisis.constant_fee.denom`
- `app_state.bank.balances[].coins[].denom`
- `app_state.bank.supply[].denom`
- `app_state.bank.denom_metadata[].base` (warn if metadata is empty)
- `app_state.genutil.gen_txs[*].MsgCreateValidator.value.denom`
- `app_state.distribution.fee_pool.community_pool[].denom`

### Command

```bash
scripts/testnet/check-genesis-denoms.sh \
  --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
  --expected-denom unxrl \
  --output coordination/audits/phase17e1-denom-audit.json
```

### Result

```text
Result: PASS
PASS=7  FAIL=0  WARN=1
```

| Field | Status | Got |
|---|---|---|
| staking.params.bond_denom | PASS | unxrl |
| mint.params.mint_denom | PASS | unxrl |
| gov.*min_deposit.denom | PASS | unxrl |
| crisis.constant_fee.denom | PASS | unxrl |
| bank.balances[].coins[].denom | PASS | unxrl |
| bank.supply[].denom | PASS | unxrl |
| bank.denom_metadata | WARN | empty (non-blocking; explorer metadata not seeded) |
| genutil.gen_txs[*].MsgCreateValidator.value.denom | PASS | unxrl |
| distribution.fee_pool.community_pool[].denom | SKIP | not present |

Suspicious denom scan: no occurrences of `stake`, `uatom`, `atom`, `token`, or `nstake`.

Full machine-readable report:

```text
coordination/audits/phase17e1-denom-audit.json
```

### Interpretation

The candidate genesis denom configuration is correct. NodeSync's `bond_denom` concern was based on the field being missing or wrong; the audit confirms `staking.params.bond_denom = unxrl` and all linked denom fields are consistently `unxrl`. The single WARN (empty `bank.denom_metadata`) is a non-blocking explorer metadata gap and is tracked separately.

No genesis fix was required. The candidate file is byte-identical to the Phase 17D candidate.

### Candidate SHA256

Unchanged after audit:

```text
4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095  genesis.json
```

## Candidate Dry-Run

The candidate was re-run through the controlled coordinator dry-run with the same SHA256 to confirm the audit did not alter the candidate and that block production still reaches the minimum height.

Command:

```bash
scripts/testnet/run-controlled-testnet-dry-run.sh \
  --genesis releases/testnet-genesis/nexarail-testnet-1-candidate/genesis.json \
  --source-homes rehearsals/coordinator-candidate/runs/20260529T163048Z/homes \
  --expected-validators 6 \
  --min-height 50
```

Result (Phase 17E.1 re-run):

```text
timestamp_utc: 2026-05-30T08:35:47Z
status: PASS
pass: 11
fail: 0
validator_count: 6
height_verified: 50
genesis_sha256: 4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095
product_live_flags: false
panic/fatal markers: 0
```

Evidence path:

```text
rehearsals/controlled-testnet/dry-run/evidence/20260530T083028Z-phase17e1/
```

NodeSync remains in the genesis validator set but is not simulated locally; the coordinator-side five validators carry block production for the dry-run.

## Real P2P Freeze Preconditions

A temporary `nc` listener on TCP 26656 confirms only that the NodeSync VPS path to the coordinator is not blocked. It is not evidence that the chain can peer.

Real P2P readiness requires all of the following, in order, after the final public genesis is distributed:

1. NodeSync receives the frozen final public genesis file and verifies SHA256 against the coordinator-published value.
2. NodeSync places the final `genesis.json` into `<node-home>/config/genesis.json`.
3. NodeSync configures `config.toml`:
   - `p2p.laddr = "tcp://0.0.0.0:26656"`,
   - `p2p.external_address = "nexarail-testnet-peer.nodesync.top:26656"`,
   - `p2p.persistent_peers` includes the coordinator persistent peer(s) once published,
   - `p2p.pex = true`,
   - `p2p.seed_mode = false`.
4. NodeSync starts the real `nexaraild start` service (systemd unit or equivalent), not a placeholder listener.
5. NodeSync confirms `node_id` matches the gentx memo node ID `2bb62d82b4dbf820fdafd843816f1e72a84ffa8f`.
6. Coordinator verifies TCP reachability:
   ```bash
   nc -vz nexarail-testnet-peer.nodesync.top 26656
   nc -vz 178.104.162.88 26656
   ```
7. Coordinator verifies CometBFT P2P handshake by running a temporary coordinator node configured with the NodeSync persistent peer and confirms inbound/outbound peer count > 0 via `curl http://127.0.0.1:26657/net_info`.
8. Coordinator records the P2P evidence under `rehearsals/controlled-testnet/p2p-launch/evidence/<TIMESTAMP>/`.

A `nc` listener test or any non-CometBFT TCP listener does not satisfy precondition 7.

## Fixes Applied

None. Candidate genesis is correct as assembled.

The audit script is now available for future runs and CI gating.

## Freeze Decision

```text
FREEZE_DEFER
```

Reason: denom audit passes, but real CometBFT P2P readiness depends on NodeSync starting the real `nexaraild` service after final genesis distribution, and the coordinator verifying a real peer handshake. This sequencing is correct and expected; it is not a regression.

## Launch Status

Controlled external-validator testnet remains **NOT LAUNCHED**. No public testnet is live. Mainnet remains **NO-GO**. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
