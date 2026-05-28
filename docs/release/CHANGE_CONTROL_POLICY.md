# Change Control Policy — NexaRail Testnet

**Date:** 2026-05-26
**Effective:** Immediately
**Applies to:** nexarail-testnet-1 preparation and operations

---

## Policy Statement

During controlled testnet preparation and active operations, changes to the codebase are restricted to bugfixes, test improvements, and operational enhancements. No new protocol features, no economic changes, and no live flag default changes are permitted.

## Permitted Changes

| Category | Example | Approval |
|---|---|---|
| Bugfixes | Fix crash, fix incorrect calculation | Coordinator |
| Test improvements | Add tests, improve coverage | Self-service |
| Documentation | Update docs, fix typos | Self-service |
| Script improvements | Improve build/CI scripts | Self-service |
| Config changes | Adjust testnet config params | Coordinator |
| Dependency updates | Patch security vulns in deps | Coordinator |

## Prohibited Changes

| Category | Example |
|---|---|
| New protocol features | New message types, new modules |
| Economic changes | Fee split changes, rebate tier changes |
| Live flag changes | Changing defaults from false to true |
| Bridge implementation | Any bridge/IBC code |
| Stablecoin registry | Any stablecoin code |
| Validator distribution | Any distribution implementation |
| Mainnet claims | Any docs saying mainnet is live |

## Approval Process

1. **Identify:** Issue filed on GitHub with description
2. **Assess:** Coordinator reviews against policy
3. **Implement:** Developer creates PR
4. **Test:** All tests must pass (`go test ./...`)
5. **Review:** Coordinator reviews PR
6. **Merge:** PR merged to main
7. **Verify:** `go test ./...` passes on main

## Test Requirements

All changes must pass:
- `go build ./...`
- `go vet ./...`
- `go test ./... -count=1`
- Relevant module tests if code changes
- No regression in existing test count

## Documentation Requirements

| Change Type | Doc Requirement |
|---|---|
| Bugfix | Update CHANGELOG.md |
| New test | None beyond test code |
| Config change | Update RUNTIME_CONFIG_HARDENING.md |
| Dependency update | Update go.mod, verify license compatibility |
| Script change | Update relevant docs/testnet/ docs |

## Emergency Fixes

For critical bugs discovered during testnet operations:

1. Coordinator declares emergency
2. Fix implemented on branch
3. All tests pass
4. Coordinator approves
5. New binary released with hotfix tag (e.g., v0.1.1-testnet)
6. Validators notified via communication channel
7. Coordinated upgrade

Emergency fixes bypass normal review cadence but must still pass all tests.

## Rollback Policy

If a change introduces a regression:

1. Revert the commit on main
2. All tests must pass on reverted code
3. New release tag if binary was released
4. Validators notified

## Versioning

| Change Type | Version Bump |
|---|---|
| Bugfix | Patch (v0.1.0 → v0.1.1) |
| New test-only changes | No version bump |
| Config/script changes | No version bump |
| Feature addition | Minor (not permitted during launch prep) |

## Current Status

| Policy | Status |
|---|---|
| Code freeze | ✅ Active |
| Last protocol change | Phase 8A (REST gateway — infrastructure, not protocol) |
| Open changes | None |
| Open issues | None |
