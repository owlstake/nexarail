# SDK Package Preparation

> **Status**: Local RC1 devnet — pre-release SDK scaffolding
> **Last updated**: 2026-05-28

---

## Scope

NexaRail provides two SDK clients for local RC1 devnet development:

- **Node.js SDK** (`@nexarail/devnet-client`) — `examples/node-client/`
- **Python SDK** (`nexarail-devnet-client`) — `examples/python-client/`

Both clients support:
- **Read-only queries** — fetching chain state, params, treasury, node status
- **Command builders** — constructing CLI tx commands (e.g. `bank send`, `merchant register`) as strings; they do **not** sign or submit transactions

---

## Versioning

| SDK | Version | Location |
|-----|---------|----------|
| Node.js | `0.1.0-dev` | `examples/node-client/VERSION` |
| Python | `0.1.0.dev` | `examples/python-client/VERSION` |

---

## Local Install Only

**These packages are NOT published to any public registry.**

| Registry | Status |
|----------|--------|
| npm | Not published |
| PyPI | Not published |
| GitHub Packages | Not published |

Users must install locally from source.

### Node.js

```bash
cd examples/node-client
npm install     # installs local deps (none currently required)
# or link globally:
npm link        # creates a global symlink
```

### Python

```bash
cd examples/python-client
pip install -e .   # editable install from local source
```

---

## Compatibility

- **Target chain**: RC1 devnet (`nexarail-devnet-1`)
- **Node SDK**: Node.js 18+
- **Python SDK**: Python 3.9+

---

## Limitations

| Area | Detail |
|------|--------|
| **Read-only** | SDK only queries chain state. No mutation calls. |
| **Command builders** | Produce CLI strings only — do not sign, submit, or broadcast. |
| **No private keys** | SDK never handles private keys, mnemonics, or secrets. |
| **Devnet only** | Hardcoded default endpoints target `localhost:1317` / `localhost:26657`. Not configured for testnet or mainnet. |
| **No authentication** | No API keys, tokens, or wallet-based auth. |

---

## Exports

### Node.js SDK (`src/client.js`)

**Read-only functions:**

| Export | Description |
|--------|-------------|
| `get(path)` | Generic GET request |
| `getParams()` | Fetch live-enabled module flags |
| `getList(endpoint)` | Paginated list from an endpoint |
| `getDetail(endpoint, id)` | Single item detail |
| `getExists(endpoint, id)` | Check if item exists (boolean) |
| `getFiltered(endpoint, query)` | Filtered list query |
| `treasurySummary()` | Treasury balance summary |
| `nodeStatus()` | Node sync status |

**Command builders (string output only):**

| Export | Description |
|--------|-------------|
| `bankSendCmd(from, to, amount, denom)` | Construct `tx bank send` |
| `merchantRegisterCmd(alias, owner, bond)` | Construct `tx merchant register` |
| `settlementCreateCmd(seller, buyer, amount)` | Construct `tx settlement create` |
| `escrowCreateCmd(seller, buyer, amount)` | Construct `tx escrow create` |
| `payoutCreateCmd(merchant, amount)` | Construct `tx payout create` |
| `productGovCmd(flag, value)` | Construct `tx product-gov set-live-flag` |

### Python SDK (`nexarail_client.py`)

Mirrors the Node.js exports with snake_case naming.

---

## Testing

### Node.js

```bash
cd examples/node-client
node test/client.test.js       # run vanilla JS tests
# or
npm test                       # same as above
npm run check                  # verify exports load correctly
```

### Python

```bash
cd examples/python-client
python3 test_client.py         # run unittest suite
```

---

## Pre-Publishing Gates

Before these packages can be published to npm / PyPI, the following must be satisfied:

1. **Controlled testnet launch** — SDK must be validated against a shared (non-local) testnet.
2. **Security review** — At minimum: dependency audit, supply-chain hardening, secret/key handling design verified absent.
3. **API stability** — Endpoint paths, response shapes, and export names should be stable or versioned before public release.
4. **Documentation** — Public API docs, migration guide, changelog.
5. **License** — Decide on an open-source license (currently UNLICENSED).
6. **CI/CD** — Automated publishing pipeline via GitHub Actions (npm publish / twine upload).

---

## Safety Notice

```
⚠️  LOCAL DEVNET ONLY — DO NOT USE AGAINST MAINNET
⚠️  NOT PUBLISHED — NOT AVAILABLE ON npm OR PyPI
⚠️  NO TOKEN SALE — THIS IS NOT A TOKEN LAUNCH
⚠️  NO PRIVATE KEY HANDLING — SDK IS READ-ONLY + COMMAND BUILDER ONLY
```
