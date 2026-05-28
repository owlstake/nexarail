# Contributing to NexaRail

## Project Status

NexaRail is in **controlled local development**. The chain is not live on any public network. All development targets `nexarail-devnet-1`, a local single-node testnet for developer and reviewer evaluation.

- NO mainnet
- NO public testnet
- NO token sale
- NO investment product
- NO published SDK packages (npm / PyPI)

## Branch & PR Workflow

1. Fork or branch from `main`
2. Make changes in a feature branch: `feat/description`, `fix/description`, `docs/description`
3. Run all checks before opening a PR (see Testing Requirements)
4. Open a PR against `main`
5. PR must pass CI checks (regression matrix fast mode)
6. PR must have at least one review

## Coding Standards

### Go
- Match existing code style (Cosmos SDK conventions)
- All exported types and functions must have Go doc comments
- No `panic()` in non-init code paths
- Run `go vet ./...` and `go test ./...` before committing

### Bash Scripts
- Start with `#!/usr/bin/env bash`
- Use `set -Eeuo pipefail` for production scripts
- Use `set -euo pipefail` for simple scripts
- Bash 3.2 compatible syntax (no `&>>`, no `[[ ]]`, no `${var^^}`)
- All scripts must pass `bash -n` syntax check

### Node.js
- CommonJS or ES modules as appropriate
- Command builders must NOT execute commands (return strings only)
- All exposed functions must have JSDoc comments

### Python
- Compatible with Python 3.9+
- Standard library only (no external dependencies for SDK client)
- Command builders must NOT execute commands (return strings only)
- All functions must have docstrings

## Documentation Standards

- All new features must be documented before PR
- Developer documentation goes in `docs/developers/`
- API documentation uses Markdown tables for parameters
- Safety warnings must be present on any file describing local devnet use
- Screenshots: use PNG, place in `docs/assets/`

## Safety Wording Standards

- NEVER claim mainnet is live
- NEVER claim NXRL is buyable or tradeable
- NEVER claim a token sale exists or existed
- NEVER use investment language (guaranteed returns, profit, APY, etc.)
- NEVER claim external validators or external decentralisation
- References to "private key" must be safety warnings only
- References to "mnemonic" or "seed phrase" must be safety warnings or scanner patterns

## Testing Requirements

Before submitting a PR, run:

```bash
# Go chain
go mod tidy && go mod verify && go build ./... && go vet ./... && go test ./...

# SDK packages
bash scripts/dev/check-sdk-packages.sh

# Fast regression
bash scripts/dev/run-nexarail-regression-matrix.sh --fast

# End-to-end (if devnet available)
bash scripts/dev/run-end-to-end-demo.sh --skip-dashboard
```

## Adding Examples

Examples in `examples/` must:
- Be runnable independently (standalone scripts where possible)
- Include a safety disclaimer banner
- Not hardcode private keys or mnemonics
- Use `--dry-run` or equivalent for write-flow examples
- Be documented in the developer quickstart

## Prohibited Changes

The following require explicit project lead review:
- Changing `live_enabled` defaults to `true` in any module
- Changing economic parameters (fees, rates, supplies)
- Adding new product modules
- Adding wallet or private-key handling to SDK clients
- Publishing SDK packages to npm, PyPI, or any registry
- Making claims about external validators, mainnet readiness, or token value

## Questions

Open an issue with the label `question` or reach out to the project coordinator.
