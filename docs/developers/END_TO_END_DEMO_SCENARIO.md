# End-to-End Developer Demo Scenario

## Purpose
Demonstrate the complete NexaRail local developer workflow:
1. Launch a local devnet
2. Verify on-chain state
3. Query via REST API
4. Query via Node.js SDK
5. Query via Python SDK
6. Build but not execute write-flow commands
7. Serve the local dashboard
8. Inspect live flags
9. Collect evidence
10. Clean up

## Prerequisites
- macOS ARM64 (Linux AMD64 compatible with flag adjustment)
- NexaRail RC1 package unpacked at `releases/testnet-rc1/`
- Node.js 18+ (for Node SDK examples)
- Python 3.9+ (for Python SDK examples)
- `jq` (for JSON parsing)
- `go` 1.26+ (for building chain binary if not using prebuilt)

## One-Command Path
```bash
scripts/dev/run-end-to-end-demo.sh
```

This launches, runs all checks, collects evidence, and stops the devnet.

## Manual Path
Follow the steps in order:
1. `scripts/release/launch-rc1-devnet.sh --single-node --clean`
2. Wait for height >= 5
3. `examples/rest/check_live_flags.sh`
4. (Node SDK) `cd examples/node-client && node -e "import('./src/client.js').then(c => c.treasurySummary()).then(r => console.log(JSON.stringify(r, null, 2)))"`
5. (Python SDK) `cd examples/python-client && python3 -c "import nexarail_client as n; print(n.treasury_summary())"`
6. `examples/write-flow/merchant-register.sh --dry-run`
7. Open `examples/dashboard/index.html` in browser
8. `scripts/release/launch-rc1-devnet.sh --stop`

## Expected Duration
- First run (build + launch + all checks): ~5-8 minutes
- Subsequent runs (devnet cached): ~3-5 minutes
- Fast mode (skip SDK, skip dashboard): ~2-3 minutes

## What Is Demonstrated
- RC1 package integrity
- Clean devnet launch with no errors
- Node reaches height
- All 7 product modules report `live_enabled: false`
- All 36 REST endpoints respond
- Node.js SDK reads treasury summary
- Python SDK reads treasury summary
- Write-flow commands build correctly (--dry-run)
- SDK command builders produce valid CLI strings
- Dashboard files are complete

## What Is NOT Demonstrated
- Mainnet or public testnet operation
- Token sale or token transfer
- Private key handling or signing
- TX execution against a live chain
- Cross-validator consensus
- Wallet integration

## Evidence Output
All output saved to:
```
rehearsals/end-to-end-demo/evidence/<timestamp>/
├── summary.json
├── summary.md
├── rc1-verify.txt
├── devnet-launch.txt
├── status.json
├── live-flags.json
├── rest-examples.txt
├── node-sdk.txt
├── python-sdk.txt
├── write-flow-dry-run.txt
├── sdk-command-builders.txt
├── dashboard-check.txt
└── logs/
```

## Cleanup
- `--keep-running` flag: leaves devnet running for exploration
- Default: stops devnet and removes temp processes
- Manual: `scripts/release/launch-rc1-devnet.sh --stop`

## Safety Disclaimer
```
╔══════════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                               ║
║  This demo runs a controlled local testnet with zero-value      ║
║  test tokens. No real funds, no token sale, no investment.      ║
║  Do not use with any production network.                        ║
╚══════════════════════════════════════════════════════════════════╝
```
