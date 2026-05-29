# Phase 17A Controlled Testnet Dry-Run Results

**Date:** 2026-05-29
**Network:** `nexarail-testnet-1`
**Scope:** local five-validator rehearsal for the controlled external-validator launch path
**Status:** PASS

## Summary

The Phase 17A dry-run exercised the controlled testnet launch path with five local validators:

- built `nexaraild` from source;
- initialised five clean validator homes;
- generated five gentxs for `nexarail-testnet-1`;
- verified each gentx with `scripts/testnet/verify-controlled-testnet-gentx.sh`;
- assembled a final genesis with `scripts/testnet/assemble-controlled-testnet-genesis.sh`;
- generated persistent peers with `scripts/testnet/generate-persistent-peers.sh`;
- started five local validator processes from the assembled genesis;
- verified block production through height 20;
- verified validator set count of 5;
- verified `tendermint show-node-id` and `comet show-node-id`;
- verified product live flags remained false.

## Result

| Check | Result |
|---|---|
| Validators initialised | PASS |
| Gentxs generated | PASS |
| Gentx verification | PASS |
| Genesis assembly | PASS |
| `validate-genesis` | PASS |
| Persistent peers generation | PASS |
| Five validators started | PASS |
| First 20 blocks | PASS |
| Validator set count | 5 |
| Product live flags | false |
| Tendermint/comet node ID helpers | PASS |

## Genesis Checksum

```text
5fc2ad8a76cfee850e33ddf8f94f403b101657f27de6f0c8885021e8b2c74d90  genesis.json
```

## Evidence

Local evidence path:

```text
rehearsals/controlled-testnet/dry-run/evidence/20260529T132046Z/
```

Raw local evidence includes generated validator homes, gentxs, logs, and assembled genesis for rehearsal purposes only. It is not a public launch genesis and must not be treated as the final external-validator testnet genesis.

## Boundary

This dry-run proves the launch tooling path locally. It does not prove public testnet operation, live external validators, or mainnet readiness. The controlled external-validator testnet remains **not launched** until final genesis is published and accepted external validators are running from that genesis.
