# Genesis Gentx Review Checklist — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Phase:** 7B — Gentx Verification
**Use:** Verify each gentx before inclusion in genesis

---

## Gentx Verification Checklist

For each submitted gentx file, verify all items below. Mark each as pass or fail.

| # | Check | Expected | Pass? |
|---|---|---|---|
| **Identity** | | | |
| 1 | Moniker present and non-empty | Moniker field populated | ☐ |
| 2 | Moniker not duplicated | Unique among all accepted validators | ☐ |
| 3 | Validator operator address present | `validator_address` field populated | ☐ |
| 4 | Operator address format correct | Starts with `nxrvaloper` | ☐ |
| 5 | Operator address matches application | Same as applicant registered address | ☐ |
| **Consensus** | | | |
| 6 | Consensus pubkey present | `pubkey` field populated with `@type` | ☐ |
| 7 | Consensus pubkey not duplicated | Unique among all accepted validators | ☐ |
| 8 | Pubkey type is ed25519 | `@type: /cosmos.crypto.ed25519.PubKey` | ☐ |
| **Delegation** | | | |
| 9 | Self-delegation denom correct | `unxrl` | ☐ |
| 10 | Self-delegation amount sufficient | ≥ 500,000,000 unxrl | ☐ |
| 11 | Self-delegation amount matches application | Matches declared amount (or higher) | ☐ |
| **Chain** | | | |
| 12 | Chain ID correct | `nexarail-testnet-1` | ☐ |
| 13 | Account has genesis allocation | Address present in genesis accounts | ☐ |
| 14 | Account balance ≥ self-delegation | Balance sufficient to cover delegation | ☐ |
| **Commission** | | | |
| 15 | Commission rate within range | 0.00 – 0.20 (rate ≤ max-rate) | ☐ |
| 16 | Max commission rate within range | 0.00 – 0.20 | ☐ |
| 17 | Max change rate within range | 0.00 – 0.10 | ☐ |
| 18 | Commission params match application | Consistent with declared values | ☐ |
| **Signature** | | | |
| 19 | Gentx signature valid | JSON parses without error | ☐ |
| 20 | Gentx is a valid protobuf message | `body.messages[0]["@type"]` = `/cosmos.staking.v1beta1.MsgCreateValidator` | ☐ |
| **Genesis Integration** | | | |
| 21 | Genesis validates after including this gentx | `nexaraild validate-genesis` passes | ☐ |
| 22 | No duplicate gentx for same operator | Only one gentx per validator | ☐ |

## Verification Commands

### Check gentx contents
```bash
python3 -c "
import json
with open('gentx.json') as f:
    g = json.load(f)
msg = g['body']['messages'][0]
print('Moniker:', msg.get('description', {}).get('moniker', 'N/A'))
print('Operator:', msg.get('validator_address', 'N/A'))
print('Pubkey:', msg.get('pubkey', {}).get('key', 'N/A')[:20] + '...')
print('Amount:', msg.get('value', {}).get('amount', 'N/A'), msg.get('value', {}).get('denom', 'N/A'))
print('Commission:', msg.get('commission', {}).get('rate', 'N/A'))
"
```

### Check for duplicate pubkeys
```bash
for f in gentx-collection/*.json; do
    python3 -c "import json; g=json.load(open('$f')); print(g['body']['messages'][0]['pubkey']['key'])"
done | sort | uniq -d
# Output should be empty (no duplicates)
```

### Check for duplicate monikers
```bash
for f in gentx-collection/*.json; do
    python3 -c "import json; g=json.load(open('$f')); print(g['body']['messages'][0]['description']['moniker'])"
done | sort | uniq -d
# Output should be empty (no duplicates)
```

### Validate genesis with all gentxs
```bash
# Copy all gentxs to genesis config
cp gentx-collection/*.json ~/.nexarail/config/gentx/

# Collect
./build/nexaraild collect-gentxs

# Validate
./build/nexaraild validate-genesis
# Expected: success (no errors)
```

### Count gentxs in genesis
```bash
python3 -c "
import json
g = json.load(open('$HOME/.nexarail/config/genesis.json'))
print(f'gen_txs: {len(g[\"app_state\"][\"genutil\"][\"gen_txs\"])}')
"
```

## Common Issues & Resolutions

| Issue | Resolution |
|---|---|
| "account not found in genesis" | Add validator's account: `nexaraild add-genesis-account <addr> 1000000000000unxrl` |
| "insufficient funds" | Increase genesis allocation for the validator |
| "chain-id mismatch" | Validator used wrong chain ID — request re-submission |
| "duplicate pubkey" | Validator re-used keys from another chain — request new keys |
| "duplicate moniker" | Request validator to choose a unique moniker |
| "commission rate exceeds max" | Commission rate > max rate — request correction |
| "invalid signature" | Gentx corrupted or malformed — request re-submission |
| "validate-genesis fails after inclusion" | Check error message — usually parameter mismatch or duplicate |

## Acceptance Criteria

A gentx is **accepted** when all 22 checks pass.

A gentx is **rejected** if:
- Any identity, consensus, delegation, chain, or signature check fails
- Duplicate moniker or pubkey detected
- Genesis fails validation after inclusion

Rejected gentx: contact validator with specific issue, request re-submission before deadline.

## Gentx Storage

```
rehearsals/testnet-1/gentx-collection/
├── APP-XXX-<moniker>-gentx.json
├── APP-YYY-<moniker>-gentx.json
└── ...
```

File naming convention: `APP-XXX-<moniker-slug>-gentx.json`

Keep gentx files until after launch. Archive after 30 days of stable operation.
