# NexaRail — CI Troubleshooting Guide

## What CI Checks

The GitHub Actions workflow (`.github/workflows/nexarail-regression.yml`) runs on every push to `main` or PR to `main`:

| Step | CI-Safe? | What It Verifies |
|---|---|---|
| go mod verify | ✅ Yes | Go module integrity |
| go build ./... | ✅ Yes | Full Go compilation (no external artifacts needed) |
| go vet ./... | ✅ Yes | Go code analysis |
| go test ./... | ✅ Yes | All unit tests |
| Predeployment check | ✅ Yes (soft-fail) | 23 code gates (passes without binaries) |
| RC1 verification | ✅ Yes (soft-fail) | 37 checks (4 binary checks skip if binaries absent) |
| Dashboard file check | ✅ Yes | 21 dashboard file assertions |
| Local demo script check | ✅ Yes | 36 demo safety checks |
| Write-flow syntax check | ✅ Yes | bash -n for all 7 write-flow scripts |
| REST syntax check | ✅ Yes | bash -n for all REST scripts |
| Node client syntax | ✅ Yes | Node.js import check |
| Python client compile | ✅ Yes | Python compile check |
| Node SDK package check | ✅ Yes | SDK imports |
| Python SDK package check | ✅ Yes | SDK compile |
| SDK package check | ✅ Yes (soft-fail) | 24 SDK checks (skips archive checks if absent) |
| SDK docs check | ✅ Yes | Required docs exist |
| Portal build | ✅ Yes | Static portal generation |
| Portal check | ✅ Yes | 6 portal checks |

## What CI Intentionally Skips

The following are intentionally not run in CI because they require:

| Check | Reason Skipped |
|---|---|
| Devnet launch | Requires RC1 binaries (not committed) |
| End-to-end demo | Requires running devnet |
| Full regression | Requires running devnet |
| Developer bundle | Requires archives (not committed) |
| SDK archive creation | Requires archives (not committed) |

## Why Binaries Are Not Committed

- RC1 binaries (`nexaraild-darwin-arm64`, `nexaraild-linux-amd64`) are ~85–92 MB each
- They are uploaded to the [GitHub Release page](https://github.com/Bookings-cpu/nexarail/releases/tag/v0.1.0-rc1)
- Reviewers download binaries from the release, verify checksums, and place in `releases/testnet-rc1/binaries/`
- Local scripts detect missing binaries and print SKIP rather than FAIL

## How to Reproduce CI Locally

```bash
# Run the exact CI-safe checks
go mod verify
go build ./...
go vet ./...
go test ./...
bash -n scripts/dev/*.sh
bash -n scripts/release/*.sh
bash -n scripts/testnet/*.sh
bash scripts/dev/check-dashboard-files.sh
bash scripts/dev/check-local-demo-script.sh
bash scripts/dev/check-sdk-packages.sh
bash scripts/dev/build-developer-portal.sh
bash scripts/dev/check-developer-portal.sh
```

## How to Interpret PASS / FAIL / SKIP

| Label | Meaning |
|---|---|
| ✅ PASS | Check passed completely |
| ❌ FAIL | Check failed — needs investigation |
| ⏭️ SKIP | Check skipped (artifact not present, e.g. binaries) |
| `requires local env` | The workflow ran a check that needs local-only resources and turned it into a non-failing step |

SKIP is expected for any check requiring:
- RC1 binaries
- Running devnet
- Generated SDK archives
- Local evidence logs

## When to Run Full Local Regression

Run the full local regression after cloning or before submitting a PR that changes chain logic:

```bash
# Fast (no devnet needed):
bash scripts/dev/run-nexarail-regression-matrix.sh --fast
# Expected: 9 PASS / 0 FAIL

# Full (requires devnet + binaries):
bash scripts/dev/run-nexarail-regression-matrix.sh --full --with-devnet

# End-to-end (requires devnet + binaries):
bash scripts/dev/run-end-to-end-demo.sh --skip-dashboard
```

## CI Workflow File

The workflow is at `.github/workflows/nexarail-regression.yml`.

Common modifications:
- To add a CI-safe check: add a new step with `run:` and no special requirements
- To make a check soft-fail: append `|| echo "requires local env -- not failing CI"`
- To skip a check entirely in CI: wrap in `if: runner.environment == 'local'` (not recommended; use soft-fail instead)
