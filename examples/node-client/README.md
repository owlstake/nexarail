# NexaRail Node.js Client Examples

Lightweight Node.js client using built-in `fetch` (Node 18+).  
**Zero npm dependencies.** Read-only queries against a local RC1 devnet.

## Prerequisites

- Node.js 18 or later
- A running NexaRail RC1 devnet (default: `http://localhost:1317`)

## How to Run

```bash
# Check live flags (params)
node src/checkLiveFlags.js

# Query full product state
node src/queryProductState.js
```

## Override API URL

```bash
API=http://localhost:1317 node src/checkLiveFlags.js
API=http://localhost:1317 node src/queryProductState.js
```

## Override RPC URL

```bash
RPC=http://localhost:26657 node src/checkLiveFlags.js
```

## Scripts

| Script | Description |
|--------|-------------|
| `src/client.js` | Helper module — wraps fetch for REST + RPC |
| `src/checkLiveFlags.js` | Checks `live_enabled` on all 4 modules |
| `src/queryProductState.js` | Full product-state dump (node, treasury, merchants, etc.) |

## Local Install

```bash
cd examples/node-client
npm install              # installs local metadata (no runtime deps currently)
# or create a global symlink:
npm link                 # makes @nexarail/devnet-client available system-wide
```

## Local Test

```bash
cd examples/node-client
node test/client.test.js          # run vanilla JS tests
# or:
npm test                          # same as above
npm run check                     # verify all exports load correctly
```

## Safety

```
⚠️  LOCAL DEVNET ONLY — Do not use against mainnet or any public testnet.
⚠️  NOT PUBLISHED — This package is NOT available on npm. Local install only.
⚠️  NO TOKEN SALE — This is a developer tool, not a token launch.
⚠️  NO PRIVATE KEYS — The SDK performs read-only queries and string-building only.
    It never handles private keys, mnemonics, or wallet secrets.
```

## No Dependencies

This client uses only Node.js built-ins (`fetch`, `process.env`). No `npm install` required for basic script usage.
