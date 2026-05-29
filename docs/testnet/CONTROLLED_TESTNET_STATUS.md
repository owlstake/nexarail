# Controlled Testnet Status

**Network:** `nexarail-testnet-1`
**Last updated:** 2026-05-29

## Current Status

| Item | Status |
|---|---|
| Controlled external-validator testnet | NOT LAUNCHED |
| Genesis | PENDING |
| Validator gentxs | PENDING |
| Launch time | PENDING |
| Persistent peers | PENDING |
| Seed or bootnode | PENDING |
| External validator evidence | PENDING |
| Local Phase 17A dry-run | PASS |
| Product live flags | FALSE BY DESIGN |
| Mainnet | NO-GO |

## Current Validator Path

Source-build only:

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1-cli-hotfix
make build
```

Prebuilt hotfix binary upload is not the validator path until release asset permissions are resolved and checksums are published through the GitHub release.

## Local Dry-Run Evidence

The launch tooling path passed a local five-validator dry-run:

- height verified: 20;
- validator set count: 5;
- genesis SHA256: `5fc2ad8a76cfee850e33ddf8f94f403b101657f27de6f0c8885021e8b2c74d90`;
- product live flags: false;
- `tendermint show-node-id` and `comet show-node-id`: pass.

See `docs/testnet/PHASE_17A_CONTROLLED_TESTNET_DRY_RUN_RESULTS.md`.

## Status Rules

- Do not describe the controlled testnet as launched until final genesis is published and accepted external validators are running.
- Do not describe external decentralisation as achieved until external validator operation is evidenced.
- Do not describe NXRL as buyable or having monetary value.
- Keep product live-funds flags false unless a separately reviewed governance process changes them.
