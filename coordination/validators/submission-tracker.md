# Validator Submission Tracker

**Network:** `nexarail-testnet-1`
**Status:** NodeSync gentx accepted; DNS peer confirmed; TCP 26656 not reachable
**Last updated:** 2026-05-30

NodeSync has provided public validator metadata and the original gentx JSON. The canonical gentx copy matches the submitted SHA256 and passes the controlled gentx verifier. The DNS peer endpoint is confirmed for generated persistent peers; the gentx memo IP is retained as a noted difference. Phase 17E reachability checks found TCP 26656 connection refused for both the DNS host and direct IP.

| validator_id | moniker | contact status | node ID received | account/operator addresses received | endpoint received | gentx received | gentx hash verified | gentx accepted/rejected | peer entry generated | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| nodesync | NODESYNC | accepted | yes | yes | P2P DNS confirmed; TCP not reachable | yes | yes | accepted | generated | SHA256 `fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601`; final peer uses DNS `nexarail-testnet-peer.nodesync.top`; gentx memo IP is `178.104.162.88`; TCP 26656 returned connection refused at `2026-05-30T00:37:58Z`. |

## Rules

- Track only real public/non-secret validator data that has actually been received.
- Do not record private contact details unless they are intended for the public coordination file.
- Do not record or commit private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, node data, or database files.
- Final public genesis remains deferred until NodeSync P2P reachability, launch-window sign-off, and coordinator freeze gates pass.
