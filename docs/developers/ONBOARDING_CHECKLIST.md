# Developer Onboarding Checklist

## Prerequisites
- [ ] macOS ARM64 or Linux AMD64
- [ ] Go 1.26+ installed
- [ ] Node.js 18+ installed (for SDK examples)
- [ ] Python 3.9+ installed (for SDK examples)
- [ ] `jq` installed
- [ ] `git` installed

## Step 1: Verify Package Integrity
- [ ] Run `bash scripts/release/verify-testnet-rc1.sh` — all 37/37 checks pass
- [ ] Run `bash scripts/dev/check-sdk-packages.sh` — all 24/24 checks pass

## Step 2: Run Fast Regression
- [ ] Run `bash scripts/dev/run-nexarail-regression-matrix.sh --fast`
- [ ] All 8 checks pass (go_mod_verify, go_build, go_test, predeployment_check, rc1_verify, dashboard_files_check, local_demo_script_check, sdk_package_check)

## Step 3: Launch Local Devnet
- [ ] Run `bash scripts/release/launch-rc1-devnet.sh --single-node --clean`
- [ ] Devnet reaches height >= 5 within 60 seconds

## Step 4: Query Devnet State
- [ ] Run `curl http://localhost:26657/status` — returns valid JSON with node info
- [ ] Run `curl http://localhost:1317/cosmos/base/tendermint/v1beta1/node_info` — REST API responds

## Step 5: Verify Live Flags
- [ ] All product module `live_enabled` fields are `false`
- [ ] Modules: settlement, escrow, payout, treasury

## Step 6: Run REST Examples
- [ ] Run `bash examples/rest/check_live_flags.sh` — shows all false
- [ ] Run `bash examples/rest/check_treasury.sh` — returns treasury summary

## Step 7: Test Node.js SDK
- [ ] `cd examples/node-client && node test/client.test.js` — all tests pass
- [ ] Node.js SDK can read treasury summary from running devnet

## Step 8: Test Python SDK
- [ ] `cd examples/python-client && python3 test_client.py` — all tests pass
- [ ] Python SDK can read treasury summary from running devnet

## Step 9: Run Write-Flow Dry Checks
- [ ] `bash -n examples/write-flows/*.sh` — all scripts pass syntax check

## Step 10: Run End-to-End Demo
- [ ] Run `bash scripts/dev/run-end-to-end-demo.sh --skip-dashboard`
- [ ] All 10 checks pass

## Step 11: Inspect Dashboard
- [ ] Open `examples/dashboard/index.html` in browser
- [ ] Dashboard loads without errors

## Step 12: Read Safety Documentation
- [ ] Read `docs/release/RC1_REVIEWER_README.md`
- [ ] Read `docs/developers/SDK_PACKAGE_PREPARATION.md`
- [ ] Understand: This is a LOCAL DEVNET ONLY — NOT MAINNET
- [ ] Understand: No token sale, no investment, no real funds
- [ ] Understand: SDKs are NOT published to npm or PyPI

## Step 12b: Developer Portal
- [ ] Run `bash scripts/dev/build-developer-portal.sh` — builds successfully
- [ ] Run `bash scripts/dev/check-developer-portal.sh` — all 6/6 checks pass
- [ ] Open portal: `site/developer-portal/index.html`

## Step 13: Submit First PR Checklist
- [ ] `go mod tidy && go mod verify && go build ./... && go vet ./... && go test ./...` — all pass
- [ ] `bash scripts/dev/check-sdk-packages.sh` — all pass
- [ ] `bash scripts/dev/run-nexarail-regression-matrix.sh --fast` — all pass
- [ ] No private keys, mnemonics, or seed phrases in commits
- [ ] No `live_enabled` default changes without explicit review
- [ ] No economic parameter changes without explicit review
- [ ] No mainnet or token-sale claims
- [ ] Safety wording audit: no promotional/false statements
