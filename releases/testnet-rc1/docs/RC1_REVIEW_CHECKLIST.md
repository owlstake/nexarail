# NexaRail RC1 — Review Checklist

Use this checklist to systematically verify the RC1 release package.

---

## Basic Verification

- [ ] Binary SHA256 checksums match SHA256SUMS file
- [ ] No private key files in release package
- [ ] Genesis is placeholder (not assembled)
- [ ] Litepaper read and understood

## Devnet Runtime

- [ ] Single-node devnet starts without errors
- [ ] Blocks are produced (height > 0)
- [ ] Chain ID is `nexarail-devnet-1`
- [ ] REST API responds for custom endpoints

## Live Flags

- [ ] `settlement.live_enabled` = false
- [ ] `settlement.treasury_routing_enabled` = false
- [ ] `settlement.burn_routing_enabled` = false
- [ ] `escrow.live_enabled` = false
- [ ] `treasury.live_enabled` = false
- [ ] `payout.live_enabled` = false

## REST Readback

- [ ] Params endpoints return valid JSON
- [ ] List endpoints return empty arrays (or null for empty state)
- [ ] Not-found endpoints return structured error
- [ ] Exists endpoints return boolean
- [ ] Treasury summary returns all zeros

## Evidence Review

- [ ] Evidence manifest reviewed
- [ ] Product-flow evidence inspected (487/0)
- [ ] REST parity confirmed (36/36)
- [ ] Predeployment check passed (23/23)
- [ ] Safety wording audit reviewed

## Understanding

- [ ] Understands this is **NOT** a public testnet
- [ ] Understands this is **NOT** mainnet
- [ ] Understands there is **NO** token sale
- [ ] Understands external validators are **NOT** onboarded
- [ ] Understands live funds are **NOT** enabled
- [ ] Understands tokens have **zero monetary value**
