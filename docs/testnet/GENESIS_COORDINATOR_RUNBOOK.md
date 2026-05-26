# Genesis Coordinator Runbook — NexaRail Testnet

**Chain:** nexarail-testnet-1
**Audience:** Genesis coordinator (internal — not for validator distribution)
**Phase:** Controlled Registration → Launch

---

## Phase 1: Application Intake

### 1.1 Receive Applications

Applications arrive via designated channel (GitHub issue, form, or direct message).

### 1.2 Track Applications

Maintain a tracking spreadsheet or document:

| Field | Example |
|---|---|
| Application ID | APP-001 |
| Operator Name | Alice Operator |
| Organisation | Example Labs |
| Date Received | 2026-06-01 |
| Status | Pending Review |
| Moniker | alice-validator |
| Linux Host | Confirmed |
| Experience | 3 years, 5 chains |
| Notes | — |

### 1.3 Acknowledge Receipt

Send acknowledgment within 48 hours:
> "Your validator application for NexaRail testnet has been received. Review typically takes 3-5 days. Reference: APP-XXX."

## Phase 2: Application Review

### 2.1 Review Checklist

For each application, verify:

- [ ] All required fields complete
- [ ] Linux host confirmed (not macOS Docker Desktop)
- [ ] Hardware meets minimum (4 vCPU, 8 GB RAM, 100 GB SSD)
- [ ] Contact information provided
- [ ] Operator has relevant experience or demonstrates technical capability
- [ ] Operator has confirmed all 10 commitments in the application form
- [ ] No red flags (token value claims, investment language, prior misbehaviour)
- [ ] Jurisdiction not on restricted list (if any)

### 2.2 Red Flags

Reject immediately if:
- Operator claims NXRL has monetary value or is an investment
- Operator intends to run on macOS/Docker Desktop as primary infrastructure
- Operator has history of validator attacks or slashing exploits
- Application contains fraudulent information
- Operator refuses to acknowledge testnet-only nature

### 2.3 Approve

Send approval notification:
> "Your validator application (APP-XXX) has been approved for the NexaRail controlled testnet. Next steps: complete the acceptance checklist at docs/testnet/VALIDATOR_ACCEPTANCE_CHECKLIST.md, then follow the gentx submission instructions at docs/testnet/GENESIS_SUBMISSION_INSTRUCTIONS.md. Deadline: [date]."

### 2.4 Reject

Send rejection notification:
> "Your validator application (APP-XXX) has not been accepted for this phase of the NexaRail testnet. Reason: [brief reason]. You may reapply in future phases. Thank you for your interest."

## Phase 3: Gentx Collection

### 3.1 Fund Validator Accounts

Before validators can create gentxs, they need testnet tokens:

```bash
# On the genesis machine:
./build/nexaraild add-genesis-account <validator-address> 1000000000000unxrl
```

**Amount:** 1,000,000,000,000 unxrl (1,000,000 NXRL equivalent) per validator.

### 3.2 Distribute Genesis

Provide each accepted validator with:
- The genesis file
- Genesis checksum
- Persistent peer list

### 3.3 Collect Gentxs

Validators submit their gentx files. Store them:
```
rehearsals/testnet-1/gentx-collection/
├── APP-001-gentx.json
├── APP-002-gentx.json
└── APP-003-gentx.json
```

### 3.4 Verify Each Gentx

For each gentx:

```bash
# Copy gentx to validator's config dir
cp APP-XXX-gentx.json ~/.nexarail/config/gentx/

# Collect all gentxs
./build/nexaraild collect-gentxs

# Check count
python3 -c "
import json
g = json.load(open('$HOME/.nexarail/config/genesis.json'))
print(f'gen_txs: {len(g[\"app_state\"][\"genutil\"][\"gen_txs\"])}')
"
```

Expected: gen_txs count matches number of approved validators.

### 3.5 Handle Invalid Gentx

If a gentx fails validation:
- Notify the validator with the specific error
- Provide troubleshooting guidance
- Request re-submission before deadline

## Phase 4: Genesis Build

### 4.1 Final Genesis Construction

