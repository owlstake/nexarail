# Genesis Publication Checklist

**Network:** `nexarail-testnet-1`
**Status:** template; final public genesis not assembled

Use this checklist only after verified external gentxs exist and the freeze gate returns `FREEZE_GO`.

| Item | Value / Status |
|---|---|
| Final genesis path | `releases/testnet-genesis/nexarail-testnet-1/genesis.json` |
| Final genesis SHA256 | TBD |
| Manifest | TBD |
| Binary/tag | `v0.1.0-rc1-cli-hotfix` or later reviewed source tag |
| Persistent peers | TBD |
| Seed nodes | TBD |
| Validator count | TBD |
| Launch time UTC | TBD |
| Status page updated | Pending |
| Validator acknowledgement | Pending |
| Rollback plan acknowledged | Pending |
| Coordinator sign-off | Pending |
| Final no-secrets scan | Pending |
| Final safety wording check | Pending |

## Publication Gates

- [ ] Verified external gentx count is greater than zero.
- [ ] Accepted validator count matches verified gentx count.
- [ ] `validate-genesis` passes.
- [ ] `SHA256SUMS` written and independently checked.
- [ ] `manifest.json` written.
- [ ] Persistent peers generated from accepted records.
- [ ] Endpoint inventory reviewed.
- [ ] Product live flags confirmed false.
- [ ] No private keys, mnemonics, node keys, validator signing keys, keyrings, node data, or database files in publication artifacts.
- [ ] Launch-window rollback plan reviewed.
- [ ] Coordinator signs off.

## Safety Boundary

Publishing a final genesis candidate does not by itself mean the public testnet is live. Launch status changes only after the confirmed launch window starts, accepted external validators are running, and evidence exists. Mainnet remains NO-GO. No token sale is announced or implied. Testnet denominations have no monetary value.
