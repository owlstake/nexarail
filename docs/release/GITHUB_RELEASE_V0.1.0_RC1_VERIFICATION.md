# NexaRail v0.1.0-rc1 — GitHub Release Verification

## Release URL
https://github.com/Bookings-cpu/nexarail/releases/tag/v0.1.0-rc1

## Tag
`v0.1.0-rc1` → commit `b6737e5e562a5d52cf1e07d6879ff0718d538b9c`

## Title
NexaRail v0.1.0-rc1 — Controlled Testnet Release Candidate

## Release Assets
| Asset | Size | Verified |
|---|---|---|
| `nexaraild-darwin-arm64` | 89,425,506 bytes | ✅ SHA256 matches |
| `nexaraild-linux-amd64` | 92,130,914 bytes | ✅ SHA256 matches |
| `SHA256SUMS` | 237 bytes | ✅ Downloaded |
| `manifest.json` | 410 bytes | ✅ Downloaded |
| `manifest-20260528T130040Z.json` | 420 bytes | Downloaded |
| `manifest-20260528T130048Z.json` | 420 bytes | Downloaded |
| `GITHUB_RELEASE_V0.1.0_RC1.md` | 2,195 bytes | Downloaded |

## Checksum Verification
```
nexaraild-darwin-arm64: 56f83f3068bb3d9cfe6854656e1f6b819c35cc138b96a5ebe757769a466bdc6a ✅
nexaraild-linux-amd64:  25efa8d47f9d141669f4fcc5a6026ec12102f61ee026a3a52b3c0a44984b8c6f ✅
```

## Binary Version
```
ABCI: 1.0.0
BlockProtocol: 11
P2PProtocol: 8
Tendermint: 0.37.16
```

## Binary Help
`./nexaraild-darwin-arm64 --help` runs successfully and displays NexaRail usage information.

## Safety Wording in Release Body
- ✅ "not a mainnet release"
- ✅ "not a public testnet launch"
- ✅ "No monetary value"
- ✅ "no token sale"
- ✅ `live_enabled` references present

## Verification Method
Assets were downloaded from the GitHub Release page, checksums computed locally with `shasum -a 256`, and compared against the published `SHA256SUMS`. Both binaries matched. The macOS ARM64 binary was executed with `version` and `--help` to confirm it is a valid executable.

## Date
2026-05-28

## Verdict
✅ Release v0.1.0-rc1 is published, assets are valid, checksums match, and binaries execute correctly. Reviewers can clone the repo, download assets from the release page, verify checksums, and run the local devnet.