# NexaRail RC1 — CI Checks Reference

> **LOCAL DEVNET ONLY — NOT MAINNET — NO TOKEN SALE**

## Purpose

This document catalogues every CI and pre-release check for the NexaRail RC1 (Controlled Testnet Release Candidate 1) workflow. Each entry describes the check's purpose, how it is run, and the expected outputs.

---

## Check Details

### 1. Predeployment Check

**Script:** `scripts/testnet/predeployment-check.sh`

**Result:** 23/23 PASS

**Purpose:** Validates that the codebase, documentation, scripts, and live-network flags are ready before any release or deployment. Runs code tests, module verification, unsafe wording audit, key documentation existence, and rehearsal evidence collection.

**When to run:** Every RC1 build, before release tagging.

**CI-safe:** Partial — requires Docker evidence directory (optional, not blocking).

**Checks:**

| # | Check | What It Proves |
|---|---|---|
| 1 | `go build ./...` | All packages compile |
| 2 | `go vet ./...` | Static analysis passes |
| 3 | `go test ./...` | All unit tests pass |
| 4 | `go mod tidy` | Module graph is consistent |
| 5 | `go mod verify` | No tampered dependencies |
| 6 | Live flags documented as false | Phase 6J.2 evidence confirms 6 flags false |
| 7 | Unsafe wording audit | All 10 evaluated terms clean across 50+ docs |
| 8–18 | 11 required docs exist | Release checklist, validator registration, FAQ, audit package, security review, threat register, tagging policy, change control, pre-deployment review, README |
| 19–22 | 4 required scripts executable | verify-submitted-gentx.sh, assemble-testnet-genesis.sh, check-final-genesis.sh, run-hardening-suite.sh |
| 23 | Docker evidence collected | At least one rehearsal session exists |

**Expected output:**
```
╔══════════════════════════════════════════╗
║  Pre-Deployment Check Complete          ║
╠══════════════════════════════════════════╣
║  Passed: 23  Failed: 0                  ║
║  ✅ Code gates pass                     ║
╚══════════════════════════════════════════╝
```

---

### 2. RC1 Verification

**Script:** `scripts/release/verify-testnet-rc1.sh`

**Result:** 37/37 PASS

**Purpose:** Validates the complete RC1 release package: binaries for both platforms, checksum integrity, all required documentation, scripts, release distribution copies, security constraints (no private keys, no agent home data), and manifest integrity.

**When to run:** After every RC1 build, before release distribution.

**CI-safe:** Partial — requires `releases/testnet-rc1/` directory populated.

**Checks grouped by category:**

| Category | Checks | Count | Description |
|---|---|---|---|
| Release directory | 1 | 1 | Root exists |
| Binaries | 2 | 3 | `nexaraild-darwin-arm64`, `nexaraild-linux-amd64` |
| Checksums | ~2+ | 5+ | SHA256SUMS file + per-entry verification |
| Documentation | 8 | 13 | Release notes, limitations, evidence manifest, API docs, hardening report, litepaper, reviewer docs |
| Source scripts | 7 | 20 | Multi-machine validator scripts, genesis scripts, smoke tests, deployment check, verify script itself |
| Security (no keys) | 1 | 21 | No PEM/private key files in release dir |
| Security (no agent data) | 4 | 25 | No `.node_key`, `priv_validator_key*`, `node_key.json`, `priv_validator_key.json` in release dir |
| Manifests | 1 | 26 | `manifest.json` exists |
| Genesis | 1 | 27 | `genesis/README.md` exists |
| Release distribution scripts | 6 | 33 | Copies of all key scripts in `releases/testnet-rc1/scripts/` |
| Checksum loop entries | ~4 | 37 | Per-entry hash verification in SHA256SUMS |

**Expected output:**
```
══════════════════════════════════════════════════════
  Verification Complete
  Passed: 37    Failed: 0
══════════════════════════════════════════════════════
  ✅ RC1 packaging verification PASSED.
```

---

### 3. Local Demo Script Check

**Script:** `scripts/dev/check-local-demo-script.sh`

**Result:** ✅ PASS (exit 0)

**Purpose:** Validates the `run-local-demo.sh` script for existence, syntax, referenced scripts, documentation, forbidden wording, sensitive key material, evidence file naming, and safety banner completeness. Ensures the demo script is safe and complete before distribution.

**When to run:** Every commit that modifies `run-local-demo.sh` or its referenced scripts. CI-safe.

**CI-safe:** Yes — no devnet required.

**Checks by category:**

