# Validator Cohort Targets — NexaRail Testnet

**Date:** 2026-05-26
**Chain:** nexarail-testnet-1

---

## Cohort Sizing

| Cohort | Validators | Fault Tolerance | Timeline |
|---|---|---|---|
| Minimum viable | 3 | 0 (all must be online) | Launch when ≥ 3 gentxs verified |
| Preferred | 5 | 1 offline tolerated | Extend intake to reach 5 if feasible |
| Strong | 7 | 2 offline tolerated | Target for post-launch growth |
| Maximum first | 10 | 3 offline tolerated | Cap to keep coordination manageable |

## Diversity Goals

| Dimension | Target |
|---|---|
| Geographic regions | ≥ 2 (different continents preferred) |
| Hosting providers | ≥ 2 (no single-provider dependency) |
| Linux distributions | Any (Ubuntu/Debian preferred) |
| Validator experience | Mix of experienced + newer operators |
| Organisations | Mix of individuals + organisations |

## Infrastructure Requirements

| Component | Minimum | Recommended |
|---|---|---|
| OS | Linux | Ubuntu 22.04+ |
| CPU | 4 vCPU | 8 vCPU |
| RAM | 8 GB | 16 GB |
| Disk | 100 GB SSD | 200 GB NVMe |
| Network | 100 Mbps, static IP | 1 Gbps |
| Ports | 26656 (P2P), 26657 (RPC) | + monitoring ports |
| Redundancy | None required | Power + network |

## Linux Requirement

macOS and Docker Desktop are not supported for validator operation. The Docker rehearsal confirmed P2P instability on macOS — validators disconnect after ~20 blocks. All validators must run Linux.

Validators unable to provision Linux hosts will not be accepted.

## Application Priorities

In order of preference:
1. Known Cosmos validators with proven track records
2. Infrastructure/node operators with Linux experience
3. Technical community members with validator experience
4. New operators with strong technical capability demonstrated

## Exclusions

Will not be accepted:
- Operators making token value or investment claims
- Operators intending to run on macOS/Docker Desktop
- Operators with history of validator attacks
- Fraudulent or incomplete applications
- Operators in restricted jurisdictions (legal review TBD)

## No Retail / Investment Framing

This is NOT:
- A retail validator program
- An investment opportunity
- A token distribution event
- A mainnet validator pre-selection

This IS:
- Technical infrastructure testing
- Controlled testnet participation
- A limited, curated validator set
