# Agent Testnet Limitations

**Date:** 2026-05-27  
**Scope:** limitations of the NexaRail local agent-testnet evidence package

## Summary

The local agent testnet is a controlled engineering rehearsal. It is useful for proving runtime behaviour under local agent conditions, but it is not a substitute for an external validator testnet, public infrastructure launch, audit, legal review, or mainnet.

## Limitations

1. **Agent validators are not external validators.** The current validator set is made of local development-operated agents.
2. **No external decentralisation proof.** The agent validator set does not prove external validator participation, external operations, or externally distributed control.
3. **Local environment only.** The evidence was collected on a local agent environment, not a multi-machine public testnet.
4. **Multi-machine/Linux rehearsal pending.** The agent evidence does not replace Linux or production-like supervised node rehearsal.
5. **External validators pending.** No external validator cohort has launched from this evidence package.
6. **External gentxs pending.** The planned public/external testnet still needs external gentx collection and validation.
7. **Final genesis candidate pending.** A final public/external testnet genesis candidate has not been assembled from external gentxs.
8. **Public RPC/API endpoints pending.** Public infrastructure has not been deployed from this evidence package.
9. **External audit pending.** A formal third-party security audit has not been completed.
10. **Legal review pending.** Formal independent legal review has not been completed.
11. **Mainnet not live.** NexaRail has no public mainnet.
12. **No token sale.** NXRL has not been offered for sale and is not available to buy.
13. **Testnet tokens have no monetary value.** Testnet tokens are for testing only.
14. **Live funds remain disabled by default.** Phase 9W did not enable genesis live flags.

## Correct Interpretation

Phase 9W supports this statement:

```text
The local NexaRail agent testnet has proven block production, query/readback, runtime transaction inclusion, governance lifecycle, long-soak stability, and restart recovery under controlled local agent conditions.
```

Phase 9W does not support these statements:

```text
No proof that external validators are live.
No proof that NexaRail is externally decentralised.
No proof that the public testnet is launched.
No proof that mainnet is live.
No proof that NXRL is available to buy.
No proof that a token sale exists.
```

## Required Before Public/External Testnet Launch

- Accept external validators.
- Collect and validate external gentxs.
- Assemble final genesis candidate.
- Publish release tag and checksums.
- Prepare public RPC/API endpoint plan.
- Create validator communication channel.
- Run multi-machine or Linux rehearsal.
- Complete launch go/no-go review.

## Required Before Mainnet Consideration

- Complete public/external testnet.
- Complete external security audit and remediation.
- Complete legal review.
- Complete final release process.
- Obtain explicit coordinator sign-off.