| Check # | Category | Individual Checks | Expected |
|---|---|---|---|
| 1 | File existence & executability | 2 | Script exists and is executable |
| 2 | Bash syntax (`bash -n`) | 1 | No syntax errors |
| 3 | Referenced script existence | 6 | `launch-rc1-devnet.sh`, `stop-rc1-devnet.sh`, `run-developer-examples-smoke.sh`, `run-write-flow-examples-smoke.sh`, `check-dashboard-files.sh`, `serve-dashboard.sh` |
| 4 | Referenced documentation | ~3 | `LOCAL_DEMO_GUIDE.md`, `DEVELOPER_QUICKSTART.md`, plus any inline doc refs |
| 5 | Forbidden wording | 10 patterns | None found (or properly negated): mainnet live, buy NXRL, token sale, investment, guaranteed, profit, APY, returns, price, listing |
| 6 | Sensitive key material | 7 patterns | None found without safety warning: private key, mnemonic, seed phrase, secret key |
| 7 | Evidence file names | 5 | `summary.json`, `summary.md`, `devnet-status.json`, `live-flags.json` referenced; `EVIDENCE_DIR` variable used |
| 8 | Safety banner | 3 | "not mainnet", "no token sale", "zero monetary value" present |

**Expected output:**
```
═══════════════════════════════════════════════════════════════
  Local Demo Script Check — Summary
  PASS: 33  FAIL: 0
═══════════════════════════════════════════════════════════════
```

---

### 4. Dashboard File Check

**Script:** `scripts/dev/check-dashboard-files.sh`

**Result:** 21/21 PASS

**Purpose:** Validates all dashboard files in `examples/dashboard/` for existence, safety banner compliance, forbidden code patterns (wallet/crypto), external API endpoint hardcoding, and forbidden wording. Ensures the dashboard is safe for developer demo use.

**When to run:** Every commit that modifies dashboard files. CI-safe.

**CI-safe:** Yes — no devnet required.

**Checks:**

| # | Check | Description |
|---|---|---|
| 1–4 | File existence | `index.html`, `app.js`, `styles.css`, `README.md` all exist with content |
| 5–8 | Safety banner | "not mainnet", "no token sale", "no monetary value", "live funds disabled" present in `index.html` |
| 9–13 | Forbidden code patterns | No "wallet", "privateKey", "mnemonic", "private_key", "secret", "keystore" in `app.js` |
| 14–16 | External API check | No hardcoded non-localhost URLs in `index.html`, `app.js`, `styles.css` |
| 17–20 | Forbidden wording | No "mainnet live", "buy NXRL", "token sale" (unqualified) in any dashboard file |
| 21 | Line counts summary | All files counted and displayed |

**Expected output:**
```
── Summary ──────────────────────────────────────────────────
  PASS: 21  FAIL: 0
─────────────────────────────────────────────────────────────
```

---

### 5. Developer Examples Smoke

**Script:** `scripts/dev/run-developer-examples-smoke.sh`

**Result:** 11 PASS / 0 FAIL / 2 SKIP

**Purpose:** Validates that developer client examples (REST scripts, Node.js client, Python client) can successfully connect to a live devnet, query state, and check live flags. Two REST scripts (`treasury_summary.sh`, `query_node_status.sh`) are skipped because they do not exist in the `examples/rest/` directory.

**When to run:** Before every release. Requires a running devnet.

**Requires devnet:** Yes.

**CI-safe:** No.

**Checks:**

| # | Check | Expected |
|---|---|---|
| 1 | Devnet liveness | Reachable at RPC, height returned |
| 2 | `check_live_flags.sh` (inline) | REST params queried for all 4 modules |
| 3 | `query_merchant.sh` (inline) | Merchant count returned (may be 0) |
| 4 | `check_live_flags.sh` (file) | REST file script executes |
| 5 | `query_merchant.sh` (file) | REST file script executes |
| 6 | `query_settlement.sh` (file) | REST file script executes |
| 7 | `query_escrow.sh` (file) | REST file script executes |
| 8 | `query_payout.sh` (file) | REST file script executes |
| 9 | `treasury_summary.sh` (file) | ⏭️ SKIP — script not in `examples/rest/` |
| 10 | `query_node_status.sh` (file) | ⏭️ SKIP — script not in `examples/rest/` |
| 11 | `node-client checkLiveFlags` | Node.js script queries live flags |
| 12 | `node-client queryProductState` | Node.js script queries full product state |
| 13 | `python-client check_live_flags` | Python script queries live flags |
| 14 | `python-client query_product_state` | Python script queries full product state |

**Expected output:**
```
── Summary ────────────────────────────────────────
  PASS: 11
  FAIL: 0
  SKIP: 2
───────────────────────────────────────────────────
```

---

### 6. Write-Flow Smoke

**Script:** `scripts/dev/run-write-flow-examples-smoke.sh`

**Result:** 14 PASS / 0 FAIL

