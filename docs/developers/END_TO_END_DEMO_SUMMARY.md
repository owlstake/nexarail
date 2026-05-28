# End-to-End Developer Demo — Summary

## Quick Run
```bash
# Full demo (launches devnet, runs all checks, stops):
scripts/dev/run-end-to-end-demo.sh

# With dashboard:
scripts/dev/run-end-to-end-demo.sh --serve-dashboard

# Keep devnet running after demo:
scripts/dev/run-end-to-end-demo.sh --keep-running
```

## What Passes
| Check | Expected |
|---|---|
| RC1 verification | 37/37 pass |
| Devnet launch | Clean, no errors |
| Height >= 5 | Yes |
| Live flags all false | 7/7 false |
| REST examples | 36/36 respond |
| Node.js SDK | Reads treasury, merchants |
| Python SDK | Reads treasury, merchants |
| Write-flow dry-runs | Build commands only |
| SDK command builders | Return strings |
| Dashboard check | 21/21 pass |

## Evidence Path
```
rehearsals/end-to-end-demo/evidence/<timestamp>/
```

## Limitations
- Devnet only — not mainnet or public testnet
- No TX execution against live chain
- No wallet or private key handling
- Requires local Node.js/Python install for SDK checks

## Safety
```
╔══════════════════════════════════════════════════════════════════╗
║  LOCAL DEVNET ONLY — NOT MAINNET                               ║
╚══════════════════════════════════════════════════════════════════╝
```
