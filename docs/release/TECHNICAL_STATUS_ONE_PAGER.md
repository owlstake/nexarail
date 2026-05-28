# NexaRail RC1 — Technical Status One-Pager

## Architecture
- Cosmos SDK v0.47.x
- CometBFT consensus (single-node devnet)
- 7 custom modules + auth/bank/staking/gov
- REST API gateway on port 1317
- RPC on port 26657

## Modules
| Module | Purpose | live_enabled |
|---|---|---|
| settlement | Record payment metadata | false |
| escrow | Escrow lifecycle management | false |
| merchant | Merchant profile registry | false |
| payout | Payout processing | false |
| treasury | Treasury account management | false |
| fees | Protocol fee distribution | false |
| governance | Product toggle proposals | — |

## RC1 Status
- Build: Go 1.26+, Darwin ARM64 + Linux AMD64
- Binary SHA256: Verified
- Genesis: Preconfigured for single-node
- Denom: unxrl (test token, zero monetary value)
- Voting period: 30 seconds (devnet)
- All live flags: false

## Product-Flow Evidence
- Full product-flow suite: 487 pass / 0 fail
- Semantic assertions: 36 pass / 0 fail
- Governance proposals: 22 executed
- Burn supply delta: -2000 unxrl verified
- Event evidence: Collected and indexed

## Developer Tooling
- Node.js SDK: 18 functions (8 read, 10 command builders)
- Python SDK: 18 functions (8 read, 10 command builders)
- REST examples: 7 scripts covering 36 endpoints
- Write-flow examples: 7 dry-run-safe scripts
- Static dashboard: HTML/JS/CSS, read-only
- Developer portal: 19-section static site

## Regression Status
- Fast regression: 9/9 pass
- SDK package check: 24/24 pass
- Portal check: 6/6 pass
- Dashboard check: 21/21 pass
- Local demo script check: 36/36 pass
- Predeployment code gates: 23/23 pass
- RC1 verification: 37/37 pass

## Remaining NO-GO Items
- Public testnet launch
- Mainnet launch
- External validator activation
- SDK publishing (npm/PyPI)
- Token economics at production scale
- Wallet/private-key integration