**Purpose:** Validates all 7 write-flow example scripts exist, have valid shell syntax, and run successfully in dry-run mode against a live devnet. Dry-run mode validates command construction without submitting real transactions.

**When to run:** Before every release. Requires a running devnet.

**Requires devnet:** Yes.

**CI-safe:** No.

**Checks:**

| Phase | Check | Script | Expected |
|---|---|---|---|
| Phase 1 | Syntax check | `bash -n bank_send_smoke.sh` | ✅ PASS |
| Phase 1 | Syntax check | `bash -n merchant_register.sh` | ✅ PASS |
| Phase 1 | Syntax check | `bash -n settlement_metadata.sh` | ✅ PASS |
| Phase 1 | Syntax check | `bash -n escrow_lifecycle.sh` | ✅ PASS |
| Phase 1 | Syntax check | `bash -n treasury_spend.sh` | ✅ PASS |
| Phase 1 | Syntax check | `bash -n payout_lifecycle.sh` | ✅ PASS |
| Phase 1 | Syntax check | `bash -n governance_toggle_demo.sh` | ✅ PASS |
| Phase 2 | Devnet liveness | RPC and REST reachable | ✅ INFO |
| Phase 3 | Dry-run execution | Bank Send Smoke | ✅ PASS |
| Phase 3 | Dry-run execution | Merchant Register | ✅ PASS |
| Phase 3 | Dry-run execution | Settlement Metadata | ✅ PASS |
| Phase 3 | Dry-run execution | Escrow Lifecycle | ✅ PASS |
| Phase 3 | Dry-run execution | Treasury Spend | ✅ PASS |
| Phase 3 | Dry-run execution | Payout Lifecycle | ✅ PASS |
| Phase 3 | Dry-run execution | Governance Toggle Demo | ✅ PASS |

**Expected output:**
```
───────── Write-Flow Smoke Summary ──────────
  PASS:  14
  FAIL:  0
──────────────────────────────────────────────
  [PASS] All 14 checks passed.
```

---

### 7. SDK Package Check

**Script:** `scripts/dev/check-sdk-packages.sh`

**Result:** ✅ PASS (13/13)

**Purpose:** Validates the Node.js and Python developer SDK packages prepared in `examples/node-client/` and `examples/python-client/`. Verifies package metadata, version consistency, runs SDK tests, and audits the SDK source for forbidden wording, investment/promotional tone, unsafe private-key usage, and presence of safety disclaimers (`LOCAL DEVNET ONLY — NOT MAINNET`).

**When to run:** Every commit touching the SDK packages, every PR, and before every release.

**Requires devnet:** No.

**CI-safe:** Yes.

**Notes:**
- Node tests run if `node` is available (`examples/node-client/test/client.test.js`), otherwise SKIP.
- Python tests run if `python3` is available (`examples/python-client/test_client.py`), otherwise SKIP.
- Packages remain **local-install only** — no npm or PyPI publishing.

---

### 8. API Smoke

**Script:** `scripts/testnet/api-smoke-test.sh` (via `launch-rc1-devnet.sh` or standalone)

**Result:** ✅ PASS (exit 0)

**Purpose:** Validates that the REST API endpoints are reachable and return expected responses when the devnet is running. Covers a subset of the 36 documented readback endpoints.

**When to run:** Before every release. Requires a running devnet with REST enabled.

**Requires devnet:** Yes, with REST API enabled at `http://localhost:1317`.

**CI-safe:** No.

**Note:** No dedicated API smoke script is present in `scripts/dev/`. The primary REST validation occurs through:
- `launch-rc1-devnet.sh` — inline REST readiness probe
- `run-developer-examples-smoke.sh` — REST endpoint queries as part of developer examples
- `scripts/testnet/api-smoke-test.sh` — standalone API smoke (requires devnet)

---

## Run Frequency

| Check | Frequency | Requires Devnet | CI-safe | Estimated Time |
|---|---|---|---|---|
| `go mod verify` | Every commit | No | Yes | < 10 s |
| `go build ./...` | Every commit | No | Yes | < 60 s |
| `go test ./...` | Every commit | No | Yes | < 120 s |
| `predeployment-check.sh` | Every RC1 build | No | Partial | < 180 s |
| `verify-testnet-rc1.sh` | Every RC1 build | No | Partial | < 30 s |
| `check-local-demo-script.sh` | Every commit | No | Yes | < 10 s |
| `check-dashboard-files.sh` | Every commit | No | Yes | < 10 s |
| `check-sdk-packages.sh` | Every commit | No | Yes | < 20 s |
| Developer examples smoke | Before release | Yes | No | < 60 s |
| Write-flow dry-run smoke | Before release | Yes | No | < 180 s |
| API smoke | Before release | Yes | No | < 30 s |
| Product-flow suite (5-agent) | Major release | Yes (5-agent) | No | ~18 min |
| Full local demo with dashboard | Major release | Yes | No | < 300 s |

