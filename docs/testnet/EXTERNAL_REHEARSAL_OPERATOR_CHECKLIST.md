# NexaRail External Rehearsal Operator Checklist

**Document:** docs/testnet/EXTERNAL_REHEARSAL_OPERATOR_CHECKLIST.md
**Date:** 2026-05-25

## For the Person Running the Docker Rehearsal

### 1. Clone and Checkout

```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git log --oneline -1   # Record this commit
```

### 2. Build

```bash
make build
# Binary: build/nexaraild
```

### 3. Verify Code

```bash
go test ./...    # All 14 packages must pass
go vet ./...     # No warnings
```

### 4. Prepare Docker Genesis

```bash
./scripts/testnet/prepare-docker-3-validator-rehearsal.sh
# Must show: gen_txs: 3
```

### 5. Run Rehearsal

```bash
./scripts/testnet/run-docker-3-validator-rehearsal.sh
# Wait for: 🚀 3 VALIDATORS PRODUCING BLOCKS!
```

### 6. Query

```bash
./scripts/testnet/query-docker-3-validator-rehearsal.sh
# Verify: chain=nexarail-testnet-1, height > 5, peers ≥ 2
```

### 7. Collect Evidence

```bash
./scripts/testnet/collect-docker-rehearsal-evidence.sh
# Output: rehearsals/testnet-1/docker/evidence/<timestamp>/
```

### 8. Attach Evidence

Zip the evidence directory and attach to the Phase 6K gate review:
```bash
tar -czf nexarail-rehearsal-evidence.tar.gz rehearsals/testnet-1/docker/evidence/
```

### 9. Report Errors

If any step fails:
- Capture the exact error message
- Capture logs: `./scripts/testnet/logs-docker-3-validator-rehearsal.sh`
- Open a GitHub issue with the evidence
- Do NOT proceed to public registration

### ⚠️ Important Warnings

- **Do NOT publish as public testnet.** This is a local Docker rehearsal only.
- **Do NOT invite external validators yet.** Wait for gate review.
- **Do NOT make mainnet claims.** Tokens have zero value.
- **Do NOT send tokens to anyone.** Testnet-only, zero-value tokens.
- **Do NOT modify genesis or live flags.** Keep all defaults.

### 10. Stop

```bash
./scripts/testnet/stop-docker-3-validator-rehearsal.sh
```
