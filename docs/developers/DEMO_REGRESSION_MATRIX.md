# NexaRail — Demo Regression Matrix

> **LOCAL DEVNET ONLY — NOT MAINNET — NO TOKEN SALE**

## Purpose

This document defines the regression matrix for the NexaRail local demo workflow. It lists every check, what it proves, how to run it, and what counts as passing. Use this matrix to validate that a code change or RC1 build has not introduced regressions in the developer experience, devnet launch, or evidence collection pipeline.

---

## Status Labels

| Label | Meaning |
|---|---|
| ✅ PASS | Check completed successfully |
| ❌ FAIL | Check failed — investigate before proceeding |
| ⏭️ SKIP | Check skipped (prerequisite unmet) |
| 🔒 BLOCKED | Check cannot run (upstream dependency failed) |
| ⚠️ WARN | Check passed with caveats or partial coverage |

---

## What Is Tested

### Fast Checks (CI-safe, no devnet required)

| # | Check | What It Proves | Evidence Artifact |
|---|---|---|---|
| 1 | `go mod verify` | Go module integrity — no tampered or missing dependencies in the dependency graph. | Console output |
| 2 | `go build ./...` | All packages compile cleanly on the current platform (macOS ARM64 or Linux AMD64). | Console output |
| 3 | `go test ./... -count=1` | All unit tests pass across 15+ packages (~465 tests). Runs without test cache. | Console output |
| 4 | `predeployment-check.sh` | 23/23 checks pass: code builds, tests pass, module verification, all 6 live flags documented false, unsafe wording audit clear, 11 key docs exist, 4 required scripts are executable, Docker evidence collected. | Script exit code + console summary |
| 5 | `verify-testnet-rc1.sh` | 37/37 checks pass: release root dir, 2 binaries, SHA256 checksums, 8 key docs, 7 scripts at source, no private keys, no agent home data, manifest.json, genesis/README.md, 6 scripts in release distribution. | Script exit code + console summary |
| 6 | `check-dashboard-files.sh` | 21/21 checks pass: 4 dashboard files exist, 4 safety banner phrases in index.html, 5 forbidden code patterns absent, 3 external API endpoint checks, 4 forbidden wording checks, line counts summary. | Script exit code + `dashboard-check.txt` |
| 7 | `check-local-demo-script.sh` | Script file exists and is executable, bash syntax OK, all 6 referenced scripts exist, key docs exist, 10 forbidden wording patterns clear (or properly negated), 8 sensitive key material scans clear, 4 evidence file names referenced, EVIDENCE_DIR variable used, 3 safety banner phrases present. | Script exit code |
| 8 | `check-sdk-packages.sh` | 13/13 checks pass: Node `package.json` fields, Node `VERSION`, Node/VERSION consistency, Node tests, Python `pyproject.toml`, Python `VERSION`, Python tests, forbidden wording (Node+Python), investment/promotional wording, private key/mnemonic/seed scan, safety disclaimer presence, `LOCAL DEVNET ONLY — NOT MAINNET` warning. | Script exit code |

### Full Local Checks (devnet required)

| # | Check | What It Proves | Evidence Artifact |
|---|---|---|---|
| 8 | **RC1 package verified** | Release manifest and binary exist at `releases/testnet-rc1/`. | `devnet-status.json` |
| 9 | **Binary checksum** | SHA256 of binary matches `releases/testnet-rc1/checksums/SHA256SUMS`. | Checksum command output |
| 10 | **Devnet launch** | Single-node devnet starts, produces blocks (height ≥ 10), REST API responds. Chain ID `nexarail-devnet-1`. | `logs/devnet-launch.log`, `devnet-status.json` |
| 11 | **Live flags query** | All 4 module live flags (`settlement`, `escrow`, `treasury`, `payout`) are `false` by default in genesis. Also checks treasury_routing and burn_routing flags. | `live-flags.json` |
| 12 | **Developer examples smoke** | 11 PASS / 0 FAIL / 2 SKIP. Validates devnet liveness, REST inline checks (live flags + merchant query), 6 REST file-based checks (2 SKIP for missing `treasury_summary.sh` and `query_node_status.sh`), Node.js client (checkLiveFlags + queryProductState), Python client (check_live_flags + query_product_state). | `smoke-results.txt` |
| 13 | **Write-flow dry-run smoke** | 14 PASS / 0 FAIL. Phase 1: 7 syntax checks on all write-flow scripts (`bash -n`). Phase 2: devnet liveness check. Phase 3: 7 dry-run executions against live devnet. Scripts: bank_send_smoke, merchant_register, settlement_metadata, escrow_lifecycle, treasury_spend, payout_lifecycle, governance_toggle_demo. | `write-flow-smoke.txt` |
| 14 | **Dashboard files check** | Same as fast check #6, but runs against the live devnet environment after launch. 21/21 pass. | `dashboard-check.txt` |
| 15 | **Devnet stop** | Clean shutdown of the single-node devnet. All processes confirmed stopped. | `logs/stop-devnet.log`, `diagnostics/after-stop-pgrep.txt` |
| 16 | **Evidence summary** | Machine-readable (`summary.json`) and human-readable (`summary.md`) summary written, JSON valid. | `summary.json`, `summary.md` |

