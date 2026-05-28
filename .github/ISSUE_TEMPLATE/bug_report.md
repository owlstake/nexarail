---
name: Bug Report
about: Report a bug in the NexaRail chain, SDK, or developer tooling
title: '[Bug] '
labels: bug
assignees: ''
---

## Describe the Bug

A clear and concise description of the bug.

## To Reproduce

Steps to reproduce:

1. Run `...`
2. See error

## Expected Behavior

What should have happened.

## Environment

- OS: [e.g. macOS 15.4 ARM64]
- Go version: `go version`
- Node.js version: `node --version`
- Python version: `python3 --version`
- RC1 binary SHA256: `shasum -a 256 releases/testnet-rc1/binaries/nexaraild-*`
- Devnet mode: [single-node / five-agent]

## Evidence

- Error output or log file path:
- Regression check results (if applicable):
- Evidence directory (if applicable):

## Safety

- [ ] This bug report does not contain private keys, mnemonics, or seed phrases
- [ ] This bug report does not claim mainnet is live or NXRL is buyable

## Checklist Before Submitting

- [ ] I have run `scripts/dev/run-nexarail-regression-matrix.sh --fast` (if applicable)
- [ ] I have verified the bug on a clean devnet (`--clean` flag)
