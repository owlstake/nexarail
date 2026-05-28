# Phase 10B.1 Product-Flow Evidence Review

**Date:** 2026-05-28  
**Scope:** Semantic review of the successful Phase 10B full product-flow rehearsal  
**Evidence root:** `rehearsals/validator-agents/product-flows/evidence/20260527T225842Z/`  
**Result reviewed:** `469 pass / 0 fail`, elapsed `1111s`, suite `all`

## Summary

The Phase 10B full product-flow rehearsal proves that the local 5-agent runtime can execute the core product paths end to end under harness ownership:

- clean local 5-agent spawn;
- RPC, height, query, address, and module-account readiness;
- merchant onboarding and status controls;
- metadata-only settlement;
- live settlement merchant-net transfer;
- live treasury-share routing;
- live burn routing;
- escrow create, release, refund, cancel, and double-release rejection;
- treasury account, budget, spend request, approval/execution, and double-execute rejection;
- payout create, approve, governance-authorized paid marking, treasury outflow, and double-pay rejection;
- safety checks and final live-flag restoration.

This evidence is local agent-testnet evidence only. It does not prove external validator participation, public/external testnet launch readiness, mainnet readiness, NXRL buyability, or external decentralisation.

## Top-Level Evidence

| Artifact | Evidence |
|---|---|
| Summary | `summary.json` |
| Run log | `run.log` |
| Stage durations | `stage-durations.tsv` |
| Final live flags | `final-live-flags.json` |
| Descriptor/CheckTx scan | `descriptor-errors.txt` with 0 lines |
| Final module state | `final-state/module-state/` |
| Runtime logs | `logs/` |
| Tx artifacts | `merchant/`, `settlement/`, `escrow/`, `treasury/`, `payout/`, `safety/`, `txs/` |
| Query artifacts | `queries/` and per-flow query JSON files |

## Flow Proofs

### Merchant Onboarding

| Field | Evidence |
|---|---|
| Status | PASS |
| Main tx hashes | Register `6CA4902097867B0A8F40E8577558150C03B4FB6C619A55303B4019EED5EB9844`; update `9217339AB20EC1269BA6405FF861019922DF0032D413C0ACDEC56580D07030E6` |
| Governance txs | Set inactive proposal `1` via `BF2A6DB01F17067F5E492611734B10FC63AC9F9569DA21D391FDA94AD60FF7DA`; restore active proposal `2` via `23877C64BAD3F3FF5A1A1584B5E73506CB902C002D492C74C136EFB44A7118D5` |
| Balance evidence | Not a live-funds flow; tx inclusion and state queries are the material proof |
| State query evidence | `merchant/query-merchant.json`, `merchant/query-merchants.json`, `final-state/module-state/merchants.json` |
| Events captured | `merchant_registered`, `merchant_updated`; governance proposal submit events for status changes |
| Final state | Primary merchant active with updated profile; payout recipient merchant also registered |
| Caveats | Status changes are authority actions executed through governance proposal JSON; no dedicated product-level governance helper is documented yet |

### Settlement Metadata

| Field | Evidence |
|---|---|
| Status | PASS |
| Main tx hash | `87DE6CF5605DC9A3D802E31E371EBAF592FDD5FAA4A81CB7D916C1FBDDF1B4DF` |
| Balance evidence | `settlement/metadata/bravo-delta.txt` shows merchant delta `0`; `settlement/metadata/treasury-delta.txt` shows treasury delta `0` |
| State query evidence | `settlement/metadata/settlement-1.json`, `settlement/metadata/settlements.json`, `settlement/metadata/by-merchant.json` |
| Events captured | `settlement_created` with `funds_settled=false` |
| Final state | Settlement `1` stored with metadata `phase10b-metadata-only`, `funds_settled=false`, `burn_executed=false` |
| Caveats | Metadata-only settlement proves record creation, not live transfer |

### Settlement Live

