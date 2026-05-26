# NexaRail Testnet Faucet Plan

**Document:** docs/testnet/FAUCET_PLAN.md
**Version:** 1.0
**Date:** 2026-05-25

## Purpose

Distribute testnet-only `unxrl` tokens to validators, developers, and testers. Tokens have zero monetary value and exist solely for testnet operations.

## Funding Account

A dedicated faucet account receives genesis allocation (e.g., 100,000,000,000,000 unxrl). The faucet mnemonic is held by the core team and never used outside testnet.

```bash
./build/nexaraild keys add faucet --keyring-backend test
# Address: nxr1faucet... (example)
```

## Rate Limits

| Limit | Value |
|---|---|
| Per address per 24h | 1,000,000 unxrl (1 NXRL) |
| Per IP per 24h | 3 requests |
| Cooldown between requests | 1 hour |
| Maximum per address lifetime | 10,000,000 unxrl (10 NXRL) |

Rate limits prevent faucet draining and spam.

## Denominations

| Denom | Display | Value |
|---|---|---|
| `unxrl` | NXRL | 1 NXRL = 1,000,000 unxrl |
| Faucet sends | `unxrl` | Native unit |

## Web Faucet

Simple web interface:
- URL: `https://faucet.testnet.nexarail.network` (TBD)
- Input: NexaRail bech32 address (nxr1...)
- Captcha: hCaptcha or Cloudflare Turnstile
- Cooldown enforced server-side
- Response: transaction hash

Technology: Static HTML + minimal backend (Go net/http or Cloudflare Workers). Sends `MsgSend` from faucet account to requester.

## Discord / Telegram Command

Optional bot command:
```
/faucet nxr1abc123...
```
Bot checks rate limit, sends transaction, replies with tx hash.

## Anti-Abuse Controls

| Control | Implementation |
|---|---|
| IP rate limit | 3 requests per IP per 24h |
| Address rate limit | 1 request per address per 24h |
| Captcha | Required on web faucet |
| Minimum account age | Discord account > 24h old (if bot used) |
| Blacklist | Manual blacklist for known abusers |
| Faucet balance alert | Alert if faucet balance < 10% of initial |

## Security Risks

| Risk | Mitigation |
|---|---|
| Faucet key compromise | Dedicated faucet account, not shared with validator keys. Low-value testnet tokens. |
| Sybil attacks | Rate limits + captcha limit mass requests |
| Transaction spam | Faucet sends small amounts, network can handle |
| Faucet drain | Lifetime per-address limit prevents accumulation |

## Logs

Faucet should log:
- Timestamp
- Requester address
- IP (hashed)
- Amount sent
- Transaction hash
- Captcha result

Logs retained for 30 days. Not publicly accessible.

## Testnet-Only Disclaimer

All tokens distributed by the faucet are testnet-only with **no monetary value**. They cannot be transferred to mainnet, sold, or exchanged. The testnet may be reset at any time, wiping all balances.
