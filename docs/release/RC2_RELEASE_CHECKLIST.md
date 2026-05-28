# RC2 Release Checklist

Target version: `v0.1.1-rc2`

Do not create the tag until RC2 readiness returns `RC2_GO`.

## Pre-Tag Evidence

- [ ] Canonical one-hour five-agent soak rerun complete
- [ ] Targeted governance/product-flow replay complete with no failed txs
- [ ] Fast regression passes
- [ ] Predeployment check passes
- [ ] RC1 verification still passes for existing assets
- [ ] Product-flow harness self-test passes
- [ ] Safety wording audit passes
- [ ] `scripts/release/check-rc2-readiness.sh` returns `RC2_GO`

## Version and Docs

- [ ] Update version labels to `v0.1.1-rc2` where release-specific
- [ ] Update `README.md` only with safe RC2 status wording
- [ ] Update reviewer handoff
- [ ] Update known limitations
- [ ] Update technical status one-pager
- [ ] Update evidence manifest/index docs
- [ ] Finalize GitHub release notes from `docs/release/GITHUB_RELEASE_V0.1.1_RC2_DRAFT.md`

## Build Assets

- [ ] Rebuild Darwin ARM64 binary
- [ ] Rebuild Linux AMD64 binary
- [ ] Regenerate `SHA256SUMS`
- [ ] Generate release manifest
- [ ] Place assets under `releases/github/v0.1.1-rc2/`
- [ ] Verify local checksums

## Verification

- [ ] `go mod tidy`
- [ ] `go mod verify`
- [ ] `go build ./...`
- [ ] `go vet ./...`
- [ ] `go test ./...`
- [ ] `scripts/testnet/predeployment-check.sh`
- [ ] `scripts/dev/run-nexarail-regression-matrix.sh --fast`
- [ ] `scripts/release/verify-testnet-rc1.sh`
- [ ] RC2 asset verification script, if created
- [ ] Downloaded-asset checksum verification after upload

## Git and Release

- [ ] Confirm `git status --short` has only intended release files
- [ ] Commit final RC2 release prep
- [ ] Create annotated tag `v0.1.1-rc2`
- [ ] Push commit
- [ ] Push tag
- [ ] Prepare GitHub release assets
- [ ] Upload binaries and checksums
- [ ] Verify release page downloads

## Safety Constraints

- [ ] No mainnet claim
- [ ] No public testnet claim
- [ ] No token-buyability claim
- [ ] No production throughput claim
- [ ] No external validator/decentralisation claim
- [ ] No npm/PyPI publishing claim
- [ ] Live flags remain false by default
