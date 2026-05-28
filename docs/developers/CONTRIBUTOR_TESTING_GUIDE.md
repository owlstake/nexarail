# Contributor Testing Guide

## Fast Checks (No Devnet Needed)

Run before every PR:

```bash
bash scripts/dev/run-nexarail-regression-matrix.sh --fast
```

### Expected: 8 PASS / 0 FAIL

| Check | What It Verifies |
|---|---|
| go_mod_verify | Go module integrity |
| go_build | Full Go compilation |
| go_test | All Go unit tests |
| predeployment_check | 23 Go module + chain config checks |
| rc1_verify | 37 RC1 packaging verifications |
| dashboard_files_check | 21 dashboard file assertions |
| local_demo_script_check | 36 local demo safety checks |
| sdk_package_check | 24 SDK package safety/completeness checks |

## Full Checks (With Running Devnet)

```bash
bash scripts/dev/run-nexarail-regression-matrix.sh --full --with-devnet
```

Additional checks: launch devnet, developer smoke, write-flow smoke, local demo, SDK local packaging, end-to-end demo.

## Developer Portal

Build and check the portal:

```bash
bash scripts/dev/build-developer-portal.sh
bash scripts/dev/check-developer-portal.sh
```

### Expected: 6 PASS / 0 FAIL

## SDK Package Checks

```bash
bash scripts/dev/check-sdk-packages.sh
```

### Expected: 24 PASS / 0 FAIL

Checks Node and Python package metadata, version consistency, tests, forbidden wording, private-key/mnemonic scan, safety disclaimers, API reference docs, recipes, local archives, manifest, and checksums.

## End-to-End Demo

```bash
bash scripts/dev/run-end-to-end-demo.sh
```

### Expected: 10+ PASS / 0 FAIL

RC1 verification, devnet launch, height check, live flags (all false), REST examples, Node SDK, Python SDK, write-flow syntax, SDK command builders, dashboard (optional).

## Dashboard Check

```bash
bash scripts/dev/check-dashboard-files.sh
```

### Expected: 21 PASS / 0 FAIL

## Local Demo Check

```bash
bash scripts/dev/check-local-demo-script.sh
```

### Expected: 36 PASS / 0 FAIL

## Evidence Paths

| Test | Evidence Dir |
|---|---|
| Fast regression | `rehearsals/regression-matrix/evidence/<timestamp>/` |
| Full regression | `rehearsals/regression-matrix/evidence/<timestamp>/` |
| SDK packaging | `releases/sdk-local/` |
| End-to-end demo | `rehearsals/end-to-end-demo/evidence/<timestamp>/` |
| Developer bundle | `releases/developer-bundles/` |

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Devnet fails to launch | Port 26657 in use | Stop other nexaraild or kill SSH tunnel |
| Height not progressing | Node not started | Check log at `rehearsals/rc1-devnet/logs/` |
| REST API not responding | REST not enabled | Run devnet with `--api.enable` (default in launch script) |
| Node tests fail | Node.js version < 18 | Install Node.js 18+ |
| Python tests fail | Python < 3.9 | Install Python 3.9+ |
| SDK check failures | Missing docs or archives | Run `scripts/dev/package-sdk-local.sh` first |
