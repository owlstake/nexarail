# Linux Hardening Execution Guide — NexaRail

**Date:** 2026-05-26

---

## Why Linux

Docker Desktop on macOS has known P2P networking instability for multi-node CometBFT consensus. Validator nodes drop connections after ~20 blocks. All validator operations and final hardening should be executed on native Linux.

## Required Environment

| Component | Requirement |
|---|---|
| Distro | Ubuntu 22.04+ or Debian 12+ |
| CPU | 4+ vCPU (8+ recommended) |
| RAM | 8+ GB (16+ recommended) |
| Disk | 100+ GB SSD |
| Docker | 24+ with Compose plugin |
| Go | 1.22+ |
| Tools | `git`, `make`, `jq`, `python3`, `curl`, `grpcurl` (optional) |

## Docker Rehearsal

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail

# Build
make build

# Run 3-validator Docker rehearsal
./scripts/testnet/run-docker-3-validator-rehearsal.sh

# Query validators
./scripts/testnet/query-docker-3-validator-rehearsal.sh

# Collect evidence
./scripts/testnet/collect-docker-rehearsal-evidence.sh

# Stop
./scripts/testnet/stop-docker-3-validator-rehearsal.sh
```

Expected: 3 validators producing blocks, height >20, peers ≥2, chain ID `nexarail-testnet-1`.

## Native Build (Alternative to Docker)

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail

go mod tidy && go mod verify
make build
./build/nexaraild version
```

## Run Hardening Suite

```bash
# Full hardening suite
./scripts/testnet/run-hardening-suite.sh

# Stress tests only
./scripts/testnet/run-stress-tests.sh

# Pre-deployment check
./scripts/testnet/predeployment-check.sh

# CLI E2E smoke (requires running node)
./scripts/testnet/cli-e2e-smoke-test.sh

# API smoke (requires running node with REST enabled)
./scripts/testnet/api-smoke-test.sh
```

## Restart Safety Rehearsal

Phase 9V fixed the local agent reuse-data restart path on macOS. Before external validator launch, repeat the restart matrix or an equivalent supervised-node restart rehearsal on Linux.

```bash
# Local-agent restart matrix
./scripts/testnet/restart-agent-matrix.sh --include-long-soak

# Minimum direct-node proof if the full matrix is too expensive
./scripts/testnet/spawn-validator-agents.sh --clean --agent-count 5
./scripts/testnet/stop-validator-agents.sh
./scripts/testnet/spawn-validator-agents.sh --reuse-data --agent-count 5
./scripts/testnet/query-validator-agents.sh
```

Expected: block production resumes after restart, full query readback passes, validator set remains stable, and no `PrepareProposal` or `ProcessProposal` panics are present in logs.

## Expected Results

| Suite | Expected |
|---|---|
| `go test ./...` | All 15 packages pass (~497 tests) |
| `run-stress-tests.sh` | Invariants, fuzz, random, failure all pass |
| `predeployment-check.sh` | 23/23 gates pass |
| `run-hardening-suite.sh` | All stages pass (smoke may skip if no node) |
| Docker rehearsal | 3 validators, height >20, peers ≥2 |
| Restart matrix | Block production resumes after clean stop/restart; no proposal panics |

## Known macOS Docker Caveat

If running on macOS Docker Desktop and validators crash ~height 22:
- This is expected — macOS Docker networking is unstable for P2P
- Solution: run on native Linux or cloud VPS
- Evidence from macOS is valid for proving binary correctness, not for P2P stability

## Collecting Linux Evidence

After running all suites on Linux:
```bash
mkdir -p evidence/$(date -u +%Y%m%dT%H%M%SZ)
./scripts/testnet/collect-docker-rehearsal-evidence.sh
cp -r rehearsals/testnet-1/docker/evidence/* evidence/
```