### Optional Long-Running Checks

| # | Check | What It Proves | Evidence Artifact |
|---|---|---|---|
| 17 | **Product-flow suite (5-agent)** | 487 pass / 0 fail across all product-flow scenarios with 5-agent consensus. Sub-suites: settlement (181 pass), escrow (91 pass), treasury (155 pass), payout (133 pass), semantic assertions (36 pass). REST parity: 36/36 endpoints. | `rehearsals/validator-agents/product-flows/evidence/<timestamp>/` |
| 18 | **Governance templates** | 12/12 valid JSON governance templates for product governance operations. | `rehearsals/validator-agents/governance/templates/` |
| 19 | **Full local demo with dashboard** | Complete end-to-end: RC1 verify → checksum → devnet launch → live flags → developer smoke → write-flow smoke → dashboard check → serve dashboard (port 8088) → stop → evidence. | `rehearsals/local-demo/evidence/<timestamp>/` |

---

## What Is NOT Tested

The following checks require a **live multi-validator node** and are **excluded from the single-node regression matrix**:

| Check | Why Excluded |
|---|---|
| **5-agent consensus validation** | Requires 5 separate validator processes. Single-node devnet has one validator. |
| **Product-flow full execution** | Requires 5 agents to reach consensus on write transactions. Single-node devnet uses `--single-node` mode. |
| **Transaction submission (non-dry-run)** | Write-flow smoke runs in `--execute` mode only with 5-agent consensus. Single-node dry-run validates syntax only. |
| **Governance proposal lifecycle** | Requires multi-validator voting to demonstrate proposal passage. |
| **Public testnet deployment** | Requires external validators, gentx collection, and genesis assembly. |
| **Cross-machine validator communication** | Requires P2P networking between separate hosts. |
| **Long-duration soak test** | Requires sustained operation over hours. Single-node devnet is ephemeral. |
| **External security audit** | Third-party audit pending — not in scope for regression. |

---

## Fast Checks

Run these on **every commit** or **every PR**. No devnet required. CI-safe.

```bash
# From repo root
go mod verify
go build ./...
go test ./... -count=1
bash scripts/testnet/predeployment-check.sh
bash scripts/release/verify-testnet-rc1.sh
bash scripts/dev/check-dashboard-files.sh
bash scripts/dev/check-local-demo-script.sh
```

**Expected count:** 7+ checks passing (each script exits 0).

| Check | Expected Result |
|---|---|
| `go mod verify` | ✅ PASS — exit 0 |
| `go build ./...` | ✅ PASS — exit 0 |
| `go test ./... -count=1` | ✅ PASS — exit 0 (~465 tests) |
| `predeployment-check.sh` | ✅ PASS — 23/23, exit 0 |
| `verify-testnet-rc1.sh` | ✅ PASS — 37/37, exit 0 |
| `check-dashboard-files.sh` | ✅ PASS — 21/21, exit 0 |
| `check-local-demo-script.sh` | ✅ PASS — exit 0 |

---

## Full Local Checks

Run these **before every release build**. Requires a local devnet.

```bash
bash scripts/dev/run-local-demo.sh
```

Or step by step:

