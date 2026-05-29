# Agent Testnet Evidence Index

**Date:** 2026-05-29
**Scope:** consolidated evidence index for NexaRail local validator-agent rehearsals through Phase 17A controlled-testnet dry-run
**Agent chain ID:** `nexarail-agent-testnet-1`
**Controlled testnet dry-run chain ID:** `nexarail-testnet-1`

## Phase Evidence Paths

| Phase | Evidence path | Purpose |
|---|---|---|
| Phase 9T clean-spawn governance | `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/` | Clean 5-agent runtime, governance lifecycle, final live flags |
| Phase 9T query readback | `rehearsals/validator-agents/query-readback/evidence/20260527T095523Z/` | Full query/readback proof |
| Phase 9U long soak | `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/` | 60-minute clean-spawn soak, runtime tx, restart failure reference |
| Phase 9V restart investigation | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/` | Restart root cause, fix, and matrix |
| Phase 9V final rebuilt-binary proof | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/final-code-restart-proof/` | Final 5-agent restart proof after rebuilding |
| Phase 16B.2 one-hour soak | `rehearsals/validator-agents/long-soak/evidence/phase16b2-20260528T190803Z/` | One-hour local stability soak baseline |
| Phase 16C smoke load | `rehearsals/validator-agents/load-sim/evidence/phase16c-smoke-20260528T213401Z/` | 120s local bank tx/query load smoke |
| Phase 16C 10-minute load | `rehearsals/validator-agents/load-sim/evidence/phase16c-10min-stable-20260528T215108Z/` | Canonical 10-minute local throughput profile |
| Phase 16C heavier load | `rehearsals/validator-agents/load-sim/evidence/phase16c-heavy-20260528T220345Z/` | Optional 20-minute heavier local throughput profile |
| Phase 16D L1/L2 trend | `rehearsals/validator-agents/load-trends/evidence/phase16d-L1L2-20260528T225534Z/` | Local trend/resource profile for L1 and L2 |
| Phase 16D L3 trend | `rehearsals/validator-agents/load-trends/evidence/phase16d-L3L4-20260528T231938Z/L3/` | Local trend/resource profile for completed L3 |
| Phase 16D partial L4 | `rehearsals/validator-agents/load-trends/evidence/phase16d-L3L4-20260528T231938Z/L4/` | Interrupted during Phase 16E handoff; non-canonical |
| Phase 17A controlled-testnet dry-run | `rehearsals/controlled-testnet/dry-run/evidence/20260529T132046Z/` | Local five-validator rehearsal of intake, gentx, genesis assembly, persistent peers, launch, and height-20 validation |

## Key Summaries

| Item | Path |
|---|---|
| Phase 9T summary | `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/summary.txt` |
| Phase 9T clean-spawn proof | `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/clean-spawn-proof.txt` |
| Phase 9T query summary | `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/query-readback/summary.txt` |
| Phase 9U final summary | `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/final-summary.md` |
| Phase 9U soak summary env | `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/summary.env` |
| Phase 9V final summary | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/final-summary.md` |
| Phase 9V matrix results | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/matrix-results.tsv` |
| Phase 9V final restart block advance | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/final-code-restart-proof/block-advance.env` |
| Phase 9V final restart query summary | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/final-code-restart-proof/query-readback/summary.txt` |
| Phase 16B.2 results | `docs/testnet/PHASE_16B2_ONE_HOUR_SOAK_RESULTS.md` |
| Phase 16C load plan | `docs/testnet/PHASE_16C_LOAD_SIMULATION_PLAN.md` |
| Phase 16C load results | `docs/testnet/PHASE_16C_LOAD_SIMULATION_RESULTS.md` |
| Phase 16C 10-minute summary | `rehearsals/validator-agents/load-sim/evidence/phase16c-10min-stable-20260528T215108Z/summary.json` |
| Phase 16C heavier summary | `rehearsals/validator-agents/load-sim/evidence/phase16c-heavy-20260528T220345Z/summary.json` |
| Phase 16D L1/L2 trend summary | `rehearsals/validator-agents/load-trends/evidence/phase16d-L1L2-20260528T225534Z/trend-summary.json` |
| Phase 16D L3 level summary | `rehearsals/validator-agents/load-trends/evidence/phase16d-L3L4-20260528T231938Z/L3/summary.json` |
| Post-RC1 rollup | `docs/release/POST_RC1_HARDENING_EVIDENCE_ROLLUP.md` |
| RC2 recommendation | `docs/release/RC2_RECOMMENDATION.md` |
| Phase 17A dry-run results | `docs/testnet/PHASE_17A_CONTROLLED_TESTNET_DRY_RUN_RESULTS.md` |
| Phase 17A dry-run summary | `rehearsals/controlled-testnet/dry-run/evidence/20260529T132046Z/summary.md` |

## Genesis Checksums

