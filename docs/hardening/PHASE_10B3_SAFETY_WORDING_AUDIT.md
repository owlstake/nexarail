# Phase 10B.3 Safety Wording Audit

**Date:** 2026-05-28
**Scope:** Read-only audit of project docs and code for prohibited promotional/financial claims
**Boundary:** No changes made to any file

## Search Parameters

Searched all `.md`, `.go`, `.sh`, `.json` files in the project tree (excluding `node_modules/` and `.git/`).

### Terms Searched

| Term | Category |
|---|---|
| `decentralized` / `decentralised` | False claims about validator independence |
| `independent validators` | False claims about validator autonomy |
| `external validators` | False claims about external participation |
| `mainnet live` | False claims about launch status |
| `buy NXRL` | Unauthorised token sale claims |
| `token sale` | Unauthorised token sale claims |
| `investment` | Investment/security framing |
| `guaranteed` | Guaranteed returns/value claims |
| `profit` | Profit claims |
| `APY` | Yield claims |
| `returns` | Return claims |
| `price` | Token price claims (promotional context) |
| `listing` | Exchange listing claims (promotional context) |

## Findings

### `decentralized` / `decentralised`

No positive claims found. The one occurrence (`docs/testnet/AGENT_TESTNET_LIMITATIONS.md`) describes why the current setup is NOT decentralised.

### `independent validators`

No occurrences found.

### `external validators`

Multiple occurrences throughout `docs/testnet/`. All are either:
- Checklist items describing future plans
- Explicit prohibitions ("Do NOT invite external validators yet")
- Status notes ("external validators remain pending")

No positive claim that external validators are live.

### `mainnet live`

No positive claims found. All references are negative/qualified.

### `buy NXRL`

No occurrences found.

### `token sale`

Multiple occurrences, all explicitly stating "no token sale" or "token sale has not occurred".

### `investment`

Multiple occurrences, all explicitly disclaiming "this is not an investment". No positive framing.

### `guaranteed`

No occurrences found.

### `profit`

No positive claims found. The term appears only in technical/error handling contexts (e.g. "returns profit" as a function name).

### `APY`

No occurrences found.

### `returns`

Appears only in technical/function-name contexts (e.g. "returns the value", "handler returns error"). No financial/ROI claims.

### `price`

Appears in technical contexts only: price of gas, no price decisions, release price. No promotional token price claims.

### `listing`

Appears in checklist/documentation improvement listing contexts only. No exchange listing claims.

## Phase 10B.4 Re-audit

Re-audited on 2026-05-28 for Phase 10B.4 finalisation. Results unchanged from Phase 10B.3 audit.

### Additional Checks

Checked new files created in 10B.4:
- `docs/api/REST_READBACK_ROUTES.md` — No promotional/financial language
- `docs/api/REST_READBACK_LIMITATIONS.md` — No promotional/financial language
- `docs/hardening/PHASE_10B_PRODUCT_FLOW_READINESS_FINAL.md` — No promotional/financial language

### FAQ Verification

- `FAQ.md` "Can I buy NXRL?" — Answer: "No." Correctly states tokens have zero monetary value, no sale mechanism exists.
- `FAQ.md` "Will there be a token sale?" — Answer: no token sale has been announced, planned, or committed.

## Verdict

**PASS** — No prohibited claims found.

All references to checked terms are:
- Negative/qualified (e.g. "no token sale")
- Technical/functional (e.g. "function returns value")
- Compliance disclaimers (e.g. "not an investment")
- Future-plans acknowledgements (e.g. "external validators remain pending")
