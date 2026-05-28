# NexaRail Local Demo Guide

**LOCAL DEVNET ONLY — NOT MAINNET — NO TOKEN SALE**

## Purpose

The local demo lets a reviewer go from repo clone to verified devnet in a single command:

```bash
scripts/dev/run-local-demo.sh --serve-dashboard --keep-running
```

This proves:
1. The RC1 binary builds and is checksum-verified
2. A single-node devnet starts and produces blocks
3. All 6 live flags are disabled by default
4. REST readback endpoints respond correctly
5. Developer examples (Node + Python clients) work
6. Write-flow examples are syntax-clean in dry-run mode
7. Dashboard files are complete and safety-compliant
8. No private keys or signing code in example files

## What It Does Not Prove

- It does not prove public testnet readiness (external validators needed)
- It does not prove mainnet readiness (does not exist)
- It does not prove production security (devnet only, test keys)
- It does not execute write flows (dry-run only)
- It does not demonstrate 5-agent consensus (use the full product-flow suite for that)

## Prerequisites

- macOS ARM64 or Linux AMD64
- Go 1.26+ (for building) or just download the RC1 binary

## Quick Start

```bash
# Clone the repository
git clone <repo-url> nexarail
cd nexarail

# Run the full local demo
scripts/dev/run-local-demo.sh --serve-dashboard --keep-running
```

## Expected Output

The demo will:

1. **Verify RC1 package** — checks `releases/testnet-rc1/manifests/manifest.json`
2. **Verify binary checksum** — SHA256 matches `releases/testnet-rc1/checksums/SHA256SUMS`
3. **Launch single-node devnet** — chain `nexarail-devnet-1`, waits for height >= 10
4. **Query live flags** — verifies all 6 flags are `false`
5. **Run developer examples** — tests Node.js + Python clients against the live devnet
6. **Run write-flow dry-run** — verifies all 7 write-flow scripts are syntax-clean
7. **Run dashboard file check** — verifies 21 safety/completeness checks
8. **Serve dashboard** (if `--serve-dashboard`) — opens at `http://localhost:8088`
9. **Save evidence** — to `rehearsals/local-demo/evidence/<timestamp>/`

## Dashboard URL

With `--serve-dashboard`:

```
http://localhost:8088
```

The dashboard shows:
- Node status (height, chain ID, validators)
- Live flags (all green if false)
- Module parameters for all 6 modules
- Treasury summary
- List views for merchants, settlements, escrows, payouts

## Script Options

| Flag | Description |
|---|---|
| `--keep-running` | Leave devnet running after demo completes |
| `--serve-dashboard` | Serve the local dashboard on port 8088 |
| `--skip-smoke` | Skip developer/write-flow smoke tests (faster) |
| `--binary <path>` | Override the nexaraild binary path |
| `--evidence-dir <path>` | Override evidence output directory |

## Example: Quick Smoke Only

```bash
scripts/dev/run-local-demo.sh --skip-smoke
```

This runs in ~30 seconds: verify → launch → check flags → stop.

## Example: Full Demo with Dashboard

```bash
scripts/dev/run-local-demo.sh --serve-dashboard --keep-running
```

Leave running for interactive exploration. Stop with:

```bash
scripts/release/stop-rc1-devnet.sh
```

## Evidence Output

Each demo run creates an evidence directory:

```
rehearsals/local-demo/evidence/<timestamp>/
├── summary.json          # Machine-readable results
├── summary.md            # Human-readable results
├── devnet-status.json    # Node status snapshot
├── live-flags.json       # All 4 module live flags
├── smoke-results.txt     # Developer examples output
├── write-flow-smoke.txt  # Write-flow dry-run output
├── dashboard-check.txt   # Dashboard file check output
└── logs/
    ├── devnet-launch.log
    ├── dashboard-serve.log
    └── stop-devnet.log
```

## Troubleshooting

| Issue | Likely Cause | Fix |
|---|---|---|
| "Binary not found" | RC1 binary not built | Run `go build -o releases/testnet-rc1/binaries/nexaraild-darwin-arm64 ./cmd/nexaraild` |
| "Devnet launch failed" | Port 26657 in use | `lsof -ti:26657 \| xargs kill` |
| "REST not reachable" | Devnet not fully started | Wait 10s, check `scripts/release/stop-rc1-devnet.sh && scripts/release/launch-rc1-devnet.sh --single-node --clean` |
| "Checksum mismatch" | Binary rebuilt or corrupted | Rebuild with `go build -o $BINARY ./cmd/nexaraild` then re-run checksum |
| Dashboard blank | CORS issue | Open dev tools console; use `http://localhost:1317` as API URL |

## Related Resources

- [Developer Quickstart](DEVELOPER_QUICKSTART.md)
- [API Examples](API_EXAMPLES.md)
- [RC1 Release Notes](../release/TESTNET_RC1_RELEASE_NOTES.md)
- [RC1 Devnet Launch Guide](../release/TESTNET_RC1_DEVNET_LAUNCH_GUIDE.md)

---

**⚠️ SAFETY:** This demo runs entirely locally. No data leaves your machine.
No token sale. No monetary value. Not mainnet. Not a public testnet.
