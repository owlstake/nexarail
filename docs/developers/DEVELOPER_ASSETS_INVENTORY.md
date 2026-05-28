# Developer Assets Inventory

Every major deliverable in the NexaRail RC1 developer package, with path and purpose.

## Release Package
| Asset | Path | Purpose |
|---|---|---|
| RC1 binaries | `releases/testnet-rc1/binaries/` | Prebuilt nexaraild for macOS ARM64 and Linux AMD64 |
| RC1 genesis | `releases/testnet-rc1/genesis/` | Devnet genesis files |
| RC1 verification | `scripts/release/verify-testnet-rc1.sh` | 37/37 checks pass |

## Developer Scripts
| Asset | Path | Purpose |
|---|---|---|
| Devnet launcher | `scripts/release/launch-rc1-devnet.sh` | Launch single-node or five-agent devnet |
| Local demo | `scripts/dev/run-local-demo.sh` | Quick devnet walkthrough |
| End-to-end demo | `scripts/dev/run-end-to-end-demo.sh` | Full developer demo (10 checks) |
| Regression matrix | `scripts/dev/run-nexarail-regression-matrix.sh` | Fast (9 checks) or full mode |
| SDK package check | `scripts/dev/check-sdk-packages.sh` | 24 SDK safety/completeness checks |
| SDK local package | `scripts/dev/package-sdk-local.sh` | Create local SDK archives |
| Dashboard check | `scripts/dev/check-dashboard-files.sh` | 21 dashboard file assertions |
| Local demo script check | `scripts/dev/check-local-demo-script.sh` | 36 demo safety checks |
| Developer bundle | `scripts/dev/prepare-developer-bundle.sh` | Create onboarding archive |
| Portal build | `scripts/dev/build-developer-portal.sh` | Build static developer portal |
| Portal serve | `scripts/dev/serve-developer-portal.sh` | Serve portal on localhost:8090 |
| Portal check | `scripts/dev/check-developer-portal.sh` | 6 portal checks |

## Developer Documentation
| Asset | Path | Purpose |
|---|---|---|
| Developer quickstart | `docs/developers/DEVELOPER_QUICKSTART.md` | Getting started guide |
| Local demo guide | `docs/developers/LOCAL_DEMO_GUIDE.md` | Demo walkthrough |
| API examples | `docs/developers/API_EXAMPLES.md` | REST API usage examples |
| REST readback routes | `docs/api/REST_READBACK_ROUTES.md` | All 36 endpoint docs |
| SDK package preparation | `docs/developers/SDK_PACKAGE_PREPARATION.md` | SDK status, version, packaging |
| SDK RC1 release notes | `docs/developers/SDK_RC1_RELEASE_NOTES.md` | Release notes for devnet SDK |
| Node SDK API reference | `docs/developers/NODE_SDK_API_REFERENCE.md` | Full Node.js API docs (18 functions) |
| Python SDK API reference | `docs/developers/PYTHON_SDK_API_REFERENCE.md` | Full Python API docs (18 functions) |
| SDK recipes | `docs/developers/SDK_RECIPES.md` | 10 practical SDK recipes |
| End-to-end scenario | `docs/developers/END_TO_END_DEMO_SCENARIO.md` | Demo scenario doc |
| End-to-end summary | `docs/developers/END_TO_END_DEMO_SUMMARY.md` | Reviewer-friendly summary |
| Developer portal | `docs/portal/index.html` | Browsable dev portal (19 sections) |
| CI checks reference | `docs/release/RC1_CI_CHECKS.md` | CI check details and frequency |
| Regression matrix | `docs/developers/DEMO_REGRESSION_MATRIX.md` | Fast/full regression details |

## Examples
| Asset | Path | Purpose |
|---|---|---|
| REST examples | `examples/rest/` | 7 scripts covering 36 endpoints |
| Node.js SDK | `examples/node-client/` | Full SDK client with tests |
| Python SDK | `examples/python-client/` | Full SDK client with tests |
| Dashboard | `examples/dashboard/` | Read-only static dashboard |
| Write-flow examples | `examples/write-flows/` | 7 dry-run-safe CLI command builders |

## SDK Packages (Local Only — NOT Published)
| Asset | Path | Version |
|---|---|---|
| Node SDK archive | `releases/sdk-local/nexarail-node-devnet-client-0.1.0-dev.tgz` | 0.1.0-dev |
| Python SDK archive | `releases/sdk-local/nexarail-python-devnet-client-0.1.0-dev.tar.gz` | 0.1.0-dev |
| SDK manifest | `releases/sdk-local/manifest.json` | 0.1.0-dev |

## Archives
| Asset | Path | Contents |
|---|---|---|
| Developer bundle | `releases/developer-bundles/nexarail-developer-bundle-<timestamp>.tar.gz` | All docs, examples, scripts, SDKs, portal |
| Bundle manifest | `releases/developer-bundles/manifest-<timestamp>.json` | Bundle metadata |

## Contributing
| Asset | Path | Purpose |
|---|---|---|
| Contributing guide | `CONTRIBUTING.md` | Standards, workflow, prohibitions |
| Onboarding checklist | `docs/developers/ONBOARDING_CHECKLIST.md` | 13-step dev onboarding |
| Contributor testing | `docs/developers/CONTRIBUTOR_TESTING_GUIDE.md` | Expected pass counts, troubleshooting |
| PR template | `.github/pull_request_template.md` | PR checklist |
| Issue templates | `.github/ISSUE_TEMPLATE/` | Bug, feedback, SDK example templates |

## CI
| Asset | Path | Purpose |
|---|---|---|
| CI workflow | `.github/workflows/nexarail-regression.yml` | GitHub Actions (CI-safe checks) |

## Evidence
Evidence paths (generated on each run):
- `rehearsals/regression-matrix/evidence/<timestamp>/`
- `rehearsals/end-to-end-demo/evidence/<timestamp>/`

## Safety Notes
- All assets are LOCAL DEVNET ONLY — NOT MAINNET
- SDK packages are NOT published to npm or PyPI
- All `live_enabled` flags must remain `false` for local devnet
- No private keys, mnemonics, or seed phrases in any deliverable
