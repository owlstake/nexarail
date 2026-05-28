# Agent Testnet Data Policy

**Date:** 2026-05-27  
**Scope:** local validator-agent rehearsals for `nexarail-agent-testnet-1`  
**Status:** Active after Phase 9V

## Purpose

This policy defines when local validator-agent data should be wiped, when it may be reused, and how evidence should be handled. It applies to the local validator-agent rehearsal only. It does not define production validator operations.

## Phase 9V Status

Phase 9V fixed and validated local agent restart safety for the tested rehearsal paths.

Evidence:

```text
rehearsals/validator-agents/restart-investigation/evidence/20260527T133148Z/
```

Validated modes:

- single-validator clean stop and reuse-data restart;
- 3-agent clean stop and reuse-data restart;
- 5-agent clean stop and reuse-data restart;
- 5-agent restart at height 20;
- 5-agent restart after a 60-minute soak;
- one-node restart while four validators continue;
- simultaneous all-node direct restart;
- sequential all-node direct restart;
- standard single-node direct restart.

Result: all tested restart paths resumed block production, queries worked, validator sets remained stable, and proposal panic scans were clean.

## Clean-Spawn Mode

Clean-spawn mode is the default supported mode for reproducible agent rehearsals.

Command:

```bash
scripts/testnet/spawn-validator-agents.sh --clean
```

Clean-spawn mode:

- stops old validator-agent processes;
- refuses stale data unless clean mode is explicit;
- wipes each agent `data/`, `config/`, and `.nexarail/` directory;
- regenerates genesis and gentxs;
- writes a fresh genesis checksum;
- records clean-spawn proof in the evidence directory.

Use clean-spawn mode for baseline rehearsals, final proof runs, governance evidence, launch-readiness checks, and any run where stale state could weaken the result.

## Reuse-Data Mode

Reuse-data mode is diagnostic and must be explicit.

Command:

```bash
scripts/testnet/spawn-validator-agents.sh --reuse-data
```

Reuse-data mode:

- keeps existing agent homes and chain data;
- does not regenerate genesis;
- starts agents from existing data directories;
- must only be used after a cleanly stopped local agent run;
- must write restart evidence separately from clean-spawn evidence.

Reuse-data mode is acceptable for explicit restart testing after a clean stop.

Phase 9U result: reuse-data restart was unsafe in the captured evidence run. Agents restarted and queries remained available, but block production did not resume beyond height `695`.

Phase 9V result: the restart bug was fixed. Reuse-data restart resumed block production in the controlled matrix, including the 5-agent restart-after-60-minute-soak case.

Reuse-data mode remains diagnostic by default. Use clean-spawn for proof-quality baseline rehearsals, then use reuse-data only when restart safety is the explicit subject of the run.

## When To Wipe Data

Wipe data when:

- starting a new proof run;
- changing genesis, gentxs, ports, validator keys, or app configuration;
- a previous run ended uncleanly;
- query readback or governance results are being used as launch-readiness evidence;
- there is any doubt about state provenance.

## When Not To Wipe Data

Do not wipe data when:

- running the explicit Phase 9U persistence-safe restart test;
- debugging restart/resume behavior;
- preserving failed-run evidence for review;
- comparing pre-stop and post-restart heights.

## Known Risks

- Reusing data can hide stale genesis, stale validator keys, or old module state.
- Reusing data can confuse evidence if old logs and new logs are mixed.
- Local agent process cleanup can differ from production service supervision.
- A reuse-data failure in this local rehearsal does not automatically prove a protocol-level persistence failure.

## Production/Testnet Difference

Local validator agents are convenience processes on one machine. They are not the same as independent validator operators running supervised services with persistent disks, backups, monitoring, and operational procedures.

Production-style restart safety must still be validated in a standard deployment setup before external launch decisions rely on it. Phase 9V validates the local agent rehearsal path, not supervised external validator operations.

## Evidence Handling

Evidence must be written to a timestamped directory and never merged with older proof runs.

Long-soak evidence path:

```text
rehearsals/validator-agents/long-soak/evidence/<timestamp>/
```

Restart-investigation evidence path:

```text
rehearsals/validator-agents/restart-investigation/evidence/<timestamp>/
```

Required evidence:

- spawn logs;
- soak samples;
- query samples;
- transaction hashes;
- restart attempt logs;
- panic/error scans;
- final summary;
- final live flags.

If reuse-data fails, preserve the logs and document the specific failed mode. Do not classify it as a production protocol failure unless a standard deployment setup reproduces the same failure.
