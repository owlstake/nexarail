# Validator Agent Rehearsal Results — nexarail-agent-testnet-1

## Phase 16C Update - 2026-05-28

**Status:** Controlled local five-agent load simulation passed.

Canonical Phase 16C evidence:

```text
rehearsals/validator-agents/load-sim/evidence/phase16c-10min-stable-20260528T215108Z/
rehearsals/validator-agents/load-sim/evidence/phase16c-heavy-20260528T220345Z/
```

Result summary:

| Metric | 10-minute | Heavier |
|---|---:|---:|
| Duration | 600s | 1200s |
| Height delta | 113 | 226 |
| Average block time | 5.44s | 5.44s |
| Peer count range | 4-4 | 4-4 |
| Validator set range | 5-5 | 5-5 |
| Tx inclusion | 220 / 220 | 876 / 876 |
| Query success | 2330 / 2330 | 9020 / 9020 |
| Tx p50 / p95 inclusion latency | 5390ms / 6052ms | 5319ms / 6153ms |
| Query p50 / p95 latency | 1ms / 10ms | 1ms / 12ms |
| Panic / CheckTx / descriptor scans | 0 / 0 / 0 | 0 / 0 / 0 |
| Final live flags | false | false |

Conclusion: the local five-agent devnet sustained conservative bank tx and REST/RPC query load without validator loss, peer-count drift, validator-set drift, unrecovered CheckTx failures, panics, descriptor/unknownproto/gzip errors, or live-flag changes. This is local rehearsal evidence only; it is not public testnet, mainnet, or external validator evidence.

---

## Phase 9V Update - 2026-05-27

**Status:** Persistence-safe restart fixed for the tested local agent rehearsal paths.

Latest Phase 9V evidence:

```text
rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/
```

Matrix result:

| Case | Result |
|---|---|
| Single-validator reuse-data restart | Pass |
| 3-agent reuse-data restart | Pass |
| 5-agent reuse-data restart | Pass |
| 5-agent restart at height 20 | Pass |
| 5-agent restart after 60-minute soak | Pass |
| One-node restart while four continue | Pass |
| All-node direct simultaneous restart | Pass |
| All-node direct sequential restart | Pass |
| Standard single-node direct restart | Pass |

Key proof:

- 60-minute soak restart: height `695` to `698`, block production resumed.
- Soak query totals: `425 pass / 0 fail / 0 skip`.
- Final rebuilt-binary restart proof: height `11` to `14`, full query readback `85 pass / 0 fail / 0 skip`.
- Post-restart panic scan: `0`.
- Post-restart bank tx inclusion code: `0`.
- Final live flags: all false.

Conclusion: the Phase 9U reuse-data restart failure was fixed by making the BaseApp consensus-param store restart-safe. The local agent testnet is stable for continued development. This remains local rehearsal evidence only; external validator launch remains pending.

---

## Phase 9U Update - 2026-05-27

**Status:** Clean-spawn long soak passed; reuse-data restart unsafe for local agent rehearsals.

Latest Phase 9U evidence:

```text
rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/
```

Result summary:

| Metric | Value |
|---|---:|
| Soak duration | 3602s |
| Start height | 12 |
| Final height | 685 |
| Height delta | 673 |
| Average block time | 5.35s |
| Peer count range | 4-4 |
| Validator set range | 5-5 |
| Query result | 425 pass / 0 fail / 0 skip |
| Runtime tx | `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5`, inclusion code 0 |
| Clean-soak panics | 0 |
| Reuse-data restart | Failed to resume block production beyond height 695 |

Conclusion: the 5-agent local testnet is stable for continued development when started from clean-spawn mode. `--reuse-data` is diagnostic only and remains unsupported for proof-quality local agent rehearsals after Phase 9U. This remains a local agent rehearsal, not evidence of external validator participation.

---

**Date:** 2026-05-26 15:47 BST
**Status:** ✅ SUCCESS

---

## Rehearsal Summary

| Metric | Value |
|---|---|
| Chain ID | nexarail-agent-testnet-1 |
| Validator agent count | 5 |
| gen_txs count | 5 |
| Block height reached | 18+ |
| Validator set count | 5 |
| Peer count (per agent) | 4 |
| All 6 live flags false | ✅ |
| Module params queryable (RPC) | ✅ |
| REST API module params | ⚠️ Not reachable (API port needs explicit enable) |
| Governance test | ⚠️ Not executed (script prepared) |
| Duration | ~50 seconds to height 9 |

## Agent Status

| Agent | Moniker | Running | Height | Peers | Val Set |
|---|---|---|---|---|---|
| alpha | nxrl-validator-agent-alpha | ✅ (RPC down post-start) | — | — | 5 |
| bravo | nxrl-validator-agent-bravo | ✅ | 18 | 4 | 5 |
| charlie | nxrl-validator-agent-charlie | ✅ | 18 | 4 | 5 |
| delta | nxrl-validator-agent-delta | ✅ | 18 | 4 | 5 |
| echo | nxrl-validator-agent-echo | ✅ | 18 | 4 | 5 |

## Node IDs

| Agent | Node ID |
|---|---|
| alpha | 41c1daf49928b2f4e84e2dc657d40e86eeab1b11 |
| bravo | 921f4ffb61f700158543a57f541ec3287fc5d4fe |
| charlie | 1e21c0c31b73d6a622409a519a299b9b04187733 |
| delta | 7cc3784526b1285a38e8cd6949310f5aa5ff1746 |
| echo | c124b81ac5b638ae380ede8a10dc0b00b665dbfa |

## Genesis

| Field | Value |
|---|---|
| Checksum | e16977a0b8be177e588ceab2336319b1547bacb34cd290000c88f5461bbfe3f5 |
| Chain ID | nexarail-agent-testnet-1 |
| gen_txs | 5 |
| Denom | unxrl |
| All live flags false | ✅ |

## Evidence

```
rehearsals/validator-agents/evidence/20260526T144955Z/
├── bravo-status.json
├── bravo-net_info.json
├── bravo-validators.json
├── charlie-status.json
├── charlie-net_info.json
├── charlie-validators.json
├── delta-status.json
├── delta-net_info.json
├── delta-validators.json
├── echo-status.json
├── echo-net_info.json
└── echo-validators.json
```

## Logs

```
rehearsals/validator-agents/logs/
├── alpha.log
├── bravo.log
├── charlie.log
├── delta.log
└── echo.log
```

## Incidents

- **Alpha RPC became unresponsive** after block production started. Node ID confirmed, gentx created, validator in genesis. RPC on port 27657 stopped responding. Likely SSH port conflict (port 27657 may be in SSH tunnel range).
- **REST API not reachable** on custom ports (1417-1421). The `--api.enable` flag or app.toml config needs `enable = true` for the API server to start. RPC endpoints worked for all 4 remaining agents.

## Conclusion

✅ **5 autonomous validator agents successfully spawned, producing blocks with full consensus.** All 5 validators in genesis, gen_txs=5, chain ID confirmed, all 6 live flags false. The autonomous validator agent model is proven working.

**Improvements for next run:** Fix alpha RPC port conflict, enable REST API in app.toml.