```bash
# Start from clean genesis
./build/nexaraild init coordinator --chain-id nexarail-testnet-1

# Add all validator accounts
./build/nexaraild add-genesis-account <addr1> 1000000000000unxrl
./build/nexaraild add-genesis-account <addr2> 1000000000000unxrl
# ...

# Copy all gentxs
cp gentx-collection/*.json ~/.nexarail/config/gentx/

# Collect
./build/nexaraild collect-gentxs

# Set parameters
TMP=$(mktemp)
jq '.app_state.staking.params.bond_denom = "unxrl" |
    .app_state.gov.voting_params.voting_period = "60s" |
    .app_state.crisis.constant_fee.denom = "unxrl"' \
    ~/.nexarail/config/genesis.json > "$TMP" && mv "$TMP" ~/.nexarail/config/genesis.json
```

### 4.2 Validate Genesis

```bash
./build/nexaraild validate-genesis
```

Must return: "Genesis validation successful" or equivalent success message.

### 4.3 Generate Checksum

```bash
sha256sum ~/.nexarail/config/genesis.json > genesis-checksum.txt
cat genesis-checksum.txt
```

### 4.4 Publish

Publish to all validators:
- Final genesis file
- Genesis checksum
- Peer list (all validator node IDs and IPs)
- Launch time (in UTC)

## Phase 5: Launch Coordination

### 5.1 Pre-Launch Check (T-2 hours)

Contact all validators:
- Confirm they have the correct genesis
- Confirm checksum matches
- Confirm binary built and ready
- Confirm ports open
- Confirm they will be available at T-0

### 5.2 Launch

At T-0, all validators start simultaneously:

```bash
./build/nexaraild start --minimum-gas-prices 0.025unxrl
```

### 5.3 Monitor First 100 Blocks

```bash
# Monitor block production
watch -n 5 'curl -s http://<rpc>:26657/status | jq ".result.sync_info.latest_block_height"'

# Monitor validator set
curl -s http://<rpc>:26657/validators | jq '.result.validators | length'

# Monitor peer count
curl -s http://<rpc>:26657/net_info | jq '.result.n_peers'
```

Checklist for first 100 blocks:
- [ ] Block 1 produced within 30 seconds
- [ ] All validators in validator set
- [ ] Each validator has ≥ N-1 peers (where N = total validators)
- [ ] Block time consistent (~5-6 seconds)
- [ ] No panics in any validator logs
- [ ] Chain ID confirmed: `nexarail-testnet-1`

### 5.4 Handle Failed Validator at Launch

If a validator fails to start:
1. Confirm the issue with the validator
2. If resolvable quickly (misconfiguration), fix and restart
3. If not resolvable, assess whether remaining validators can maintain consensus
4. N validators needed for consensus: N ≥ 3 (2/3+ of total requires all 3)
5. If consensus cannot be reached, halt and reschedule launch

### 5.5 Post-Launch Monitoring

| Time | Check |
|---|---|
| T+15 min | Block height increasing, all validators signing |
| T+1 hour | No performance degradation, peer stability |
| T+6 hours | Disk usage, memory usage, no leaks |
| T+24 hours | Full day of stable operation |
| T+72 hours | Extended stability confirmed |

## Phase 6: Ongoing Coordination

### 6.1 Regular Health Checks

Daily:
- Block production rate
- Validator set integrity
- Peer connectivity
- Disk usage trend

### 6.2 Governance Proposals

- Monitor for submitted proposals
- Notify validators of voting periods
- Track proposal outcomes

### 6.3 Upgrade Coordination

When a new binary is needed:
1. Announce upgrade proposal
2. Coordinate governance vote
3. Distribute new binary and instructions
4. Coordinate upgrade height

## Reset Policy

### When to Reset

- Critical bug discovered requiring genesis change
- Validator set needs restructuring
- Parameter changes requiring new genesis
- Major code upgrade incompatible with state

### Reset Process

1. Announce reset 48+ hours in advance
2. Provide new genesis and checksum
3. Coordinate new launch time
4. All validators wipe data and restart with new genesis

### What Survives a Reset

- Validator identities (node IDs, keys) — if same validator participates
- Nothing else — state is wiped completely

## Emergency Contacts

Maintain an emergency contact list:

| Validator | Operator | Phone/Signal | Secondary |
|---|---|---|---|
| val-1 | Alice O. | +1-555-... | alice@... |
| val-2 | Bob N. | +44-7700-... | bob@... |
| ... | ... | ... | ... |

**This information is confidential.** Do not share validator contact details without permission.
