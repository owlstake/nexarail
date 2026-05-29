# Validator Intake Template

**Network:** `nexarail-testnet-1`
**Status:** controlled external-validator testnet candidate

Submit one completed record per validator. Do not include secrets, key files, node data, account mnemonics, SSH keys, or private infrastructure notes.

## Markdown Template

```markdown
## Validator Intake

- Moniker:
- Contact handle:
- Operator address:
- Account address:
- Node ID:
- Public IP or DNS:
- P2P port:
- Gentx filename:
- Gentx SHA256:
- Build commit/tag:
- OS/arch:
- Sentry/validator layout used: yes/no
- Sentry details, if yes:

## Acknowledgement

- I understand this is a testnet-only infrastructure exercise.
- I understand testnet denominations have no monetary value.
- I understand this is not mainnet and not a token sale.
- I will not share account mnemonics, private keys, node keys, validator signing keys, keyrings, SSH keys, or node data directories.
- I can be present during the launch window and first-hour validation.
```

## CSV Header

Use this header if submitting intake as CSV:

```csv
moniker,contact_handle,operator_address,account_address,node_id,public_ip_or_dns,p2p_port,gentx_filename,gentx_sha256,build_commit_or_tag,os_arch,sentry_layout,ack_testnet_only
```

## Field Requirements

| Field | Required | Notes |
|---|---|---|
| `moniker` | yes | Must match the gentx validator description. |
| `contact_handle` | yes | Support-channel handle or direct contact approved by the coordinator. |
| `operator_address` | yes | `nxrvaloper...` address from the gentx. |
| `account_address` | yes | `nxr...` account used to create the gentx. |
| `node_id` | yes | Output of `nexaraild tendermint show-node-id`. |
| `public_ip_or_dns` | yes | Public host peers can dial. |
| `p2p_port` | yes | Default `26656` unless coordinated otherwise. |
| `gentx_filename` | yes | File name only, not a path containing local secrets. |
| `gentx_sha256` | yes | SHA256 of the submitted gentx file. |
| `build_commit_or_tag` | yes | Use `v0.1.0-rc1-cli-hotfix` or a later approved commit/tag. |
| `os_arch` | yes | Example: `ubuntu-22.04/amd64`. |
| `sentry_layout` | yes | `yes` or `no`; include public sentry host if applicable. |
| `ack_testnet_only` | yes | Must be `yes`. |
