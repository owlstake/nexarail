---
name: Pull Request
about: Submit changes to the NexaRail project
title: ''
labels: ''
assignees: ''
---

## Description

<!-- Describe the changes in this PR -->

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Developer tooling
- [ ] SDK change (Node.js or Python)
- [ ] CI / Workflow change
- [ ] Example addition

## Checklist

### Code Quality
- [ ] `go mod tidy && go mod verify && go build ./... && go vet ./... && go test ./...` — all pass
- [ ] New Go code has proper documentation comments
- [ ] New bash scripts pass `bash -n` syntax check
- [ ] Bash scripts use Bash 3.2 compatible syntax (no `&>>`, no `[[ ]]`)
- [ ] Node.js SDK changes: tests pass (`node test/client.test.js`)
- [ ] Python SDK changes: tests pass (`python3 test_client.py`)

### SDK Safety
- [ ] SDK command builders return strings only (no command execution)
- [ ] No private key, mnemonic, or seed phrase handling in SDK clients
- [ ] No wallet integration in SDK clients

### Documentation
- [ ] README updated if changing developer workflow
- [ ] Docs in `docs/developers/` updated if changing SDK or examples
- [ ] API references updated if adding/modifying SDK functions

### Safety Wording
- [ ] No claim that mainnet is live
- [ ] No claim that NXRL is buyable or tradeable
- [ ] No investment, returns, profit, or APY language
- [ ] No claim of external decentralisation or independent validators
- [ ] No token sale claims
- [ ] No npm/PyPI publishing instructions

### Feature Safety
- [ ] No changes to `live_enabled` defaults without explicit review
- [ ] No economic parameter changes without explicit review
- [ ] No new product modules without explicit review
- [ ] No wallet or private-key handling additions

### Testing
- [ ] `bash scripts/dev/check-sdk-packages.sh` — all pass
- [ ] `bash scripts/dev/run-nexarail-regression-matrix.sh --fast` — all pass
- [ ] End-to-end demo passes (if devnet-related changes)
