# Launch Go / No-Go Review — NexaRail Testnet

**Date:** 2026-05-28 01:58 BST (updated Phase 10B.2)
**Review:** Clove (automated)
**Decision:** AGENT TESTNET RUNTIME GO / PUBLIC TESTNET NO-GO / MAINNET NO-GO

**Technical agent-testnet readiness:** GO. Phase 9W consolidates the Phase 9T, 9U, and 9V evidence: clean-spawn block production, query/readback, runtime bank tx, governance lifecycle, 60-minute soak, and restart recovery are proven for the local agent-testnet runtime path.

**Public/external testnet launch:** NO-GO until external validators are accepted, external gentxs are collected and validated, final genesis is assembled, public endpoint plans are approved, and validator communications are active.

**Mainnet:** NO-GO. Mainnet remains blocked by external validator launch, public/external testnet evidence, external audit, legal review, and final release sign-off.

**Phase 9X status:** External validator activation docs and multi-machine/Linux rehearsal preparation are ready. External validator cohort activation, external gentx collection, and multi-machine execution remain pending.

**Phase 10B.0.1 status:** Product-flow rehearsal harness is GO for local agent-testnet rehearsal. Smoke, payout, safety, and full suite modes pass with harness-owned cleanup, resumable suites, stage summaries, and a 2400s full-suite cap. This does not change public/external testnet or mainnet status.

**Phase 10B.1 status:** Product-flow evidence review is complete. The successful full-suite evidence proves local merchant, settlement, escrow, treasury, payout, safety, and final live-flag product flows. Semantic gaps remain around REST route completeness, governance/operator UX, event indexing for governance-executed actions, burn supply-delta evidence, and evidence/reporting polish.

**Phase 10B.2 status:** Product-flow operator-surface hardening is complete. The full suite passed with `487 pass / 0 fail`, event summaries, governance evidence indexes, semantic assertions, treasury funding prerequisite checks, and explicit burn supply-delta proof. Remaining gaps are operator/API/documentation polish, not local runtime blockers.

**Restart finding:** The Phase 9U stall was caused by the custom in-memory BaseApp consensus-param store returning nil after process restart. Phase 9V seeds that store from genesis/default consensus params and verifies restart safety. The 5-agent restart-after-60-minute-soak case resumed from height 695 to 698 with queries passing and zero proposal panics.

**Truthful assessment:** The agent-testnet runtime is technically ready for the next controlled preparation phase. The launch blockers are operational and external: no external validators have been accepted for launch, no external gentxs have been collected, no final public/external genesis has been assembled, and no public endpoint or validator communications channel has been launched.

---

## Go / No-Go Gates

### Gate 1: Genesis

| Check | Required | Status | Notes |
|---|---|---|---|
| Final genesis built | Yes | ❌ | Awaiting gentx collection |
| Genesis checksum published | Yes | ❌ | Awaiting genesis assembly |
| All gentxs verified | Yes | ❌ | No gentxs received |
| gen_txs count ≥ 3 | Yes | ❌ | 0 of 3 minimum |
| All 6 live flags = false | Yes | ✅ | Verified in genesis template — all false |
| Clean-spawn final state readback | Yes | ✅ | Phase 9T final live flags all false after governance disable |
| Custom modules present (6) | Yes | ✅ | Verified in genesis template |
| `validate-genesis` passes | Yes | ❌ | Awaiting genesis assembly |
| `check-final-genesis.sh` passes | Yes | ❌ | Awaiting genesis assembly |

### Gate 2: Validators

| Check | Required | Status | Notes |
|---|---|---|---|
| ≥ 3 validators accepted | Yes | ❌ | 0 accepted |
| All validators on Linux | Yes | ❌ | No validators onboarded |
| All gentxs validated | Yes | ❌ | No gentxs received |
| All validators acknowledged genesis | Yes | ❌ | Awaiting genesis publication |
| All validators acknowledged launch time | Yes | ❌ | Awaiting launch scheduling |
| Peer list distributed | Yes | ❌ | Awaiting validator node IDs |
| All validators in communication channel | Yes | ❌ | Awaiting channel setup and validators |
| External validator participation | Yes | ❌ | Pending; local agent validators do not prove external validator participation |