### Rules

1. **Fast checks** (rows 1–7) must pass before any commit is merged.
2. **Devnet-dependent checks** (rows 8–10) must pass before any release is tagged.
3. **Product-flow suite** must pass before any major release (e.g., public testnet, mainnet).
4. **Full local demo** is the integration test that combines all checks into one command.

---

## Expected Outputs Per Check

### `go mod verify`
```
go: verifying module graph... ok
<exit 0>
```

### `go build ./...`
```
<no output — exit 0>
```

### `go test ./... -count=1`
```
ok  github.com/nexarail/app     0.234s    coverage: 45.3% of statements
ok  github.com/nexarail/x/settlement 0.567s coverage: 72.1% of statements
...
<exit 0>
```

### `predeployment-check.sh`
```
║  Passed: 23  Failed: 0                  ║
║  ✅ Code gates pass                     ║
<exit 0>
```

### `verify-testnet-rc1.sh`
```
  Passed: 37    Failed: 0
  ✅ RC1 packaging verification PASSED.
<exit 0>
```

### `check-dashboard-files.sh`
```
  PASS: 21  FAIL: 0
<exit 0>
```

### `check-local-demo-script.sh`
```
  PASS: 33  FAIL: 0
<exit 0>
```

### Developer examples smoke
```
  PASS: 11
  FAIL: 0
  SKIP: 2
<exit 0>
```

### Write-flow dry-run smoke
```
  PASS:  14
  FAIL:  0
  [PASS] All 14 checks passed.
<exit 0>
```

### Full local demo (`--skip-smoke`)
```
  Pass: 12  Fail: 0  Skip: 2
  Evidence: rehearsals/local-demo/evidence/<timestamp>/
<exit 0>
```

### Full local demo (with smoke)
```
  Pass: 14  Fail: 0  Skip: 0
  Evidence: rehearsals/local-demo/evidence/<timestamp>/
<exit 0>
```

### Product-flow suite (5-agent)
```
  Settlement: 181 pass / 0 fail
  Escrow:      91 pass / 0 fail
  Treasury:   155 pass / 0 fail
  Payout:     133 pass / 0 fail
  Total:      487 pass / 0 fail
  Duration:   1102s
<exit 0>
```

---

## CI Pipeline Stages (Recommended)

### Stage 1: Fast Checks (every commit)
```yaml
stage: fast
checks:
  - go mod verify
  - go build ./...
  - go test ./... -count=1
  - bash scripts/dev/check-local-demo-script.sh
  - bash scripts/dev/check-dashboard-files.sh
```

### Stage 2: Pre-Release (every RC1 tag)
```yaml
stage: pre-release
checks:
  - bash scripts/testnet/predeployment-check.sh
  - bash scripts/release/verify-testnet-rc1.sh
```

### Stage 3: Devnet Integration (before release, manual trigger)
```yaml
stage: devnet
checks:
  - bash scripts/release/launch-rc1-devnet.sh --single-node --clean
  - bash scripts/dev/run-developer-examples-smoke.sh
  - bash scripts/dev/run-write-flow-examples-smoke.sh
  - bash scripts/testnet/api-smoke-test.sh
  - bash scripts/release/stop-rc1-devnet.sh
```

### Stage 4: Full Integration (major release, manual trigger)
```yaml
stage: full-integration
checks:
  - bash scripts/dev/run-local-demo.sh
  - cd rehearsals/validator-agents && bash run-product-flow-suite.sh
```

---

## Failure Recovery

| Check Fails | Immediate Action | Escalation |
|---|---|---|
| `go mod verify` | `go mod tidy`, verify `go.sum` | Check for network issues, proxy corruption |
| `go build ./...` | Fix compilation errors | Check for Go version mismatch (requires 1.26+) |
| `go test ./...` | `go test -v -count=1 ./... --run=<failing-test>` | Review test for environmental dependency |
| `predeployment-check.sh` | Check which of the 23 checks failed | Missing docs, scripts, or evidence |
| `verify-testnet-rc1.sh` | Rebuild RC1 package | Missing release assets |
| Dashboard check | Fix missing/wrong dashboard files | Safety banner or forbidden pattern issue |
| Demo script check | Fix script syntax, references, or wording | Safety wording or key material exposure |
| Developer smoke | Check devnet is running, REST reachable | Check RPC/REST ports, devnet logs |
| Write-flow smoke | Check individual script logs in evidence dir | Syntax error or devnet connectivity |
| Product-flow suite | Check sub-suite evidence | Multi-agent consensus issue |

---

*End of CI checks reference.*
