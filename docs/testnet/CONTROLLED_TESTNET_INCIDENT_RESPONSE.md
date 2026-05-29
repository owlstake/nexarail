# Controlled Testnet Incident Response

**Network:** `nexarail-testnet-1`
**Status:** coordinator launch preparation; no public network launched

## Purpose

Provide the coordinator-side response process for controlled testnet launch rehearsals and future launch windows. This runbook covers incident severity, roles, halt and rollback criteria, validator communication, evidence capture, log preservation, and common failure paths.

## Severity Levels

| Severity | Meaning | Response |
|---|---|---|
| SEV0 | Chain safety issue, wrong genesis, unexpected live flag, consensus halt, double-sign risk, or secret exposure | Stop launch flow, preserve evidence, coordinate halt/rollback |
| SEV1 | Launch-blocking issue affecting genesis, validator set, peers, or binary/tag consistency | Pause launch, triage with affected validators, publish corrected instructions only after review |
| SEV2 | Partial validator, endpoint, REST/RPC, or monitoring issue that does not compromise consensus | Continue triage, collect evidence, decide whether launch criteria still hold |
| SEV3 | Documentation, support, or non-blocking visibility issue | Track and resolve without changing launch status |

## Incident Roles

- Coordinator: owns launch decision, halt/rollback calls, and public status wording.
- Evidence lead: captures RPC/API, validator-set, peer, live-flag, checksum, and log evidence.
- Validator liaison: sends approved validator messages and gathers operator status.
- Release reviewer: checks binary/tag, genesis hash, manifest, persistent peers, and no-secrets scan.

One person can hold multiple roles during rehearsal, but the coordinator must remain the final decision owner.

## Halt Criteria

Halt the launch flow if any of these occur:

- final genesis checksum mismatch;
- validator set differs from the accepted gentx manifest;
- wrong binary or tag is being used;
- chain does not produce blocks;
- consensus halt or repeated proposer failure;
- app hash mismatch;
- any product live flag is unexpectedly true;
- double-sign warning or validator signing-key confusion;
- private material is shared in the support channel or launch artifacts;
- coordinator cannot contact enough validators to maintain launch safety.

## Rollback Criteria

Rollback to the previous preparation state if:

- no block is produced after the launch window opens;
- more than one accepted validator cannot join because of peer or genesis mismatch;
- final genesis must be regenerated;
- persistent peers are materially wrong;
- launch instructions were sent with the wrong hash, binary, tag, or chain ID;
- a SEV0 incident is confirmed.

Rollback means stop launch coordination, preserve evidence, publish corrected status only through approved channels, and do not call the public network live.

## Validator Communication Procedure

1. Use `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md` for approved wording where possible.
2. State the chain ID, genesis hash, binary/tag, and action requested.
3. Ask for specific non-secret evidence: node ID, latest height, peer count, `catching_up`, validator signing status, and sanitized logs.
4. Do not request private keys, mnemonics, node keys, validator signing keys, keyrings, SSH keys, node data, or database files.
5. Keep public wording clear: controlled testnet preparation only, not mainnet, no token sale, no monetary value.

## Evidence To Collect

- final genesis hash and `SHA256SUMS`;
- manifest and validator count;
- binary/tag and `nexaraild version`;
- `status`, `net_info`, and `validators` from RPC endpoints;
- first block, first 10 blocks, first 100 blocks, and first-hour samples when available;
- live-flag REST/API responses;
- persistent peers string and per-validator peer snippets;
- endpoint inventory status;
- sanitized logs from affected validators;
- panic/fatal scans;
- support decisions and timestamps.

Use `scripts/testnet/collect-launch-hour-evidence.sh` for first-hour evidence capture.

## Preserve Logs

- Ask validators to copy logs before restarting.
- Prefer compressed, sanitized excerpts scoped to the incident window.
- Keep local evidence under `rehearsals/controlled-testnet/`.
- Record UTC timestamps for every action.
- Preserve original checksums and command output where possible.

## What Not To Share

Do not share or commit:

- private keys;
- mnemonics;
- `node_key.json`;
- `priv_validator_key.json`;
- keyring files;
- validator signing keys;
- SSH keys;
- node data directories;
- database files;
- unsanitized private validator contact details.

## Common Incidents

### Chain Does Not Start

- Confirm genesis hash and binary/tag.
- Check `nexaraild validate-genesis`.
- Check logs for panic/fatal markers.
- Confirm persistent peers are set correctly.
- Halt launch if the issue affects more than one validator or the first block is not produced.

### Validator Missing From Set

- Compare final manifest, accepted gentx set, and `/validators`.
- Confirm the validator used the final genesis.
- Check gentx acceptance evidence.
- Do not regenerate genesis during a launch window without coordinator sign-off.

### Peer Connection Failure

- Confirm node ID, host, P2P port, and firewall.
- Check `net_info` peer count.
- Verify persistent peer string excludes the validator's own node ID.
- Use sentry-specific instructions only if reviewed.

### App Hash Mismatch

- Treat as SEV0 or SEV1 depending on scope.
- Preserve logs immediately.
- Confirm genesis checksum and binary/tag across affected nodes.
- Do not continue launch until cause is known.

### Node Stuck Catching Up

- Check latest height, `catching_up`, peers, clock sync, and network reachability.
- Confirm the node started from final genesis.
- Ask for sanitized logs around sync start.

### Consensus Halt

- Capture `/status`, `/validators`, and logs from all reachable nodes.
- Confirm validator signing status.
- Check for app hash mismatch, double-sign warning, or proposer failure.
- Halt public launch wording until evidence confirms recovery.

### Wrong Genesis Hash

- Stop affected validator.
- Reinstall the published final genesis candidate.
- Recheck SHA256.
- If the wrong hash was sent through coordinator channels, halt and issue corrected instructions.

### Wrong Binary/Tag

- Confirm `nexaraild version` and Git tag or commit.
- Rebuild from the approved tag.
- Re-run node ID helper commands if the validator rebuilt from source.

### Validator Signing Issue

- Check `validator_info` and logs.
- Confirm the validator is using the intended signing key.
- Never request or transmit validator signing keys.

### Double-Sign Warning

- Treat as SEV0.
- Stop affected nodes immediately.
- Preserve logs and signing evidence.
- Do not restart until the operator confirms there is no duplicate signer.

### REST/RPC Unavailable

- Check whether consensus is still healthy through other endpoints.
- Verify firewall and local API/RPC enablement.
- Treat as SEV2 unless monitoring loss blocks launch criteria.

### Product Live Flags Unexpectedly True

- Treat as SEV0.
- Stop launch flow.
- Capture REST/API params and genesis evidence.
- Do not proceed until flags are confirmed false through reviewed artifacts.

## Safety Boundary

This runbook is for controlled testnet preparation only. It is not mainnet. No public network is live from these materials. External decentralisation is not claimed. NXRL is not presented as buyable and no monetary value is implied. No token sale is announced or implied.
