# Reproducible Build Notes — NexaRail

**Date:** 2026-05-26

---

## Build Environment

| Parameter | Value |
|---|---|
| Go version | 1.22+ |
| Build tool | `go build` |
| Module mode | `-mod=readonly` for reproducible deps |
| CGO (Linux) | Disabled (`CGO_ENABLED=0`) |
| CGO (macOS) | Enabled (required for keychain on Darwin) |
| Linker flags | Version info via `-ldflags` |

## Deterministic Build Flags

```bash
CGO_ENABLED=0 go build -mod=readonly \
  -ldflags '-X github.com/cosmos/cosmos-sdk/version.Name=nexarail
            -X github.com/cosmos/cosmos-sdk/version.AppName=nexaraild
            -X github.com/cosmos/cosmos-sdk/version.Version=v0.1.0-testnet
            -X github.com/cosmos/cosmos-sdk/version.Commit=$(git rev-parse HEAD)' \
  -o build/nexaraild ./cmd/nexaraild
```

## Docker Build

Multi-stage Dockerfile builds natively inside the container:
```dockerfile
FROM golang:1.22-alpine AS builder
RUN CGO_ENABLED=0 go build ...
```

Docker builds are **not bit-identical** to local builds (different Go toolchain cache, OS headers) but are **functionally equivalent**.

## Native vs Docker Differences

| Factor | Native | Docker |
|---|---|---|
| Go version | Host Go | golang:1.22-alpine |
| C library | Host libc | musl (Alpine) |
| Binary size | May differ | May differ |
| Functionality | ✅ Identical | ✅ Identical |

## Checksum Verification

```bash
# Download checksums
wget https://github.com/Bookings-cpu/nexarail/releases/download/v0.1.0-testnet/SHA256SUMS

# Verify binary
sha256sum -c SHA256SUMS --ignore-missing

# Expected: nexaraild-linux-amd64: OK
```

## Known macOS Docker Caveat

Docker Desktop on macOS runs in a Linux VM. The P2P networking layer is unstable for multi-validator consensus — connection drops after ~20 blocks. **Production validators must run on native Linux hosts**, not Docker Desktop on macOS.

## Linux Recommended Path

For maximum reproducibility:
1. Ubuntu 22.04 LTS or Debian 12
2. Go 1.22+ installed via official tarball
3. Build with `CGO_ENABLED=0` for static binary
4. Verify checksum against published SHA256SUMS
