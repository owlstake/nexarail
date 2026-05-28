# Phase 9T — Clean-Spawn Query Readback and Governance Results

**Date:** 2026-05-27  
**Chain:** `nexarail-agent-testnet-1`  
**Status:** Complete — clean-spawn live readback and governance final-state proof captured

## Phase 9U Follow-On

Phase 9U extended the Phase 9T baseline with a clean-spawn long soak:

- Duration: 3602 seconds.
- Start/final height: 12 / 685.
- Height delta: 673.
- Average block time: 5.35s.
- Peer count range: 4-4.
- Validator set range: 5-5.
- Periodic query result: 425 pass / 0 fail / 0 skip.
- Runtime bank-send tx: `9F85BD88F936818D6A910BEE640DDAF3B1D437F993519BE2FACCCF3D0E0E52A5`, inclusion code 0.
- Reuse-data restart result: unsafe for local agent rehearsals; agents restarted and queries passed, but block production did not resume beyond height 695.
- Phase 9U evidence: `rehearsals/validator-agents/long-soak/evidence/20260527T102106Z/`.

Clean-spawn remains the required mode for proof-quality local agent rehearsals.

## Clean Data Policy

`scripts/testnet/spawn-validator-agents.sh` now enforces clean-spawn hygiene:

- stops existing validator-agent processes before spawning;
- refuses stale agent data by default;
- permits stale data reuse only with explicit `--reuse-data`;
- wipes each agent `data/`, `config/`, and `.nexarail/` path in `--clean` mode;
- supports `--full-reset` for deleting full agent homes;
- regenerates genesis and gentxs;
- writes a fresh genesis checksum and clean-spawn proof.

The run printed `CLEAN SPAWN: data directories wiped`.

## Clean-Spawn Runtime

- Agents running: 5
- Validator set count: 5
- Alpha peer count: 4
- Readback proof height: 21
- Genesis checksum: `1e1e515b37139ba88a9bdd41a57c131c5d4da3c7ea615f6505a668be225b2253`
- Panic scan: no panics found in captured agent logs

## Query Readback Result

`scripts/testnet/query-validator-agents.sh` passed against the clean 5-agent runtime.

- Latest height query: passed
- Bank balance query: passed
- Auth account query: passed
- Custom module params queries: passed for fees, merchant, settlement, escrow, payout, treasury
- Initial live flags: all false
- Query summary: 85 pass, 0 fail, 0 skip

## Governance Rerun Result

The escrow live flag lifecycle passed end-to-end with final state readback.

- Enable proposal ID: `1`
- Enable submit tx: `CBFBBDD5964C7B1D2C9C0BBDE8D9CAA40863F734E3B4BA4C4B08CE22F8840338`
- LiveEnabled after enable: `true`
- Disable proposal ID: `2`
- Disable submit tx: `46733082097465AD2BEA3B8A7532F18F9B4A5F6CCD44FC798EF508957E53CECC`
- LiveEnabled after disable: `false`
- Governance summary: 49 pass, 0 fail

## Vote Tx Hashes

Enable proposal votes:

- alpha: `9721371596D889E1FA26147F6181BE018D4E2808F945545479840C72AA2DCCC7`
- bravo: `B4C1DCEF484C5028FC69401AF6F1250C56FCD35B367821BEB65FDF0FE0FFDAB5`
- charlie: `C0CD73082375AD65FD0A590F0B07BB9D814DBD5B0CA13103EC6A694AFB7733D8`
- delta: `6D1FB1A92D5445665F38B98E437D1A77411DA4FF296D80F0E537B16D0E731ED5`
- echo: `CDF7111C3D34E1B35C1C7F7686FC2E3518DE7E09755D6805F6E93278FDCD7091`

Disable proposal votes:

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

- Governance evidence: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/`
- Query readback evidence: `rehearsals/validator-agents/query-readback/evidence/20260527T095523Z/`
- Clean spawn proof: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/clean-spawn-proof.txt`
- Final state flags: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/final-state/final-live-flags.txt`
- Verification logs: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/verification/`
- Safety wording audit: `rehearsals/validator-agents/clean-spawn-governance/evidence/20260527T095523Z/safety-wording-audit/`

## Verification

- `go mod tidy`: pass
- `go mod verify`: pass
- `go build ./...`: pass
- `go vet ./...`: pass
- `go test ./...`: pass
- `scripts/testnet/predeployment-check.sh`: pass

## Safety Wording Audit

Terms audited: `decentralised`, `independent validators`, `external validators`, `mainnet live`, `buy NXRL`, `token sale`, `investment`, `guaranteed`, `profit`, `APY`, `returns`, `price`, `listing`.

Result: pass after review. Remaining `decentralised` uses are negative/qualified or audit-command literals. External validator references are pending/future onboarding status only, not claims of external validator participation.

## Remaining Blockers

- External validator launch remains pending.
- The 5-agent local runtime proves agent-based rehearsal behavior only. It does not prove external validator participation.
- No mainnet launch has occurred.
- NXRL remains testnet/devnet-only in this evidence set.
