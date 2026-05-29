# Validator Submission Tracker

**Network:** `nexarail-testnet-1`
**Status:** NodeSync metadata received; gentx file content pending local receipt
**Last updated:** 2026-05-29

NodeSync has provided public validator metadata and a claimed gentx filename/SHA256. The gentx JSON file content is not present in the local workspace yet, so SHA256 and gentx verification remain pending.

| validator_id | moniker | contact status | node ID received | account/operator addresses received | endpoint received | gentx received | gentx hash verified | gentx accepted/rejected | peer entry generated | notes |
|---|---|---|---|---|---|---|---|---|---|---|
| nodesync | NODESYNC | metadata received | yes | yes | P2P only | file content pending | no | waiting for gentx file | no | Claimed gentx SHA256 `fbf829ef28330323d6850f89b7219f2d43a47e98ecce91ba16e46aef94566601`; request resend/upload of JSON file. |

## Rules

- Track only real public/non-secret validator data that has actually been received.
- Do not record private contact details unless they are intended for the public coordination file.
- Do not record or commit private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, node data, or database files.
- Final public genesis remains deferred until verified external gentxs exist.