```bash
# 1. Fast checks (above)
# 2. Launch devnet
bash scripts/release/launch-rc1-devnet.sh --single-node --clean --keep-running
# 3. Verify devnet health
curl -s http://127.0.0.1:26657/status | jq .
# 4. Check live flags
bash scripts/dev/run-developer-examples-smoke.sh
# 5. Run write-flow smoke
bash scripts/dev/run-write-flow-examples-smoke.sh
# 6. Check dashboard
bash scripts/dev/check-dashboard-files.sh
# 7. Stop devnet
bash scripts/release/stop-rc1-devnet.sh
```

**Expected count:** 14+ checks passing.

| Check | Expected Result |
|---|---|
| All fast checks (7) | ✅ PASS |
| RC1 package verified | ✅ PASS |
| Binary checksum | ✅ PASS |
| Devnet launch (height ≥ 10) | ✅ PASS |
| Live flags (all false) | ✅ PASS |
| Developer examples smoke | ✅ PASS (11 PASS / 0 FAIL / 2 SKIP) |
| Write-flow dry-run smoke | ✅ PASS (14 PASS / 0 FAIL) |
| Dashboard files check | ✅ PASS (21/21) |
| Devnet stop | ✅ PASS |
| Evidence summary | ✅ PASS |

---

## Local Demo Script

### With `--skip-smoke`

```bash
bash scripts/dev/run-local-demo.sh --skip-smoke
```

**Expected count:** 12+ PASS, 0 FAIL.

Steps and expected passes:

| Step | Passes | Notes |
|---|---|---|
| 1. Verify RC1 package | 2 | Manifest + binary |
| 2. Verify checksum | 1 | SHA256 verification |
| 3. Launch devnet | 1 | Height ≥ 10 |
| 4. Query live flags | 5 | 4 modules × false + saved |
| 5. Developer smoke | ⏭️ SKIP | `--skip-smoke` |
| 6. Write-flow smoke | ⏭️ SKIP | `--skip-smoke` |
| 7. Dashboard check | 1 | 21/21 |
| 8. Stop devnet | 1 | (unless `--keep-running`) |
| Summary | 1 | Evidence saved |

**Total:** 12+ (skipping 2 smoke steps)

### Full Run

```bash
bash scripts/dev/run-local-demo.sh
```

**Expected count:** 14+ PASS, 0 FAIL.

Includes all steps above plus:
- Developer examples smoke: 1 PASS
- Write-flow dry-run smoke: 1 PASS

---

## Optional Long-Running Checks

### Product-Flow Suite (5-Agent)

Run the full product-flow suite with 5-agent consensus:

```bash
cd rehearsals/validator-agents/
bash run-product-flow-suite.sh
```

**Expected:** 487 pass / 0 fail.

| Sub-suite | Expected | Notes |
|---|---|---|
| Settlement | 181 pass | Lifecycle flows |
| Escrow | 91 pass | Create → dispute → release |
| Treasury | 155 pass | Budgets, grants, spend requests |
| Payout | 133 pass | Batch payout lifecycle |
| Semantic assertions | 36 pass | Cross-module invariants |
| REST parity | 36/36 | Endpoint coverage |

**Duration:** ~18 minutes (1102s on reference hardware).

### Full Local Demo with Dashboard

```bash
bash scripts/dev/run-local-demo.sh --serve-dashboard --keep-running
```

**Expected:** 15+ PASS, 0 FAIL (includes dashboard server check).

Starts a local HTTP server at `http://localhost:8088` showing:
- Node status (height, chain ID, validators)
- Live flags (all green = false)
- Module parameters for all 6 modules
- Treasury summary
- List views for merchants, settlements, escrows, payouts

---

## Evidence Paths

All regression matrix evidence is collected to:

```
rehearsals/regression-matrix/evidence/<timestamp>/
```

Where `<timestamp>` follows the format `YYYYMMDDTHHMMSSZ` (UTC).

### Evidence Directory Structure

