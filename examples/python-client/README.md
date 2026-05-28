# NexaRail Python Client Examples

Lightweight Python client using only the standard library.  
**Zero pip dependencies.** Read-only queries against a local RC1 devnet.

## Prerequisites

- Python 3.8 or later
- A running NexaRail RC1 devnet (default: `http://localhost:1317`)

## How to Run

```bash
# Check live flags (params)
python3 check_live_flags.py

# Query full product state
python3 query_product_state.py
```

## Override API URL

```bash
API=http://localhost:1317 python3 check_live_flags.py
API=http://localhost:1317 python3 query_product_state.py
```

## Override RPC URL

```bash
RPC=http://localhost:26657 python3 check_live_flags.py
```

## Scripts

| Script | Description |
|--------|-------------|
| `nexarail_client.py` | Helper module — wraps `urllib.request` for REST + RPC |
| `check_live_flags.py` | Checks `live_enabled` on all 4 modules |
| `query_product_state.py` | Full product-state dump (node, treasury, merchants, etc.) |

## Local Install

```bash
cd examples/python-client
pip install -e .     # editable install from local source
```

## Local Test

```bash
cd examples/python-client
python3 test_client.py
```

## Safety

```
⚠️  LOCAL DEVNET ONLY — Do not use against mainnet or any public testnet.
⚠️  NOT PUBLISHED — This package is NOT available on PyPI. Local install only.
⚠️  NO TOKEN SALE — This is a developer tool, not a token launch.
⚠️  NO PRIVATE KEYS — The SDK performs read-only queries and string-building only.
    It never handles private keys, mnemonics, or wallet secrets.
```

## No Dependencies

This client uses only Python standard library modules (`json`, `os`, `urllib.request`, `urllib.error`, `sys`). No `pip install` required for basic script usage.
