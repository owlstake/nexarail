# NexaRail Controlled Testnet RC1 — Release Notes

| Field | Value |
|---|---|
| **Version** | NexaRail Controlled Testnet RC1 |
| **Codename** | N/A (release candidate) |
| **Release Type** | Controlled Testnet Release Candidate |
| **Date** | 2026-05-28 |
| **Status** | ⚠️ NOT LIVE — Controlled testnet preparation only |

---

## Scope

This release is a **controlled testnet release candidate** for the NexaRail network. It is intended for internal validation, agent-driven governance rehearsals, and product-flow verification in a sandboxed environment. **No tokens of value**, **no mainnet**, and **no public network** are involved.

### What Is Included

- **Binary** — Compiled `nexad` daemon for the controlled testnet
- **Checksums** — SHA-256 checksums for binary verification
- **Documentation** — API docs, governance templates, hardening reports, known limitations
- **Scripts** — Predeployment check script, Genesis helper scripts, API smoke tests
- **Evidence** — 12-item evidence manifest (see `TESTNET_RC1_EVIDENCE_MANIFEST.md`)

### What Is Not Included

- ❌ Mainnet launch
- ❌ Token sale
- ❌ External validator set
- ❌ Final genesis transaction collection (gentx)
- ❌ Public testnet
- ❌ External security audit (pending)
- ❌ Legal review (pending)
- ❌ SLAs or mainnet guarantees
- ❌ Any token with real or implied value

---

## Technical Evidence Summary

| Category | Result |
|---|---|
| **Product-flow tests** | 487/487 passed (0 failures) — *Phase 10B final report* |
| **REST readback parity** | 36/36 endpoints operational — *REST_READBACK_ROUTES.md* |
| **Governance helpers** | 12 valid governance templates — *governance/templates/* |
| **Predeployment checks** | 23/23 passed — *predeployment-check.sh* |
| **Safety wording audit** | PASS — *PHASE_10B3_SAFETY_WORDING_AUDIT.md* |

### Product-Flow Coverage

| Flow | Status |
|---|---|
| **Settlement** | ✅ Proven |
| **Escrow** | ✅ Proven |
| **Treasury** | ✅ Proven |
| **Payout** | ✅ Proven |

Full evidence: `rehearsals/validator-agents/product-flows/evidence/`

---

## Live Flags

All live-network flags are **disabled by default** (genesis default `false`). No deployment will interact with a real economic network until these flags are explicitly enabled in a future release.

---

## External Validator Status

| Item | Status |
|---|---|
| Validator onboarding | ⏳ Pending |
| Gentx collection | ⏳ Pending |
| Final external genesis | ⏳ Pending |
| Validator distribution design | ⏳ Pending |

External validator onboarding is planned for a subsequent release phase.

---

## Known Limitations

See `TESTNET_RC1_KNOWN_LIMITATIONS.md` for the full enumeration.

High-level items:
- No mainnet exists
- No token sale has occurred
- External validators have not been onboarded
- Final external genesis not assembled (gentx collection required)
- Escrow dispute harness coverage deferred
- CLI-native product-gov commands deferred (script wrapper exists)
- External security audit and legal review pending
- REST is readback-only; tx broadcast uses generic Cosmos endpoint
- No SLAs, no mainnet guarantees, no token value

---

## Install / Build Instructions

### 1. Download the Binary

```bash
# Download nexad binary (binary URL TBD)
curl -LO https://releases.nexarail.dev/testnet/rc1/nexad
```

### 2. Verify Checksum

```bash
# Download checksums
curl -LO https://releases.nexarail.dev/testnet/rc1/nexad_SHA256SUMS

# Verify
sha256sum -c nexad_SHA256SUMS
```

### 3. Make Executable

```bash
chmod +x nexad
```

### 4. Initialize Node

```bash
./nexad init <your-moniker> --chain-id nexarail-testnet-rc1
```

### 5. Configure

Edit `~/.nexad/config/config.toml` and `~/.nexad/config/app.toml` to point to the controlled testnet seed nodes (seed node endpoints TBD).

### 6. (Optional) Run Predeployment Checks

```bash
./scripts/testnet/predeployment-check.sh
```

---

## Verification Instructions

1. **Check binary** — Run `./nexad version` and confirm the output reports testnet RC1
2. **Run API smoke test** — Use the helper script:
   ```bash
   ./scripts/testnet/api-smoke.sh
   ```
3. **Verify live flags** — Check that all live-network genesis parameters are `false`:
   ```bash
   ./nexad q genesis params | grep -i 'live\|enable\|active'
   ```
4. **Review evidence** — See `TESTNET_RC1_EVIDENCE_MANIFEST.md` for the full list of validation evidence

---

## Launch Status

🚫 **NOT LIVE.** This is a controlled testnet preparation only.

No public network, no token value, no mainnet guarantees. All live flags are disabled by default. External validator onboarding, gentx collection, security audit, and legal review remain pending.

---

*End of release notes.*