| Field | Evidence |
|---|---|
| Status | PASS |
| Governance txs | Enable live proposal `3` via `C0C595E3F4B6429125CB6A0D8C90FB4F3E6809D484373D9102E6249269B86852`; disable proposal `4` via `B433080E8DE2812961EEE1C4754651DFE7C9A94A19EC9E988BC058726C0608B0` |
| Main tx hash | `9AD2C25E83ACFBE80ED988289A7BC800AE91DB1B0689DDF372BDD7EAE7A2FE61` |
| Balance evidence | `settlement/live/bravo-delta.txt` shows merchant delta `990000`; `settlement/live/treasury-delta.txt` shows treasury delta `0` |
| State query evidence | `settlement/live/settlement-2.json`, `settlement/live/settlements.json` |
| Events captured | `settlement_created`; bank transfer events; governance proposal submit/vote/final status artifacts |
| Final state | Settlement `2` has `funds_settled=true`, `burn_executed=false`, metadata `phase10b-live` |
| Caveats | Validator-share distribution is fee accounting metadata in this rehearsal; treasury/burn routing are covered by separate flows |

### Settlement Treasury Routing

| Field | Evidence |
|---|---|
| Status | PASS |
| Governance txs | Enable treasury routing proposal `5` via `ECA4EF27A476CF5E8EFF8C6A40EE68632BCC6A4FC13FC149A74C03F9546EF896`; disable proposal `6` via `A0CD3165851E7E241AB2A37E409FBFC6ECD5107A04CB136316139F5C49C7301F` |
| Main tx hash | `F4829DC66FF3B562C72D4AFF7394AFED858344457AF9E00733114AF6B2CCFECC` |
| Balance evidence | `settlement/treasury-routing/bravo-delta.txt` shows merchant delta `990000`; `settlement/treasury-routing/treasury-delta.txt` shows treasury module delta `2000` |
| State query evidence | `settlement/treasury-routing/settlement-3.json`, `settlement/treasury-routing/settlements.json` |
| Events captured | `settlement_created` with treasury-routing attributes; bank transfer events |
| Final state | Settlement `3` has `funds_settled=true`, `burn_executed=false`, metadata `phase10b-treasury-routing` |
| Caveats | REST summary proves account counts, but REST does not yet expose all detailed treasury entity routes used by CLI/gRPC |

### Settlement Burn Routing

| Field | Evidence |
|---|---|
| Status | PASS |
| Governance txs | Enable burn routing proposal `7` via `91158490CA3716C42816CBB00521221A027249A60966CD65EFB378FFC949691D`; disable proposal `8` via `6CD687A1A871A512B1AE61E4C67C84C8903E30526E50F3EB7512990706A9761A` |
| Main tx hash | `C9BA4326A817CAF10BC2CF34A2A78320906951CCD14FEC376DB904B2ECA5AF08` |
| Balance evidence | `settlement/burn-routing/bravo-delta.txt` shows merchant delta `990000`; `settlement/burn-routing/treasury-delta.txt` shows treasury module delta `2000` |
| State query evidence | `settlement/burn-routing/settlement-4.json`, `settlement/burn-routing/settlements.json` |
| Events captured | `settlement_created`; bank `burn` event; bank transfer events |
| Final state | Settlement `4` has `funds_settled=true`, `burn_executed=true`, metadata `phase10b-burn-routing` |
| Caveats | `settlement/burn-routing/supply-note.txt` did not capture before/after supply values, so the strongest burn evidence is tx event + settlement state, not an explicit total-supply delta |

### Escrow

| Field | Evidence |
|---|---|
| Status | PASS |
| Governance txs | Enable escrow live proposal `9` via `DDC8F126C7F00C95B9FB9671373E1771C946738D5693D56D519A3FC020F98F9A`; disable proposal `10` via `8F561228EAB9D3F5E71A906C66E6A8371FB9D8AE94EC00A71413F86B94422732` |
| Main tx hashes | Create release case `383CA2A216282BC7C5252B69EA5DD651038C7EF1BD3EF286C29A3626940C739C`; release `6FA096663396202DC50BEE37085B74F660F074B26F5CE1A8152827BDFF4EDB90`; create refund `ADF0F0E87A75FF8D2E1E58B1BEF11AF8888E271EF50F6A48E601A1CD30F5F63B`; refund `68425404D04236FEC5D0C06A8B90DD51D3252BFCC60308FBE86708B0C0594965`; create cancel `8FC3334E5EEC893F797873695E39B7FF463E178D734DD74D8026FB5368058011`; cancel `A732367571008BC698724DC08F9F8DE7A12F37E1224653483232D815F92D8342` |
| Balance evidence | `escrow/release-escrow-custody-delta.txt` shows custody delta `250000`; `escrow/release-bravo-delta.txt` shows seller delta `250000`; refund/cancel notes show module custody returns to `0` |
| State query evidence | `escrow/escrows.json`, `final-state/module-state/escrows.json` |
| Events captured | `escrow_created`, `escrow_released`, `escrow_refunded`, `escrow_cancelled`; bank transfer events |
| Final state | Release case status `3`, refund case status `4`, cancel case status `6`; all have `funds_custodied=false` |
| Caveats | Dispute and resolve-dispute commands exist but were not part of this product-flow suite |

