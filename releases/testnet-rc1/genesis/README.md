# NexaRail Controlled Testnet RC1 — Genesis Placeholder

**Status:** NOT ASSEMBLED — Placeholder only.

## Current State

- External validator onboarding is **pending**.
- External gentx collection has **not begun**.
- Final testnet genesis has **not been assembled**.

## Requirements

When external validators are onboarded and gentxs collected:

1. Collect all external gentx files.
2. Validate each gentx using `scripts/testnet/verify-submitted-gentx.sh`.
3. Assemble the genesis candidate using `scripts/testnet/assemble-testnet-genesis.sh`.
4. Verify genesis integrity with `scripts/testnet/check-final-genesis.sh`.
5. Generate genesis SHA256 checksum.
6. Publish checksum for validator verification.

## Important

- **Live flags must remain false** in genesis. See `docs/hardening/PHASE_10B_PRODUCT_FLOW_READINESS_FINAL.md` for current defaults.
- The genesis checksum will be generated **after** the validator set is finalised.
- No genesis file has been placed in this directory yet.
