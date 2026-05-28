# NexaRail RC1 — Quickstart

A concise command-first guide. No long paragraphs.

---

## Prerequisites

**Option A — Go 1.26+ (compile from source):**

```bash
go version  # must show go1.26 or later
```

**Option B — Download RC1 binary (recommended):**

```bash
# linux/amd64
curl -LO <package-url>/releases/testnet-rc1/binaries/nexaraild-linux-amd64
chmod +x nexaraild-linux-amd64

# darwin/arm64
curl -LO <package-url>/releases/testnet-rc1/binaries/nexaraild-darwin-arm64
chmod +x nexaraild-darwin-arm64
```

---

## Verify package

```bash
shasum -a 256 -c releases/testnet-rc1/checksums/SHA256SUMS
```

---

## Run single-node devnet

```bash
bash scripts/release/launch-rc1-devnet.sh --single-node --clean
```

---

## Query status

```bash
curl -s http://127.0.0.1:26657/status | jq .result.sync_info.latest_block_height
```

---

## Query live flags

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq .params.live_enabled
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/params      | jq .params.live_enabled
curl -s http://127.0.0.1:1317/nexarail/treasury/v1/params    | jq .params.live_enabled
curl -s http://127.0.0.1:1317/nexarail/payout/v1/params      | jq .params.live_enabled
```

All four should return `false`.

---

## Hit custom REST endpoints

**Params / detail endpoint:**

```bash
curl -s http://127.0.0.1:1317/nexarail/settlement/v1/params | jq .
```

**List endpoint:**

```bash
curl -s http://127.0.0.1:1317/nexarail/escrow/v1/escrows | jq .
```

**Exists endpoint:**

```bash
curl -s 'http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-id/does-not-exist/exists' | jq .
```

**Not-found endpoint (structured error):**

```bash
curl -s 'http://127.0.0.1:1317/nexarail/escrow/v1/escrows/by-id/00000000-0000-0000-0000-000000000000' | jq .
```

---

## Stop devnet

```bash
bash scripts/release/stop-rc1-devnet.sh
```

---

## Clean state

```bash
rm -rf ~/.nexarail-devnet rehearsals/rc1-devnet
```

---

## ⚠️ Important Notes

> ⚠️ **NOT** a public testnet  
> ⚠️ **NOT** mainnet  
> ⚠️ **NO** token sale  
> ⚠️ Tokens have **zero monetary value** — test tokens only
