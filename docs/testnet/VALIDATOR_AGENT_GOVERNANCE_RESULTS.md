# Validator Agent Governance Results

**Date:** 2026-05-27  
**Chain:** `nexarail-agent-testnet-1`  
**Status:** Complete — proposal lifecycle and final state readback captured

## Phase Summary

| Phase | Status | Key Achievement |
|---|---|---|
| Phase 9F | Complete | Gov v1 submit-proposal with `MsgUpdateParams` |
| Phase 9L | Complete | Bank send proven on-chain |
| Phase 9M | Complete | Proto tx broadcast path proven |
| Phase 9O | Complete | First on-chain governance proposal submitted |
| Phase 9T | Complete | Clean-spawn enable/disable lifecycle with final-state query proof |

## Phase 9T Final Governance Evidence

- Enable proposal ID: `1`
- Enable proposal status: `PROPOSAL_STATUS_PASSED`
- Enable submit tx: `CBFBBDD5964C7B1D2C9C0BBDE8D9CAA40863F734E3B4BA4C4B08CE22F8840338`
- LiveEnabled after enable: `true`
- Disable proposal ID: `2`
- Disable proposal status: `PROPOSAL_STATUS_PASSED`
- Disable submit tx: `46733082097465AD2BEA3B8A7532F18F9B4A5F6CCD44FC798EF508957E53CECC`
- LiveEnabled after disable: `false`
- Final all-live-flags state: all false

## Vote Tx Hashes

Enable proposal:

- alpha: `9721371596D889E1FA26147F6181BE018D4E2808F945545479840C72AA2DCCC7`
- bravo: `B4C1DCEF484C5028FC69401AF6F1250C56FCD35B367821BEB65FDF0FE0FFDAB5`
- charlie: `C0CD73082375AD65FD0A590F0B07BB9D814DBD5B0CA13103EC6A694AFB7733D8`
- delta: `6D1FB1A92D5445665F38B98E437D1A77411DA4FF296D80F0E537B16D0E731ED5`
- echo: `CDF7111C3D34E1B35C1C7F7686FC2E3518DE7E09755D6805F6E93278FDCD7091`

Disable proposal:

- alpha: `69C21FDEDB94D6E1FE0C10F3CEB440281FC84BA0A22FA9A38022E362858E8CF5`
- bravo: `0123A12B435EF26871074188F670D1E66D6969533620CBEF1C42F21FD091BA5C`
- charlie: `79C75A402F3C3CC455F07BE84722FB9BC767F5E57DABD31FCFD7511A80ED2204`
- delta: `42EC1D039D3EA50D9950CD6DFBC5989667004F5E362E2DD80AF1B3405694BB2F`
- echo: `C513216750C18F500CADB2A95D37B526F77141DD13FA91BA033B9629FCBBA065`

## Final Live Flags

- `settlement.live_enabled=false`
- `settlement.treasury_routing_enabled=false`
- `settlement.burn_routing_enabled=false`
- `escrow.live_enabled=false`
- `payout.live_enabled=false`
- `treasury.live_enabled=false`

## Evidence

- `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/`
- `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/summary.txt`
- `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/final-state/final-live-flags.txt`

## See Also

- `docs/testnet/PHASE_9T_CLEAN_SPAWN_RESULTS.md`
- `docs/testnet/PHASE_9S_QUERY_READBACK_RESULTS.md`
- `docs/testnet/LAUNCH_GO_NO_GO_REVIEW.md`
