# Phase 9U - Long Soak and Persistence-Safe Restart Results

**Date:** 2026-05-27  
**Chain:** `nexarail-agent-testnet-1`  
**Scope:** local 5-agent validator rehearsal only  
**Status:** Complete - clean-spawn soak passed; reuse-data restart unsafe for local agent rehearsals

## Duration

- Target: `60m`
- Actual: `3602s`
- Preferred `6h` and strong `24h` targets were not run in this OpenClaw execution window. The minimum Phase 9U soak target was completed.

## Clean-Spawn Baseline

The run started from a fresh clean spawn:

```bash
scripts/testnet/stop-validator-agents.sh
scripts/testnet/spawn-validator-agents.sh --clean
scripts/testnet/run-agent-soak-test.sh --duration 60m
scripts/testnet/agent-soak-summary.sh
```

Clean-spawn genesis checksum:

```text
efc6b3a89911275cdbc34d12e444b6a3264e186b41d7301714942c294eaa2fcb
```

## Soak Result

| Metric | Result |
|---|---:|
| Start height | 12 |
| Final height | 685 |
| Height delta | 673 |
| Average block time | 5.35s |
| Status samples | 61 |
| Agent sample rows | 305 |
| Peer count range | 4-4 |
| Validator set range | 5-5 |
| Panic count during soak | 0 |

The 19 soak error-scan entries were startup peer-dial retries and local pprof port reuse messages. No runtime panics were found during the clean-spawn soak.

## Query During Soak

Five full readback samples were captured during the run:

| Sample | Result |
|---:|---|
| 1 | 85 pass / 0 fail / 0 skip |
| 16 | 85 pass / 0 fail / 0 skip |
| 31 | 85 pass / 0 fail / 0 skip |
| 46 | 85 pass / 0 fail / 0 skip |
| 61 | 85 pass / 0 fail / 0 skip |

Total query result:

```text
425 pass / 0 fail / 0 skip
```

Each query sample covered status, validator set, bank balances, auth accounts, fees params, merchant params, settlement params, escrow params, payout params, treasury params, and all live flags.

## Runtime Transaction

A small testnet-only bank send was submitted during the soak from `bravo` to `alpha`.

- Command path: `tx send` fallback, because this binary exposes `tx send` rather than `tx bank send`.
- Amount: `123unxrl`
- Tx hash: `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5`
- Inclusion code: `0`
- Result: pass

## Persistence-Safe Restart Test

After the long soak, all agents were stopped and restarted with existing data:

```bash
scripts/testnet/spawn-validator-agents.sh --reuse-data
```

Restart observations:

| Check | Result |
|---|---|
| Existing data retained | Pass |
| Agents restarted | Pass |
| Pre-restart alpha height | 695 |
| Post-restart sampled alpha height | 695 |
| Queries after restart | 85 pass / 0 fail |
| Peer count after restart | 4 |
| Validator set after restart | 5 |
| Block production resumed beyond pre-restart height | Fail |
| Panic/consensus warning lines captured | 270 |

The restart reached the existing height and kept API/RPC query readback available, but block production did not advance beyond height `695`. Agent logs recorded recovered `PrepareProposal` / `ProcessProposal` nil-pointer panics at height `696`.

Classification:

- `--reuse-data` is unsafe for local agent rehearsals in this evidence run.
- Clean-spawn mode remains required for proof-quality local agent rehearsals.
- This is not treated as a protocol-level production restart failure unless persistent restart also fails in a standard deployment setup.

## Final Live Flags

Final readback from the long-soak evidence:

```text
settlement.live_enabled=false
settlement.treasury_routing_enabled=false
settlement.burn_routing_enabled=false
escrow.live_enabled=false
payout.live_enabled=false
treasury.live_enabled=false
```

## Evidence

```text
rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/
```

Key artefacts:

- `clean-spawn.log`
- `soak.log`
- `samples.tsv`
- `height-range.tsv`
- `query-summary.tsv`
- `query-samples/`
- `runtime-bank-send/`
- `restart-reuse-data/`
- `final-summary.md`
- `agent-soak-summary.log`
- `panic-scan.txt`
- `error-scan.txt`

## Verification

Verification logs:

```text
rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/verification/
```

Result:

- `go mod tidy`: pass
- `go mod verify`: pass
- `go build ./...`: pass
- `go vet ./...`: pass
- `go test ./...`: pass
- `scripts/testnet/predeployment-check.sh`: pass

## Safety Wording Audit

Safety audit logs:

```text
rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/safety-wording-audit/
```

Terms audited: `decentralised`, `independent validators`, `external validators`, `mainnet live`, `buy NXRL`, `token sale`, `investment`, `guaranteed`, `profit`, `APY`, `returns`, `price`, `listing`.

Result: pass. Remaining references are negative, qualified, technical, checklist literals, or explicit prohibitions. No positive claim was found for mainnet live status, NXRL buyability, token sale, investment, returns, APY, profit, price, listing, independent validators, external validators, or decentralised validator status.

## Conclusion

Phase 9U is complete.

The local 5-agent testnet is stable for continued development under clean-spawn conditions. It completed the 1-hour minimum soak with stable peers, stable validator set, successful periodic query readback, successful runtime transaction inclusion, and no clean-soak panics.

Persistence-safe reuse of existing local agent data is not supported from this evidence run. Local agent rehearsals should use `--clean` unless explicitly testing restart failure modes.

External validator launch remains pending. The 5-agent local runtime does not prove external validator participation, independent validator operations, mainnet launch, NXRL availability, or external decentralisation.