```
rehearsals/regression-matrix/evidence/<timestamp>/
├── env.txt                    # Environment snapshot (API, RPC, date, host)
├── summary.json               # Machine-readable summary
├── summary.md                 # Human-readable summary
├── diagnostics/
│   ├── go-version.txt         # go version output
│   ├── uname.txt              # OS/kernel info
│   └── git-status.txt         # git status + diff
├── fast-checks/
│   ├── go-mod-verify.log      # go mod verify output
│   ├── go-build.log           # go build output
│   ├── go-test.log            # go test output
│   ├── predeployment.log      # predeployment-check.sh output
│   ├── rc1-verify.log         # verify-testnet-rc1.sh output
│   ├── dashboard-check.log    # check-dashboard-files.sh output
│   └── demo-script-check.log  # check-local-demo-script.sh output
├── devnet/
│   ├── devnet-status.json     # Node status at demo time
│   ├── devnet-launch.log      # Devnet launch output
│   ├── devnet-stop.log        # Devnet stop output
│   ├── genesis.json           # Genesis snapshot
│   └── live-flags.json        # Live flags from genesis
├── smoke/
│   ├── developer-smoke.txt    # Developer examples smoke output
│   └── write-flow-smoke.txt   # Write-flow dry-run smoke output
└── regression-matrix.json     # Full matrix with PASS/FAIL/SKIP per check
```

### Existing Evidence References

| Test Suite | Evidence Root |
|---|---|
| Developer examples | `rehearsals/developer-examples/evidence/<timestamp>/` |
| Developer write-flows | `rehearsals/developer-write-flows/evidence/<timestamp>/` |
| Local demo | `rehearsals/local-demo/evidence/<timestamp>/` |
| RC1 devnet | `rehearsals/rc1-devnet/evidence/` |
| Product-flow (5-agent) | `rehearsals/validator-agents/product-flows/evidence/<timestamp>/` |
| Governance templates | `rehearsals/validator-agents/governance/templates/` |
| **Regression matrix** | `rehearsals/regression-matrix/evidence/<timestamp>/` |

---

## Known Limitations

### REST / gRPC Gateway

- **REST is readback-only** in this release. Transaction broadcast uses the generic Cosmos SDK `/cosmos/tx/v1beta1/txs` endpoint. No NexaRail-specific tx broadcast endpoint exists.
- **gRPC gateway operates in single-node mode only.** Multi-node REST proxy is not validated by the regression matrix.

### Build Environment

- **Go 1.26+ required.** Older Go versions (≤1.24) may produce build failures due to language features used in the codebase.
- **macOS ARM64 and Linux AMD64 only.** No Windows support. No 32-bit support.

### Devnet Scope

- **Single-node devnet** validates developer experience but does not demonstrate multi-validator consensus, P2P networking, or cross-machine state replication.
- **Write flows run in dry-run mode only** in the regression matrix. For full execution, use the 5-agent product-flow suite.
- **Governance proposal lifecycle** is not tested in the single-node matrix. Use the 5-agent suite for governance validation.

### Evidence Collection

- **Evidence timestamps** are UTC. Local timezone differences may cause confusion when correlating evidence with release builds.
- **Diagnostic files** may contain paths specific to the host machine (e.g., `/Users/bradleyjohnston/...`). These are normal for local evidence.

### Safe Harbor

- No mainnet infrastructure, incentives, or guarantees are implied.
- Tokens on the devnet have **zero monetary value**.
- All live-funds flags default to `false` and must never be toggled to `true` outside a mainnet-grade release.

---

## Quick Reference

### Run All Fast Checks

```bash
for check in \
  "go mod verify" \
  "go build ./..." \
  "go test ./... -count=1" \
  "bash scripts/testnet/predeployment-check.sh" \
  "bash scripts/release/verify-testnet-rc1.sh" \
  "bash scripts/dev/check-dashboard-files.sh" \
  "bash scripts/dev/check-local-demo-script.sh"; do
  echo "── $check ──"
  $check && echo "✅" || echo "❌"
done
```

### Run Full Local Demo

```bash
bash scripts/dev/run-local-demo.sh
```

### Run Local Demo (Smoke Skipped)

```bash
bash scripts/dev/run-local-demo.sh --skip-smoke
```

### Run Full Product-Flow Suite

```bash
cd rehearsals/validator-agents && bash run-product-flow-suite.sh
```

### Check Evidence

```bash
# Latest regression matrix evidence
ls -lt rehearsals/regression-matrix/evidence/ | head -5

# Read summary
cat rehearsals/regression-matrix/evidence/$(ls -t rehearsals/regression-matrix/evidence/ | head -1)/summary.md
```

---

*End of regression matrix.*
