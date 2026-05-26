# NexaRail Public Validator Registration Plan

**Document:** docs/testnet/PUBLIC_VALIDATOR_REGISTRATION_PLAN.md
**Date:** 2026-05-25
**Status:** 🔴 BLOCKED — awaiting Docker evidence

## Preconditions (All Must Be Met)

- [ ] Docker 3-validator rehearsal produces blocks (height > 20)
- [ ] Evidence reviewed and accepted (Phase 6L)
- [ ] All code gates green (build, vet, test)
- [ ] All live flags default false confirmed at runtime
- [ ] Unsafe wording audit clean

## Registration Process (After Unblock)

### Phase 1: Announcement (72 hours before window opens)

1. Post to Discord `#testnet-announcements`
2. Publish genesis template + checksum
3. Open GitHub issue: "Testnet Validator Registration"
4. Provide validator onboarding docs

### Phase 2: Registration Window (48 hours)

1. Validators submit gentx via GitHub PR
2. Core team validates each gentx
3. Faucet funds validator addresses
4. Minimum gentx: 1,000,000 unxrl self-bond
5. Target: 5-15 validators

### Phase 3: Genesis Finalisation (24 hours)

1. Collect all valid gentx
2. Generate final genesis
3. Publish genesis + checksum
4. Coordinate launch time (T-0)

### Phase 4: Launch

1. All validators start simultaneously
2. Core team monitors block production
3. Faucet activated
4. Explorer live
5. RPC/REST/gRPC endpoints live

### Phase 5: Progressive Testing

1. Governance proposals to enable live flags (one at a time)
2. Live fund flow testing (escrow, treasury, payout, settlement)
3. Parameter change testing
4. Bug reporting and triage

## Communication Channels

- Discord: `#testnet-validators` (private), `#testnet-general` (public)
- GitHub Issues: bug reports, gentx submissions
- Explorer: TBD
- RPC: TBD

## Post-Registration Governance

Once validators are active:

```bash
# Enable settlement merchant transfers
nexaraild tx settlement update-params --live-enabled true --from validator

# Enable escrow custody
nexaraild tx escrow update-params --live-enabled true --from validator

# Enable treasury spend execution
nexaraild tx treasury update-params --live-enabled true --from validator

# Enable payout execution
nexaraild tx payout update-params --live-enabled true --from validator

# Enable settlement treasury routing
nexaraild tx settlement update-params --treasury-routing-enabled true --from validator

# Enable settlement burn routing
nexaraild tx settlement update-params --burn-routing-enabled true --from validator
```

Each enablement should be a separate governance proposal with a voting period.

## Rollback Plan

If critical bugs are discovered:
1. Disable the affected live flag
2. Fix the bug
3. Re-enable the flag
4. If state is corrupted, announce testnet reset

## ⚠️ Disclaimers for Public Communication

- This is a TESTNET. Tokens have ZERO monetary value.
- No mainnet exists. No mainnet timeline is promised.
- No token sale has occurred or is planned.
- Testnet may be reset at any time.
- Participation is for technical testing only.
- No investment returns are promised.
