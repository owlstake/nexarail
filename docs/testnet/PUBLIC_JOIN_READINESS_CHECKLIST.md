# Public Join Readiness Checklist

**Network:** `nexarail-testnet-1`
**Status:** preparation continues; no public network launched

| Item | Status | Reference |
|---|---|---|
| Source build works | READY | `v0.1.0-rc1-cli-hotfix`, `make build` |
| CLI node ID command works | READY | `nexaraild tendermint show-node-id`, `nexaraild comet show-node-id` |
| Gentx command documented | READY | `docs/testnet/CONTROLLED_TESTNET_RUNBOOK.md` |
| Intake form exists | READY | `docs/testnet/VALIDATOR_APPLICATION_FORM.md` |
| Gentx verifier exists | READY | `scripts/testnet/verify-controlled-testnet-gentx.sh` |
| Genesis assembler exists | READY | `scripts/testnet/assemble-controlled-testnet-genesis.sh` |
| Persistent peers generator exists | READY | `scripts/testnet/generate-persistent-peers.sh` |
| Runbook exists | READY | `docs/testnet/CONTROLLED_TESTNET_RUNBOOK.md` |
| Status doc exists | READY | `docs/testnet/CONTROLLED_TESTNET_STATUS.md` |
| Support process exists | READY - channel placeholder pending launch window | `docs/testnet/CONTROLLED_TESTNET_LAUNCH_WINDOW_TEMPLATE.md` |
| Final genesis pending | PENDING | Requires verified external gentxs |
| Launch time pending | PENDING | Requires final genesis and validator readiness |

## Guardrails

- Controlled external-validator testnet is not launched.
- Mainnet remains NO-GO.
- External validator gentxs remain pending.
- Product live flags remain false by default.
- No token sale is announced or implied.
- Testnet denominations have no monetary value.
