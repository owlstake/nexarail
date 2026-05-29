# Public Validator Registration Gate

**Date:** 2026-05-26
**Reviewer:** Clove
**Verdict:** ✅ CONTROLLED REGISTRATION CONDITIONALLY OPEN — public permissionless testnet still blocked

## Gate Checklist

| Gate | Required | Actual | Status |
|---|---|---|---|
| Docker containers running | 3 | 3 | ✅ |
| Chain ID | nexarail-testnet-1 | nexarail-testnet-1 | ✅ |
| Block height | > 20 | 22 (max observed) | ✅ |
| Validator count | 3 | 3 | ✅ |
| Peer count | ≥ 2 | 2 (all validators) | ✅ |
| Fees params queryable | Yes | Yes (genesis) | ✅ |
| Merchant params queryable | Yes | Yes (genesis) | ✅ |
| Settlement params queryable | Yes | Yes (genesis) | ✅ |
| Escrow params queryable | Yes | Yes (genesis) | ✅ |
| Treasury params queryable | Yes | Yes (genesis) | ✅ |
| Payout params queryable | Yes | Yes (genesis) | ✅ |
| Settlement live_enabled | false | false | ✅ |
| Escrow live_enabled | false | false | ✅ |
| Treasury live_enabled | false | false | ✅ |
| Payout live_enabled | false | false | ✅ |
| Settlement treasury_routing_enabled | false | false | ✅ |
| Settlement burn_routing_enabled | false | false | ✅ |
| No panics in logs | 0 panics | 0 panics | ✅ |
| Genesis checksum recorded | Yes | Yes | ✅ |
| Build/vet/test green | Yes | ✅ (14 packages) | ✅ |
| CLI bootstrap (init, keys, gentx) | Yes | ✅ | ✅ |
| debug-p2p-config working | Yes | ✅ | ✅ |

## Controlled Registration Conditions

### Preconditions for External Validators

1. **Validator must run on Linux** (amd64 or arm64). Docker Desktop on macOS is insufficient for stable P2P consensus.
2. **Minimum 4 validators recommended** for the public testnet. A 3-validator set requires 100% uptime (any one validator offline = halt).
3. **Validator must provide:**
   - Node ID (from `nexaraild tendermint show-node-id`)
   - Validator public key
   - Self-delegation amount (min: 500,000,000 unxrl)
   - Commission rates: rate, max-rate, max-change-rate
   - Moniker (human-readable name)
   - Contact: website, email, or social handle
4. **Network access**: Validator must expose ports 26656 (P2P) and 26657 (RPC) to the network.
5. **gentx submission**: Validators submit a signed `gentx` via the registration process.

### Registration Process

```
1. Validator runs:
   nexaraild init <moniker> --chain-id nexarail-testnet-1
   
2. Configure config.toml:
   persistent_peers = "<seed-node-id>@<seed-ip>:26656"
   pex = true
   addr_book_strict = false
   
3. Add validator account to the local gentx-preparation genesis:
   nexaraild add-genesis-account <key-name-or-address> 1000000000unxrl \
     --keyring-backend test
   
4. Create gentx:
   nexaraild gentx <key-name> 500000000unxrl \
     --chain-id nexarail-testnet-1 \
     --commission-rate 0.05 \
     --commission-max-rate 0.20 \
     --commission-max-change-rate 0.01

5. Submit gentx to genesis coordinator
```

The `add-genesis-account` command is local gentx preparation only. The coordinator assembles final genesis separately from accepted gentxs.

### What "Controlled" Means

- Genesis coordinator (Bradley/Clove) reviews and approves each validator application
- Only approved validators are included in the genesis
- The testnet is NOT permissionless — validators must be whitelisted
- Validator set changes require governance on-chain

### NOT: Public Permissionless Testnet

This is NOT a public permissionless testnet. It is a **controlled registration testnet** where:
- Validator registration requires manual approval
- The genesis is curated (not auto-collected from open gentx submissions)
- Module live flags remain FALSE (no real funds flowing)

## Current Status (Updated 2026-05-26)

**Controlled validator registration is now open** (Phase 7A). See:
- `docs/testnet/CONTROLLED_VALIDATOR_REGISTRATION.md` — full registration guide
- `docs/testnet/VALIDATOR_APPLICATION_FORM.md` — application form
- `docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md` — gentx instructions
- `docs/testnet/FAQ.md` — frequently asked questions

**Public permissionless testnet remains blocked** until all items below are resolved.

## What Would Upgrade This to "Public Testnet Live"

1. Fix Docker networking stability (run on Linux hosts)
2. Register gRPC-Gateway routes for all 6 custom modules (REST API coverage)
3. End-to-end CLI query verification on stable environment
4. Explorer node deployed (separate RPC endpoint)
5. Faucet deployed (rate-limited, CAPTCHA-protected)
6. Bug bounty program announced
7. Runbook published for validators
