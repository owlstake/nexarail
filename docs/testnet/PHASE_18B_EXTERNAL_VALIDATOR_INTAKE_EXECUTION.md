# Phase 18B External Validator Intake Execution

**Date:** 2026-05-29
**Network:** `nexarail-testnet-1`
**Status:** intake execution open; NodeSync gentx accepted; peer host pending confirmation

## Objective

Execute the external-validator intake path by collecting real public validator records, validating submitted gentxs, collecting endpoints, generating persistent peers, and deciding whether final public genesis can be frozen.

Phase 18B does not fabricate validators and does not wait idly. If no validator submissions exist, the correct output is a documented waiting state and a deferred freeze decision.

## Current Intake Status

- Validator registry: `coordination/validators/validator-intake.csv`
- Endpoint inventory: `coordination/validators/endpoint-inventory.csv`
- Submitted validator metadata records: 1 (`NODESYNC`)
- Accepted validator intake records: 1
- Submitted external gentx files present locally: 1
- Verified gentxs: 1
- Rejected gentxs: 0
- Persistent peers: generated for NodeSync; DNS/IP host confirmation pending
- Final public genesis: not assembled
- Controlled external-validator testnet: not launched
- Mainnet: NO-GO

NodeSync has provided public metadata and the original gentx JSON. SHA256 matches and the controlled gentx verifier passes. Peer host is pending confirmation because the earlier DNS endpoint differs from the gentx memo IP.

## Required Validator Fields

Each accepted validator record must contain public, non-secret fields only:

- `validator_id`
- `moniker`
- `contact`
- `operator_address`
- `account_address`
- `node_id`
- `public_host`
- `p2p_port`
- `gentx_filename`
- `gentx_sha256`
- `build_tag` or `build_commit`
- `os_arch`
- `status`
- `notes`

Do not collect private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, node data, database files, or private operator notes.

## Gentx Handling Process

1. Receive only `gentx-*.json` plus the intake row fields.
2. Store submitted gentxs under `coordination/validators/gentxs/`.
3. Verify the submitted SHA256 before trusting the file.
4. Run `scripts/testnet/verify-controlled-testnet-gentx.sh` directly or through `scripts/testnet/validate-validator-intake.sh`.
5. Copy accepted gentxs to `coordination/validators/verified/`.
6. Copy rejected gentxs to `coordination/validators/rejected/` with a reason file.
7. Do not edit validator gentxs silently.
8. Send the validator the exact correction reason when a gentx is rejected.

## Endpoint Collection Process

Endpoint inventory lives at `coordination/validators/endpoint-inventory.csv`.

Required endpoint fields:

- `node_name`
- `operator`
- `rpc_url`
- `api_url`
- `grpc_url`
- `p2p_address`
- `status`
- `notes`

RPC/API/gRPC endpoints are optional until monitoring is requested, but P2P address details are required for persistent peers. Exposed RPC/API endpoints should be restricted by the operator to trusted access where possible.

## Verification Process

Run:

```bash
scripts/testnet/validate-validator-intake.sh
scripts/testnet/generate-persistent-peers.sh \
  --input coordination/validators/validator-intake.csv \
  --output coordination/validators/peer-info/
```

For each submitted gentx, acceptance requires:

- valid JSON;
- expected chain ID `nexarail-testnet-1`;
- expected denom `unxrl`;
- operator address parses;
- consensus pubkey present;
- no secret material;
- moniker present;
- self-delegation amount present;
- no live-flag changes;
- SHA256 matches the intake row.

## Acceptance Rules

A validator can be accepted for final genesis only when:

- all required intake fields are present;
- node ID is a 40-character hex string;
- P2P port is valid;
- build tag or commit is present;
- gentx file exists under the submitted gentx directory;
- gentx SHA256 matches the intake row;
- gentx verification passes;
- no secret material is present.

## Rejection Rules

Reject the submission if:

- required fields are missing;
- gentx JSON is invalid;
- chain ID or denom is wrong;
- operator address, consensus pubkey, moniker, or self-delegation is missing;
- gentx SHA256 does not match the intake row;
- private material is included;
- the validator attempts to change product live flags;
- the operator claims token value, sale terms, or launch status inconsistent with the controlled testnet boundary.

Rejected gentxs must be copied to `coordination/validators/rejected/` with a reason file. The validator should receive a correction message from `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md`.

## Final Genesis Freeze Criteria

Final public genesis can be frozen only when all of these are true:

- verified external gentx count is greater than zero;
- accepted validator count matches verified gentx count;
- persistent peers are generated from complete accepted records;
- endpoint inventory is complete enough for launch monitoring;
- `validate-genesis` passes;
- `SHA256SUMS` and `manifest.json` are written;
- product live flags remain false;
- no secret material appears in release artifacts;
- final genesis is marked as a final public genesis candidate, not as a launched network;
- launch window and support channel are confirmed.

If verified external gentx count is zero, final public genesis must not be assembled.

## Launch Status Wording

Use this wording until final genesis is published and external validators are actually running:

```text
Controlled external-validator testnet preparation continues. Validator intake is open. No public network has launched yet.
```

Do not claim external decentralisation until accepted external validators are live and evidenced.

## Disclaimer

This is controlled testnet preparation only. It is not mainnet. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied. Product live-funds flags remain false by default.
