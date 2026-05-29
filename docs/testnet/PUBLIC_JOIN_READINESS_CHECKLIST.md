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
| Intake execution doc exists | READY | `docs/testnet/PHASE_18B_EXTERNAL_VALIDATOR_INTAKE_EXECUTION.md` |
| Validator message pack exists | READY | `docs/testnet/VALIDATOR_INTAKE_MESSAGE_PACK.md` |
| Submission tracker exists | READY - one accepted external validator | NodeSync gentx accepted; DNS peer confirmed |
| Endpoint inventory populated | PARTIAL | NodeSync P2P DNS endpoint confirmed; RPC/API/gRPC pending |
| Persistent peers from external records | READY - one accepted external validator | NodeSync DNS peer generated |
| Final genesis pending | PENDING | Requires freeze gate and launch criteria |
| Launch time pending | PENDING | Requires final genesis and validator readiness |

## Guardrails

- Controlled external-validator testnet is not launched.
- Mainnet remains NO-GO.
- NodeSync gentx has been verified and the DNS peer is confirmed.
- Final public genesis freeze decision is `FREEZE_DEFER` until coordinator launch criteria are met.
- Product live flags remain false by default.
- No token sale is announced or implied.
- Testnet denominations have no monetary value.