### Treasury

| Field | Evidence |
|---|---|
| Status | PASS |
| Governance txs | Enable treasury proposal `11` via `9D1B8CE387587413177936D95934479839599DEC651C3A27249BD9ACAB9F195B`; create account proposal `12` via `FE169813095229B8D56DFF34EBB4D36EE382AE588C778C4A514F9A6268B84A20`; create budget proposal `13` via `9397C331FE67BE73F2855808EFE0EAB074771578BBC8A7BAB815C35222237B98`; approve/execute proposal `14` via `6F0EC7BD24B0FBF9BA309BCA52701E069429212DC286AFE72C0500EC0434F8EE`; disable proposal `15` via `9575B2CD7FA0D75DDCE68531D0C1FE7D82C37DDDEE24A91B7DDA334E4B79F420` |
| Main tx hash | Create spend request `F320BCE983C46E4C032EBE857ABC372A968B0851B59E9315D2316AECAB6053FA` |
| Balance evidence | `treasury/recipient-delta.txt` shows recipient delta `1000`; `treasury/treasury-module-delta.txt` shows treasury module delta `-1000` |
| State query evidence | `treasury/spend-query.json`, `treasury/treasury-summary.json`, `final-state/module-state/treasury-summary.json` |
| Events captured | Direct create-spend tx emits `spend_request_created`; governance submit txs emit gov proposal events; state readback proves approve/execute result |
| Final state | One treasury account, one budget, one spend request; spend request status `4`, `funds_executed=true` |
| Caveats | Account/budget creation and spend approval/execution happen through governance; module-specific execution events are not captured in the submit tx artifact because execution occurs when the proposal passes |

### Payout

| Field | Evidence |
|---|---|
| Status | PASS |
| Governance txs | Enable payout proposal `16` via `5BC69DB846DEAC0C6D0126173DEF5F7870188EEBC66D624A06A4D4B4DD70ECA8`; mark-paid proposal `17` via `24A804E60276348FB3C6F188853930497846466FEED14D632D91731283EF5BC5`; disable proposal `18` via `9F6D11936BC2F7B27331FC66A0E449EE7B2CB7062C2E73C45C3F608DF261951E` |
| Main tx hashes | Fund recipient merchant `CB5815D213343C87677A17A3908DB5E9B33275EFA59AC32581684941759AFDAB`; register recipient merchant `B6F96F70CBC41FBE4DB3472BA289AA1311D2B3617CB9995B693148B27739D833`; create payout `130CB7DAF141301A14709FF5DD3940E39F6302E6B5C63A169E2D9FC311603457`; approve payout `E349FCDE5C987A6DD86B66F2D3FCB572890677264E2179A6970C34328A3EDA14` |
| Balance evidence | `payout/recipient-delta.txt` shows recipient delta `1000`; `payout/treasury-module-delta.txt` shows treasury module delta `-1000` |
| State query evidence | `payout/payout-query.json`, `payout/payouts.json`, `final-state/module-state/payouts.json` |
| Events captured | `merchant_registered`, `payout_created`, `payout_approved`; governance proposal events for mark-paid; state/balance proof for paid execution |
| Final state | Payout `phase10b-payout` has status `3`, `funds_paid=true`, `external_reference=phase10b-paid` |
| Caveats | `payout mark-paid` is authority-only; the normal operator path is governance/scripted proposal, not a simple signer-only CLI path |

### Safety And Final Live Flags

