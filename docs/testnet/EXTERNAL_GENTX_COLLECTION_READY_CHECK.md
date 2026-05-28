# External Gentx Collection Ready Check

**Date:** 2026-05-27  
**Scope:** readiness checklist for accepting external validator gentxs  
**Chain:** `nexarail-testnet-1`

## Per-Validator Checklist

| Check | Required | Status | Notes |
|---|---|---|---|
| Validator accepted | Yes | ☐ | Acceptance recorded in validator set draft |
| Moniker reviewed | Yes | ☐ | No impersonation, offensive text, or unsafe claims |
| Operator address format valid | Yes | ☐ | Must use `nxr` prefix |
| Operator address funded | Yes | ☐ | Testnet self-delegation funds allocated |
| Node ID collected | Yes | ☐ | Required for persistent peers |
| Validator pubkey collected | Yes | ☐ | Required for gentx validation |
| Pubkey uniqueness checked | Yes | ☐ | No duplicate consensus pubkeys |
| Gentx file received | Yes | ☐ | Only gentx JSON accepted |
| Gentx signature valid | Yes | ☐ | Verify with `verify-submitted-gentx.sh` |
| Self-delegation denom `unxrl` | Yes | ☐ | Reject wrong denom |
| Self-delegation amount meets requirement | Yes | ☐ | Expected `500000000unxrl` unless coordinator changes testnet-only value |
| Commission parameters reviewed | Yes | ☐ | Within accepted range |
| Chain ID matches | Yes | ☐ | Must be `nexarail-testnet-1` |
| Genesis inclusion confirmed | Yes | ☐ | Gentx included in final candidate |
| Validator set count updated | Yes | ☐ | Cohort count matches accepted validators |
| Genesis checksum updated | Yes | ☐ | SHA256 recorded after inclusion |
| Final live flags false | Yes | ☐ | All six live flags remain `false` |
| Acknowledgement sent | Yes | ☐ | Validator notified of acceptance or required correction |

## Batch Checklist

- [ ] Minimum 3 accepted validators have valid gentxs.
- [ ] Preferred 5 accepted validators have valid gentxs, if available.
- [ ] No duplicate operator addresses.
- [ ] No duplicate consensus pubkeys.
- [ ] No duplicate node IDs.
- [ ] All gentx files are stored in the coordinator evidence path.
- [ ] Final genesis candidate validates.
- [ ] Final genesis checksum recorded.
- [ ] Persistent peer list generated.
- [ ] Accepted validators have acknowledged final genesis and launch window.

## Commands

Validate one submitted gentx:

```bash
scripts/testnet/verify-submitted-gentx.sh <path-to-gentx.json>
```

Assemble candidate genesis:

```bash
scripts/testnet/assemble-testnet-genesis.sh
```

Check final genesis:

```bash
scripts/testnet/check-final-genesis.sh
```

## Rejection Reasons

Reject or request correction if:

- validator was not accepted;
- gentx includes wrong chain ID;
- self-delegation denom is not `unxrl`;
- signature is invalid;
- consensus pubkey is duplicated;
- operator address format is invalid;
- moniker impersonates another project or contains unsafe claims;
- private material was submitted.

If private material is submitted, stop processing that submission and instruct the validator to rotate keys.
