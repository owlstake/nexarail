# Release Process Runbook — NexaRail Testnet

**Date:** 2026-05-26
**Phase:** 8F

---

## Branch Freeze

Before any testnet release:
1. No new feature PRs merged
2. Bugfix-only merges permitted
3. Coordinator declares freeze in communication channel
4. All tests must pass on main branch

## Version Naming

```
v<major>.<minor>.<patch>-testnet

Examples:
  v0.1.0-testnet  — Initial controlled testnet release
  v0.1.1-testnet  — Bugfix release
  v0.2.0-testnet  — Feature release with upgrade
```

## Tag Process

```bash
# 1. Ensure all tests pass
go test ./... -count=1

# 2. Create annotated tag
git tag -a v0.1.0-testnet -m "NexaRail v0.1.0 — Controlled Testnet Release"

# 3. Push tag
git push origin v0.1.0-testnet

# 4. Create GitHub Release from tag
gh release create v0.1.0-testnet \
  --title "NexaRail v0.1.0 — Controlled Testnet Release" \
  --notes-file CHANGELOG.md \
  build/nexaraild-linux-amd64 \
  build/nexaraild-linux-arm64 \
  build/SHA256SUMS
```

## Changelog Process

```bash
# Generate from commits since last tag
git log --oneline v0.0.0-testnet..HEAD > CHANGELOG.txt

# Format into CHANGELOG.md sections:
# - Bugfixes
# - Improvements
# - Documentation
# - Dependencies
```

## Build Matrix

| OS | Arch | Binary Name |
|---|---|---|
| Linux | amd64 | nexaraild-linux-amd64 |
| Linux | arm64 | nexaraild-linux-arm64 |
| macOS | arm64 | nexaraild-darwin-arm64 |

```bash
# Build all targets
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o build/nexaraild-linux-amd64 ./cmd/nexaraild
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o build/nexaraild-linux-arm64 ./cmd/nexaraild
GOOS=darwin GOARCH=arm64 go build -o build/nexaraild-darwin-arm64 ./cmd/nexaraild
```

## Checksums

```bash
cd build/
sha256sum nexaraild-* > SHA256SUMS
cat SHA256SUMS
```

## Validator Notification

After release:
1. Post in communication channel with release link
2. Include: version, checksums, upgrade instructions
3. If upgrade: specify upgrade height and handler name
4. If fresh genesis: provide genesis file and checksum
5. Request validators confirm upgrade within 48h

## Rollback Procedure

If release contains a critical bug:

1. Coordinator declares rollback
2. Validators stop nodes
3. If fresh genesis: restore previous genesis, wipe data, restart
4. If state-compatible: revert to previous binary, restart
5. Tag the broken release with deprecation note
6. File incident report

## Emergency Release Process

For critical security fixes:
1. Fix implemented on dedicated branch
2. All tests pass
3. Coordinator reviews and approves
4. Emergency tag created (e.g., v0.1.1-testnet-emergency)
5. Validators notified immediately
6. Coordinated upgrade if state-breaking
7. Incident report filed
