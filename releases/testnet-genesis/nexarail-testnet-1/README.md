# nexarail-testnet-1 — Final Controlled Testnet Genesis

**FINAL CONTROLLED TESTNET GENESIS**

> This is **NOT mainnet**. NXRL has **no monetary value**. There is **no token sale** announced or implied. **Testnet tokens have no monetary value.** Product live-funds flags remain **false by default**. Network start is **coordinated separately** under `docs/testnet/CONTROLLED_TESTNET_LAUNCH_SIGNOFF.md`.

## Artifact Summary

| Field | Value |
|---|---|
| Network / chain ID | `nexarail-testnet-1` |
| Genesis SHA256 | `4ced9f713d8d6f4e85cd4611c8e28a465db6d3d74e62269e3b0df2fc8a4f0095` |
| Source ref | `v0.1.0-rc1-cli-hotfix` (build commit `3d0d434`) |
| Validator count | 6 (NodeSync + 5 coordinator-operated) |
| Denom | `unxrl` |
| Frozen UTC | `2026-05-30T12:03:32Z` |
| Status | Final controlled-testnet genesis (rolling start under separate signoff) |
| Mainnet | **NO-GO** |
| External decentralisation | Not claimed until external-validator block-signing is observed |

## Files

- `genesis.json` — final controlled-testnet genesis
- `SHA256SUMS` — checksum manifest
- `manifest.json` — provenance + safety metadata
- `persistent-peers.txt` — known persistent peers (NodeSync; coordinator peers added at coordinator startup)
- `FINAL_NOTICE.md` — full safety / operational notice
- `README.md` — this file (GitHub overview)

## Verify SHA256

```bash
shasum -a 256 -c SHA256SUMS
```

Expected output:

```
genesis.json: OK
```

## Raw Download Links

After publication to `origin/main` on `github.com/Bookings-cpu/nexarail`:

- `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/genesis.json`
- `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/SHA256SUMS`
- `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/manifest.json`
- `https://raw.githubusercontent.com/Bookings-cpu/nexarail/main/releases/testnet-genesis/nexarail-testnet-1/persistent-peers.txt`

## Operational Rules

- Use only for the controlled external-validator testnet. Do not reuse for mainnet.
- Persistent peers are bootstrap-only. The network does not authorise outbound transactions of monetary value.
- Halt and follow `docs/testnet/CONTROLLED_TESTNET_INCIDENT_RESPONSE.md` if any product live-funds flag is observed `true`, height stalls, or any `panic`/`fatal` marker appears in `nexaraild` logs.
- Validators must not share private keys, mnemonics, or seed phrases over public channels.

## Safety Boundary

- Mainnet: **NO-GO**.
- Public testnet declared **LIVE**: only after coordinator + NodeSync external block-signing evidence is collected.
- External decentralisation: **not claimed** until external-validator block-signing is observed.
- Token value / token sale: **none**. NXRL has no monetary value.
- Product live-funds flags: **false by default**.