| Field | Evidence |
|---|---|
| Status | PASS |
| Safety tx hashes | Unauthorized settlement params rejection `46745F614888FFE3180F983B08C36DDE74AA83BF303A67BDF645802A772C8B7A`; failed payout after disable `DD48E9E53C6CB414BB72830161DDC662C7BF812CDEB7866EDC237AC74B1B40B9` |
| Final restoration txs | Settlement restore proposal `19` via `3C3338C52C135ECE5B4F797FD4754761EAACCDDCE79C8D9EC4C98FD5B256DCF9`; escrow restore proposal `20` via `BA2CE762A6D961E05F2649D17389F3D203A39B2FFA84A090E7F17378FDC29D61`; treasury restore proposal `21` via `2E4913E09507BD944AB0907BACFCAE8B23C4CD04B8EF351FFB139E38C0CC0CB1`; payout restore proposal `22` via `B16392DF55709A2CBC23A28CC13452FB4DB8722E3E423A8C10231039DA1CBBD3` |
| Balance evidence | Safety checks focus on rejection and final flag readback |
| State query evidence | `safety/pre-final-flags/live-flags.txt`, `final-state/live-flags.txt`, `final-live-flags.json` |
| Events captured | Rejected txs include generic fee/message events; gov submit/vote/final-status artifacts captured for restoration proposals |
| Final state | All live flags false: settlement live, treasury routing, burn routing, escrow live, treasury live, payout live |
| Caveats | Rejected tx event payloads are generic; product-specific rejection analytics should use tx result codes/log strings unless richer failure events are added later |

## Stage Timing

| Stage | Duration |
|---|---:|
| Clean spawn | 77s |
| Height readiness | 58s |
| Merchant flow | 97s |
| Settlement metadata flow | 5s |
| Settlement live flow | 83s |
| Settlement treasury routing flow | 78s |
| Settlement burn routing flow | 81s |
| Escrow flow | 112s |
| Treasury flow | 200s |
| Payout flow | 139s |
| Safety checks | 8s |
| Restore live flags false | 154s |
| Full suite total | 1111s |

## Semantic Conclusion

The full local product-flow suite is proven at runtime. The remaining issues are not protocol blockers in this evidence; they are semantic/operator gaps around API coverage, event indexing, governance UX, evidence precision, and documentation polish. Those are tracked in `docs/hardening/PRODUCT_FLOW_GAPS.md`.

## Phase 10B.2 Evidence Hardening Addendum

Phase 10B.2 reran the full suite after adding operator-surface evidence artifacts and stricter semantic assertions.

| Field | Result |
|---|---|
| Evidence root | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/` |
| Full suite | PASS, `487 pass / 0 fail`, elapsed `1102s` |
| Semantic assertions | PASS, `36 pass / 0 fail` in `semantic-assertions.json` |
| Event summary | Generated `event-summary.json` and `event-summary.md` |
| Governance index | Generated `governance-product-evidence.json` and `governance-product-evidence.md`; proposal count `22` |
| Burn supply delta | PASS, total supply delta `-2000unxrl`, burn share `2000unxrl`, burner module delta `0` |
| Final live flags | All false in `final-live-flags.json` |
| Descriptor/CheckTx scan | `descriptor-errors.txt` empty |

Targeted suite reruns also passed:

| Suite | Evidence | Result |
|---|---|---|
| Settlement | `rehearsals/validator-agents/product-flows/evidence/20260528T000636Z/` | `181 pass / 0 fail`, elapsed `398s` |
| Escrow | `rehearsals/validator-agents/product-flows/evidence/20260528T002058Z/` | `91 pass / 0 fail`, elapsed `261s` |
| Treasury | `rehearsals/validator-agents/product-flows/evidence/20260528T002534Z/` | `155 pass / 0 fail`, elapsed `426s` |
| Payout | `rehearsals/validator-agents/product-flows/evidence/20260528T003258Z/` | `133 pass / 0 fail`, elapsed `370s` |

The Phase 10B.2 additions close the evidence precision gaps for event summaries, governance-action indexing, burn supply delta proof, JSON readback semantics, and treasury/payout funding prerequisites. Remaining gaps are operator-surface gaps: REST parity, governance UX, governance-executed product event indexing, status labels, selected rejection-message clarity, escrow dispute coverage, and REST route documentation.