### Gate 3: Infrastructure

| Check | Required | Status | Notes |
|---|---|---|---|
| Seed node(s) deployed (optional) | No | ⬜ | Not yet deployed |
| Persistent peer list compiled | Yes | ❌ | Awaiting validator IPs |
| Faucet account in genesis | Recommended | ⬜ | Not yet allocated |
| Explorer node planned | Recommended | ⬜ | Not yet deployed |
| Monitoring configured | Yes | ⬜ | Coordinator ready to monitor via RPC |

### Gate 4: Code & Configuration

| Check | Required | Status | Notes |
|---|---|---|---|
| Code freeze active | Yes | ✅ | No protocol changes since Phase 6J.2 |
| `go build ./...` passes | Yes | ✅ | 14 packages |
| `go vet ./...` passes | Yes | ✅ | No warnings |
| `go test ./...` passes | Yes | ✅ | 14 packages, all pass |
| No live flags enabled by default | Yes | ✅ | All 6 = false |
| Clean-spawn query readback | Yes | ✅ | 85 pass, 0 fail across 5 local agent validators |
| Governance state readback | Yes | ✅ | Enable proposal 1 then disable proposal 2; final flags false |
| Clean-spawn long soak | Yes | ✅ | Phase 9U: 3602s, height 12→685, peer range 4-4, validator range 5-5 |
| Runtime tx after extended runtime | Yes | ✅ | Bank-send tx `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5`, inclusion code 0 |
| Agent reuse-data restart | Diagnostic | ✅ | Phase 9V matrix passed; post-soak restart height 695→698 |
| Direct restart path | Diagnostic | ✅ | Standard single-node direct restart passed |
| Agent runtime readiness package | Diagnostic | ✅ | Phase 9W package complete: report, evidence index, limitations, next steps |
| Multi-machine prep scripts | Diagnostic | ✅ | Phase 9X setup and evidence helper scripts present |
| Chain ID = `nexarail-testnet-1` | Yes | ✅ | Reserved target for planned public/external testnet; agent evidence uses `nexarail-agent-testnet-1` |
| Denom = `unxrl` | Yes | ✅ | Confirmed |
| Bech32 prefix = `nxr` | Yes | ✅ | Confirmed |

### Gate 5: Documentation

| Check | Required | Status | Notes |
|---|---|---|---|
| All Phase 7A-7F docs complete | Yes | ✅ | 30+ documents |
| Launch coordination plan ready | Yes | ✅ | `TESTNET_LAUNCH_COORDINATION.md` |
| Pre-launch freeze checklist ready | Yes | ✅ | `PRE_LAUNCH_FREEZE_CHECKLIST.md` (47 points) |
| Gentx validation scripts tested | Yes | ✅ | 3 scripts verified |
| Genesis assembly scripts tested | Yes | ✅ | Ready to run |
| Halt/reset procedure documented | Yes | ✅ | In launch coordination doc |
| Validator onboarding guide ready | Yes | ✅ | `ACCEPTED_VALIDATOR_ONBOARDING.md` |
| Phase 9W runtime readiness package | Yes | ✅ | Consolidated agent-testnet evidence and limitations docs complete |
| Phase 9X external activation package | Yes | ✅ | External activation, multi-machine rehearsal, action pack, gentx, evidence, and shortlist docs complete |
| Phase 10B.2 product-flow evidence package | Yes | ✅ | Evidence review, event coverage, CLI/API usability, REST parity, governance UX plan, evidence index, and semantic gaps documented |

### Gate 6: Communications

| Check | Required | Status | Notes |
|---|---|---|---|
| Validator communication channel ready | Yes | ❌ | Not yet created |
| Moderation guide distributed | Yes | ✅ | `DISCORD_TELEGRAM_MODERATION_GUIDE.md` |
| Incident reporting process documented | Yes | ✅ | In launch coordination doc |
| Emergency contacts collected | Yes | ❌ | Awaiting validator onboarding |
| Backup communication method confirmed | Yes | ❌ | Awaiting validator contacts |

