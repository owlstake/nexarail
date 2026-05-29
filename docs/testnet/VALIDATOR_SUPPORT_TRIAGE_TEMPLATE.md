# Validator Support Triage Template

**Network:** `nexarail-testnet-1`
**Status:** support template; controlled testnet preparation

Use one copy per validator issue. Do not include private keys, mnemonics, node keys, validator signing keys, keyring files, SSH keys, node data, database files, or unsanitized private contact details.

| Field | Value |
|---|---|
| Validator moniker |  |
| Issue category |  |
| Time UTC |  |
| Binary/tag |  |
| Genesis hash |  |
| Node ID |  |
| Peer count |  |
| Latest height |  |
| catching_up |  |
| RPC status |  |
| Relevant sanitized logs excerpt |  |
| Action taken |  |
| Status |  |
| Follow-up required |  |

## Issue Categories

- genesis checksum mismatch
- wrong binary/tag
- peer connectivity
- missing from validator set
- catching_up
- validator signing
- REST/RPC unavailable
- consensus halt
- live-flag mismatch
- evidence/log collection
- other

## Safe Log Handling

Paste only minimal sanitized excerpts. Remove secrets, private infrastructure notes, unnecessary IPs if requested by the operator, and any key material. The coordinator will never request mnemonics or validator signing keys.

## Status Values

- OPEN
- WAITING_ON_VALIDATOR
- WAITING_ON_COORDINATOR
- MITIGATED
- CLOSED
- ESCALATED
