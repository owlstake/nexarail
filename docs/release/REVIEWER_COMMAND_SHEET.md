# NexaRail RC1 — Reviewer Command Sheet

## Clone & Tag
```bash
git clone https://github.com/Bookings-cpu/nexarail.git
cd nexarail
git checkout v0.1.0-rc1
```

## Download Binaries
Download `nexaraild-linux-amd64` and `nexaraild-darwin-arm64` from the GitHub Release page.
Place in `releases/testnet-rc1/binaries/`.

## Verify Checksums
```bash
cd releases/testnet-rc1
shasum -a 256 -c checksums/SHA256SUMS
```

## Validator CLI Node ID Check
Pre-hotfix RC1 binaries are missing the `tendermint`/`comet` helper group required for validator onboarding. Use the patched binary set under `releases/github/v0.1.0-rc1-hotfix-cli/` (`v0.1.0-rc1-cli-hotfix`):
```bash
cd releases/github/v0.1.0-rc1-hotfix-cli
shasum -a 256 -c SHA256SUMS
./nexaraild-darwin-arm64 tendermint --help            # expect: show-node-id listed
HOTFIX_HOME="$(mktemp -d)"
./nexaraild-darwin-arm64 init reviewer --chain-id nexarail-devnet-1 --home "$HOTFIX_HOME"
./nexaraild-darwin-arm64 tendermint show-node-id --home "$HOTFIX_HOME"
./nexaraild-darwin-arm64 comet show-node-id --home "$HOTFIX_HOME"
```
Expected: both commands print the same 40-char hex node ID. See `docs/release/VALIDATOR_CLI_HOTFIX_NOTES.md`.

## Verify RC1 Package
```bash
bash scripts/release/verify-testnet-rc1.sh
```
Expected: 37/37 pass

## Fast Regression (No Binaries Needed)
```bash
bash scripts/dev/run-nexarail-regression-matrix.sh --fast
```
Expected: 9/9 pass

## Launch Local Devnet
```bash
bash scripts/release/launch-rc1-devnet.sh --single-node --clean
```

## Query Live Flags
```bash
curl -s http://localhost:1317/nexarail/settlement/v1/params | python3 -m json.tool
```
Expected: `live_enabled: false`

## Run Local Demo
```bash
bash scripts/dev/run-local-demo.sh
```

## Run End-to-End Demo
```bash
bash scripts/dev/run-end-to-end-demo.sh --skip-dashboard
```
Expected: 10/10 pass

## Check SDKs
```bash
bash scripts/dev/check-sdk-packages.sh
```
Expected: 24/24 pass

## Build Developer Portal
```bash
bash scripts/dev/build-developer-portal.sh
bash scripts/dev/check-developer-portal.sh
# Open: site/developer-portal/index.html
```

## Serve Portal
```bash
bash scripts/dev/serve-developer-portal.sh
# Open: http://localhost:8090
```

## Test Node.js SDK
```bash
cd examples/node-client
node test/client.test.js
```

## Test Python SDK
```bash
cd examples/python-client
python3 test_client.py
```

## Stop Devnet
```bash
scripts/release/launch-rc1-devnet.sh --stop
```

## Clean Up Devnet State
```bash
rm -rf ~/.nexarail-devnet
```

## Prepare Developer Bundle
```bash
bash scripts/dev/prepare-developer-bundle.sh
```
Output: `releases/developer-bundles/`