| Evidence run | Genesis checksum |
|---|---|
| Phase 9T clean-spawn governance | `1e1e515b37139ba88a9bdd41a57c131c5d4da3c7ea615f6505a668be225b2253` |
| Phase 9U long soak | `efc6b3a89911275cdbc34d12e444b6a3264e186b41d7301714942c294eaa2fcb` |
| Phase 9V A single-validator | `638fbf6fb50465b530e44aae394725fc7033a515343491640076dbd95ee01e46` |
| Phase 9V B 3-agent | `126635c22f6eb674350eccda3e5d9c311d5ed223213f432be7a284a07c8802c8` |
| Phase 9V C 5-agent | `4c1c91b28fd1ecf8b2233f0c6e07f4d5f9441d33c814ca461a47f1a13b890a48` |
| Phase 9V D height-20 restart | `48afb9c62c58452b7c29ccd6894e3543ef977504394462e7f15bbfaea8a7ae0e` |
| Phase 9V E 5-agent after soak | `846cd679ceb76a836b0c84c9aaa23822aa8cf9faa389e4d889c39519b219de37` |
| Phase 9V F one-node restart | `135ad93408c584f362da4f0653de67ed518db745ab77d1ffbfe1cbddd78db456` |
| Phase 9V G all-direct simultaneous | `f9b5b1c3fe345d9f5effe5d610289780129a490b000776241e50f82d11efe141` |
| Phase 9V H all-direct sequential | `5399d53c0f134edd8d4b5c5f7f2b9355e2aee6c1dd4ccbcba3abdae8f310c4e6` |
| Phase 9V standard direct | `5b2ec7f27c6a8ec61db1790ab3f5eb054017c02ee3aa7b664f204fe42740d6c8` |
| Phase 9V final rebuilt-binary proof | `23d40e8a7c301c8d0d1b5bbdfa27c54648e8a44a19264c5a966d9501ed0ac9b4` |
| Phase 17A controlled-testnet dry-run | `5fc2ad8a76cfee850e33ddf8f94f403b101657f27de6f0c8885021e8b2c74d90` |

## Runtime Transaction Hashes

| Source | Tx hash | Result |
|---|---|---|
| Phase 9U runtime bank send | `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5` | inclusion code `0` |
| Phase 9V all-direct simultaneous post-restart bank send | `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5` | inclusion code `0` |
| Phase 16C 10-minute bank load | 220 attempted / 220 included | all inclusion code `0` |
| Phase 16C heavier bank load | 876 attempted / 876 included | all inclusion code `0` |
| Phase 16D L1 bank load | 224 attempted / 224 included | all inclusion code `0` |
| Phase 16D L2 bank load | 448 attempted / 448 included | all inclusion code `0` |
| Phase 16D L3 bank load | 515 attempted / 515 included | all inclusion code `0` |

## Governance Proposal IDs

| Proposal | Proposal ID | Submit tx |
|---|---|---|
| Enable escrow live flag | `1` | `CBFBBDD5964C7B1D2C9C0BBDE8D9CAA40863F734E3B4BA4C4B08CE22F8840338` |
| Disable escrow live flag | `2` | `46733082097465AD2BEA3B8A7532F18F9B4A5F6CCD44FC798EF508957E53CECC` |

## Vote Tx Hashes

Enable proposal votes:

| Agent | Tx hash |
|---|---|
| alpha | `9721371596D889E1FA26147F6181BE018D4E2808F945545479840C72AA2DCCC7` |
| bravo | `B4C1DCEF484C5028FC69401AF6F1250C56FCD35B367821BEB65FDF0FE0FFDAB5` |
| charlie | `C0CD73082375AD65FD0A590F0B07BB9D814DBD5B0CA13103EC6A694AFB7733D8` |
| delta | `6D1FB1A92D5445665F38B98E437D1A77411DA4FF296D80F0E537B16D0E731ED5` |
| echo | `CDF7111C3D34E1B35C1C7F7686FC2E3518DE7E09755D6805F6E93278FDCD7091` |

Disable proposal votes:

| Agent | Tx hash |
|---|---|
| alpha | `69C21FDEDB94D6E1FE0C10F3CEB440281FC84BA0A22FA9A38022E362858E8CF5` |
| bravo | `0123A12B435EF26871074188F670D1E66D6969533620CBEF1C42F21FD091BA5C` |
| charlie | `79C75A402F3C3CC455F07BE84722FB9BC767F5E57DABD31FCFD7511A80ED2204` |
| delta | `42EC1D039D3EA50D9950CD6DFBC5989667004F5E362E2DD80AF1B3405694BB2F` |
| echo | `C513216750C18F500CADB2A95D37B526F77141DD13FA91BA033B9629FCBBA065` |

## Restart Evidence

| Case | Evidence path | Result |
|---|---|---|
| A single-validator | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/A-single-validator/` | pass |
| B 3-agent | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/B-three-agent/` | pass |
| C 5-agent | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/C-five-agent/` | pass |
| D 5-agent height-20 | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/D-five-agent-height20/` | pass |
| E 5-agent after soak | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/E-5-agent-after-soak/` | pass; height `695` to `698` |
| F one-node restart | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/F-one-node/` | pass |
| G all-direct simultaneous | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/G-all-direct-simultaneous/` | pass |
| H all-direct sequential | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/H-all-direct-sequential/` | pass |
| Standard direct | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/standard-direct/` | pass |

## Final Live Flags

Final consolidated readback:

```text
settlement.live_enabled=false
settlement.treasury_routing_enabled=false
settlement.burn_routing_enabled=false
escrow.live_enabled=false
payout.live_enabled=false
treasury.live_enabled=false
```

Relevant files:

- `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/final-state/final-live-flags.txt`
- `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/final-code-restart-proof/query-readback/alpha-live-flags.txt`

## Safety Audit Evidence

| Phase | Path |
|---|---|
| Phase 9T | `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/safety-wording-audit/` |
| Phase 9U | `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/safety-wording-audit/` |
| Phase 9V | `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/safety-wording-audit/` |
| Phase 16C | `rehearsals/validator-agents/load-sim/evidence/phase16c-safety-audit-20260528T222937Z/` |

## Boundary

This evidence index covers local agent and controlled-testnet dry-run evidence only. It does not index live external-validator launch evidence because external validators and external gentxs remain pending.
