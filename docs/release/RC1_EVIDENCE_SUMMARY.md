# NexaRail RC1 — Evidence Summary

## Test Suite Results

| Evidence | Result | Source |
|---|---|---|
| Product-flow full suite | 487 pass / 0 fail, 1102s | `rehearsals/validator-agents/product-flows/evidence/20260528T003925Z/` |
| Settlement suite | 181 pass / 0 fail | Same evidence root |
| Escrow suite | 91 pass / 0 fail | Same evidence root |
| Treasury suite | 155 pass / 0 fail | Same evidence root |
| Payout suite | 133 pass / 0 fail | Same evidence root |
| Semantic assertions | 36 pass / 0 fail | Same evidence root |
| REST parity | 36/36 (100%) | `docs/api/REST_READBACK_ROUTES.md` |
| Governance templates | 12/12 valid JSON | `rehearsals/validator-agents/governance/templates/` |
| Release verification | 33/33 pass | `scripts/release/verify-testnet-rc1.sh` |
| Predeployment check | 23/23 pass | `scripts/testnet/predeployment-check.sh` |
| Safety wording audit | PASS | `docs/hardening/PHASE_10B3_SAFETY_WORDING_AUDIT.md` |
| Descriptor / CheckTx / panic | 0 issues | Phase 10B evidence |
| Burn supply delta | -2000 unxrl, burner delta 0 | `check-burn-supply-delta.sh` |
| Single-node devnet | Height 5+, REST working, live flags false | `rehearsals/rc1-devnet/evidence/` |

## Governance Proof

- **22 proposals** created, all passed on-chain
- Each proposal indexed with **before / after values**
- Located in `rehearsals/validator-agents/governance/templates/`

## Agent Testnet Runtime

| Phase | Duration | Blocks | Status |
|---|---|---|---|
| Phase 9T | Clean spawn | — | Clean |
| Phase 9U | Long soak | 673 (1 hour) | Clean |
| Phase 9V | Restart matrix | — | Clean |

## Release Package Contents

```
releases/testnet-rc1/
├── binaries/
│   ├── nexaraild-linux-amd64
│   └── nexaraild-darwin-arm64
├── checksums/
│   └── SHA256SUMS
└── ... (package root)

scripts/
├── release/
│   ├── launch-rc1-devnet.sh
│   ├── stop-rc1-devnet.sh
│   └── verify-testnet-rc1.sh
└── testnet/
    └── predeployment-check.sh

docs/
├── NEXARAIL_LITEPAPER.md
├── api/
│   └── REST_READBACK_ROUTES.md
├── hardening/
│   └── PHASE_10B3_SAFETY_WORDING_AUDIT.md
└── release/
    ├── TESTNET_RC1_EVIDENCE_MANIFEST.md
    ├── RC1_REVIEWER_README.md
    ├── RC1_QUICKSTART.md
    ├── RC1_EVIDENCE_SUMMARY.md
    └── RC1_REVIEW_CHECKLIST.md
```