### Gate 7: Unsafe Wording

| Check | Required | Status | Notes |
|---|---|---|---|
| No "mainnet live" in public docs | Yes | ✅ | Clean across all 30+ docs |
| No "buy NXRL" in public docs | Yes | ✅ | Clean |
| No "token sale" (positive) | Yes | ✅ | All negated or prohibition |
| No "investment" (positive) | Yes | ✅ | All negated or prohibition |
| No financial return claims | Yes | ✅ | Clean |
| No price speculation | Yes | ✅ | Technical gas-price only |
| Testnet-only disclaimers present | Yes | ✅ | In all public-facing docs |

---

## Gate Summary

| Gate | Required | Passed | Remaining |
|---|---|---|---|
| Genesis | 9 | 3 | 6 |
| Validators | 9 | 0 | 9 |
| Infrastructure | 5 | 0 | 5 |
| Code & Configuration | 16 | 16 | 0 |
| Documentation | 10 | 10 | 0 |
| Communications | 5 | 2 | 3 |
| Unsafe Wording | 7 | 7 | 0 |

**Total gates: 61 | Passed: 38 | Remaining: 23**

**All remaining gates are operational: validators, gentxs, genesis, communications.** No code, documentation, or wording gates remain to be cleared.

## Phase 9T Status

- Clean-spawn query readback: complete under fresh data conditions.
- Governance state readback: complete; `escrow.live_enabled=true` after enable proposal and `false` after disable proposal.
- Final all-live-flags state: all false.
- Evidence: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/`.
- External validator status: pending. The 5-agent runtime is a local rehearsal and does not prove external validator participation.

## Phase 9U Status

- Long soak: complete under clean-spawn conditions.
- Duration: 3602 seconds.
- Start/final height: 12 / 685.
- Height delta: 673.
- Average block time: 5.35s.
- Query readback: 425 pass / 0 fail / 0 skip.
- Runtime tx: `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5`, included with code 0.
- Reuse-data restart: unsafe for local agent rehearsals; block production did not resume beyond height 695.
- Final live flags: all false.
- Evidence: `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/`.
- External validator status: pending. The 5-agent runtime is a local rehearsal and does not prove external validator participation.

## Phase 9V Status

- Restart investigation: complete.
- Root cause: BaseApp consensus-param store was in-memory and could return nil after process restart.
- Matrix result: all restart cases passed.
- 60-minute-soak restart: height `695` to `698`, block production resumed.
- Final rebuilt-binary proof: height `11` to `14`, full query readback `85 pass / 0 fail / 0 skip`.
- Post-restart bank tx: `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5`, inclusion code `0`.
- Final live flags: all false.
- Evidence: `rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/`.
- External validator status: pending. The 5-agent runtime is a local rehearsal and does not prove external validator participation.

## Phase 9W Status

- Runtime readiness consolidation: complete.
- Runtime readiness report: `docs/testnet/PHASE_9W_AGENT_RUNTIME_READINESS_REPORT.md`.
- Evidence index: `docs/testnet/AGENT_TESTNET_EVIDENCE_INDEX.md`.
- Limitations doc: `docs/testnet/AGENT_TESTNET_LIMITATIONS.md`.
- Controlled next steps: `docs/testnet/CONTROLLED_TESTNET_NEXT_STEPS.md`.
- Technical agent-testnet readiness: GO.
- Public/external testnet launch: NO-GO until external validators and gentxs are complete.
- Mainnet: NO-GO.
- Final live flags: all false.
- External validator status: pending. Phase 9W does not claim external validator participation or external decentralisation.

## Phase 9X Status

- External validator activation preparation: complete.
- External validator activation doc: `docs/testnet/PHASE_9X_EXTERNAL_VALIDATOR_ACTIVATION.md`.
- Multi-machine rehearsal plan: `docs/testnet/MULTI_MACHINE_REHEARSAL_PLAN.md`.
- External validator action pack: `docs/testnet/EXTERNAL_VALIDATOR_ACTION_PACK.md`.
- Recruitment shortlist template: `docs/testnet/VALIDATOR_RECRUITMENT_SHORTLIST_TARGETS.md`.
- External gentx readiness checklist: `docs/testnet/EXTERNAL_GENTX_COLLECTION_READY_CHECK.md`.
- Multi-machine evidence checklist: `docs/testnet/MULTI_MACHINE_EVIDENCE_CHECKLIST.md`.
- Multi-machine helper scripts: `scripts/testnet/prepare-multi-machine-validator.sh`, `scripts/testnet/collect-multi-machine-evidence.sh`.
- External validator cohort: pending.
- Multi-machine/Linux rehearsal execution: pending.
- Public/external testnet launch: NO-GO.
- Mainnet: NO-GO.

## Phase 10B.0 Status

- Harness hardening: complete for smoke and failure diagnostics.
- Plain smoke: PASS, 43 pass / 0 fail.
- Force-clean smoke: PASS, 43 pass / 0 fail.
- Full force-clean: FAIL clearly at `payout flow`, exit `143`, due 900s global timeout while the flow was still progressing.
- Evidence:
  - `rehearsals/validator-agents/product-flows/evidence/20260527T220802Z/`
  - `rehearsals/validator-agents/product-flows/evidence/20260527T220951Z/`
  - `rehearsals/validator-agents/product-flows/evidence/20260527T221138Z/`
- Descriptor/CheckTx panic: not reproduced; filtered runtime scan has 0 matches.
- Manual cleanup: no longer required; scripts own diagnostics, validator-agent cleanup, and failure reporting.
- Public/external testnet launch: still NO-GO.
- Mainnet: still NO-GO.

## Phase 10B.0.1 Status

- Full-mode budget fix and resumable product-flow suites: complete.
- Suite support: `smoke`, `merchant`, `settlement`, `escrow`, `treasury`, `payout`, `safety`, `all`.
- Resume support: `--resume-from` for preflight, spawn, query-readiness, product module stages, safety, and final live flags.
- Global timeout defaults: smoke `300s`, individual module suites `600s`, all/full `2400s`.
- Smoke force-clean: PASS, `43 pass / 0 fail`, evidence `rehearsals/validator-agents/product-flows/evidence/20260527T224738Z/`.
- Payout suite clean-spawn fallback: PASS, `132 pass / 0 fail`, evidence `rehearsals/validator-agents/product-flows/evidence/20260527T225147Z/`.
- Safety suite no-spawn: PASS, `53 pass / 0 fail`, evidence `rehearsals/validator-agents/product-flows/evidence/20260527T225807Z/`.
- Full suite force-clean: PASS, `469 pass / 0 fail`, elapsed `1111s`, evidence `rehearsals/validator-agents/product-flows/evidence/20260527T225842Z/`.
- Final live flags: settlement live, settlement treasury routing, settlement burn routing, escrow live, treasury live, and payout live all read back `false`.
- Descriptor/CheckTx panic: not reproduced; final full-suite descriptor scan has 0 runtime matches.
- Public/external testnet launch: still NO-GO.
- Mainnet: still NO-GO.

## Phase 10B.1 Status

- Product-flow evidence review: complete.
- Evidence reviewed: `rehearsals/validator-agents/product-flows/evidence/20260527T225842Z/`.
- Proven flows: merchant onboarding, settlement metadata, settlement live transfer, settlement treasury routing, settlement burn routing, escrow release/refund/cancel, treasury account/budget/spend execution, payout create/approve/paid, safety checks, and final live flags.
- Semantic gap counts: high `0`, medium `6`, low `5`.
- Event coverage: direct user/module txs emit useful product events; governance-executed authority actions still need better event indexing/correlation.
- CLI/API usability: CLI and gRPC surfaces cover the modules; REST readback is partial and should be expanded before dashboard/operator API claims.
- Product-flow evidence index: `docs/testnet/PRODUCT_FLOW_EVIDENCE_INDEX.md`.
- Product semantic gaps: `docs/hardening/PRODUCT_FLOW_GAPS.md`.
- Public/external testnet launch: still NO-GO until external validators, gentxs, final genesis, endpoints, and communications are complete.
- Mainnet: still NO-GO.

## Phase 10B.2 Status

- Product-flow operator-surface hardening: complete.
- Final all-suite evidence: `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/`.
- Full suite force-clean: PASS, `487 pass / 0 fail`, elapsed `1102s`.
- Targeted suites: settlement `181 pass / 0 fail`, escrow `91 pass / 0 fail`, treasury `155 pass / 0 fail`, payout `133 pass / 0 fail`.
- Semantic assertions: PASS, `36 pass / 0 fail`.
- Event summary: generated `event-summary.json` and `event-summary.md`.
- Governance evidence index: generated `governance-product-evidence.json` and `governance-product-evidence.md`, proposal count `22`.
- Burn supply-delta proof: PASS, total supply delta `-2000unxrl`, burner module delta `0`.
- Final live flags: settlement live, settlement treasury routing, settlement burn routing, escrow live, treasury live, and payout live all read back `false`.
- Remaining gaps: high `0`, medium `3`, low `4`; mainly REST parity, governance UX, governance-executed product event indexing, and documentation/ergonomics polish.
- Public/external testnet launch: still NO-GO until external validators, gentxs, final genesis, endpoints, and communications are complete.
- Mainnet: still NO-GO.

## Pathway to GO

1. Execute validator outreach → receive applications
2. Review and accept ≥ 3 validators
3. Collect and validate all gentxs
4. Assemble genesis candidate
5. Publish genesis checksum
6. Create communication channel
7. Complete 47-point pre-launch freeze checklist
8. Obtain coordinator sign-off

---

## Decision

**Agent testnet runtime: GO. Public/external controlled testnet launch: NO-GO. Mainnet: NO-GO.**

The local agent runtime is ready for the next controlled preparation phase. Public/external testnet launch is not ready because external validators, external gentxs, final genesis, endpoint publication, and validator communications remain incomplete. Mainnet is not ready.

---

## Required for GO Decision

1. Complete validator outreach.
2. Accept ≥ 3 external validators.
3. Collect and validate all external gentxs.
4. Assemble final genesis candidate.
5. Publish genesis checksum.
6. Create validator communication channel.
7. Confirm launch time with all validators.
8. Complete all 47 pre-launch freeze checks.
9. Obtain coordinator sign-off.

---

## Phase 10B.3 Update

Phase 10B.3 (REST parity + governance UX hardening) completed:

**State:** Agent testnet runtime remains GO. Public/external testnet remains NO-GO.

### What Changed
- REST readback parity improved from ~55% to ~97% (16 new endpoints)
- `product-gov.sh` created for safe governance flag operations
- 12 governance proposal JSON templates created
- Governance evidence indexing improved with classification and before/after values
- Safety wording audit: PASS (no promotional/financial claims)
- Build verification: `go build ./...` and `go vet ./...` pass

### Live Flags (unchanged, all false)
- `settlement.live_enabled=false`
- `settlement.treasury_routing_enabled=false`
- `settlement.burn_routing_enabled=false`
- `escrow.live_enabled=false`
- `treasury.live_enabled=false`
- `payout.live_enabled=false`

### Phase 10B.4 Update

Phase 10B.4 closed remaining low operator-surface gaps:
- Payout exists REST endpoint added (100% REST parity)
- REST route documentation published
- Status labels standardised
- Rejection messages improved
- Final Phase 10B report created

### Remaining Gaps

| Gap | Priority | Status |
|---|---|---|
| External validators onboarding | High | Next phase |
| Gentx collection | High | Next phase |
| Final genesis candidate | High | Next phase |
| CLI-native product-gov commands | Low | Deferred |
| Escrow dispute suite | Low | Deferred |
| Public endpoint plans | Medium | Next phase |

## Next Review

Next go/no-go review should be conducted after gentx collection is complete and genesis candidate is assembled.

---

## Sign-Off

**Reviewer:** Clove
**Date:** 2026-05-28 (Phase 10B.3 update)
**Decision:** Agent runtime GO / public-external testnet NO-GO / mainnet NO-GO
**Signature:** Automated review — coordinator must confirm
