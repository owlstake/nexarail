# nexarail-testnet-1 — FINAL CONTROLLED TESTNET GENESIS

**This is NOT mainnet. NXRL has no monetary value. No token sale is announced or implied. Product live-funds flags remain false.**

| Field | Value |
|---|---|
| Network | `nexarail-testnet-1` |
| Status | Final controlled-testnet genesis (rolling start) |
| Genesis path | `releases/testnet-genesis/nexarail-testnet-1/genesis.json` |
| Genesis SHA256 | `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095` |
| Validator count | 6 (NodeSync + 5 coordinator-operated) |
| Denom | `unxrl` |
| Source ref | `v0.1.0-rc1-cli-hotfix` (commit `3d0d434`) |
| Frozen UTC | `2026-05-30T12:03:32Z` |
| Approved by | Bradley Johnston (coordinator) |
| Mainnet | NO-GO |
| External decentralisation | Not claimed until external validator block-signing is observed |

## Files in this Folder

- `genesis.json` — final controlled-testnet genesis
- `SHA256SUMS` — checksums
- `manifest.json` — provenance + safety metadata
- `persistent-peers.txt` — known persistent peers (NodeSync; coordinator peers added at coordinator startup)
- `FINAL_NOTICE.md` — this file

## Operational Rules

- Use only for the controlled external-validator testnet. Do not reuse for mainnet.
- Persistent peers are bootstrap-only; the network does not authorise outbound transactions of monetary value.
- Halt and follow `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` if any product live-funds flag is observed true, height stalls, or any panic/fatal marker appears in `nexaraild` logs.
