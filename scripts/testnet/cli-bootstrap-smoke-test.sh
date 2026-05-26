#!/usr/bin/env bash
# NexaRail CLI Bootstrap Smoke Test
# Verifies bootstrap commands work with a fresh home directory.
set -euo pipefail

BINARY="./build/nexaraild"
CHAIN_ID="nexarail-testnet-1"
TMP_HOME=$(mktemp -d)
PASS=0
FAIL=0

check() { echo -n "  $1 ... "; if "${@:2}" 2>/dev/null; then echo "✅"; ((PASS++)); else echo "❌"; ((FAIL++)); fi }

echo "=== NexaRail CLI Bootstrap Smoke Test ==="
echo "Chain: $CHAIN_ID"
echo "Home:  $TMP_HOME"
echo ""

# 1. Init
check "init creates genesis" ./build/nexaraild init smokeval --chain-id "$CHAIN_ID" --home "$TMP_HOME" >/dev/null 2>&1
check "genesis.json exists" test -f "$TMP_HOME/config/genesis.json"
check "node_key.json exists" test -f "$TMP_HOME/config/node_key.json"
check "priv_validator_key.json exists" test -f "$TMP_HOME/config/priv_validator_key.json"

# 2. Chain ID in genesis
check "chain ID in genesis" grep -q "\"chain_id\":\"$CHAIN_ID\"" "$TMP_HOME/config/genesis.json"

# 3. Live flags default false
check "settlement live_enabled false" grep -q '"live_enabled":false' "$TMP_HOME/config/genesis.json"
check "settlement treasury_routing false" grep -q '"treasury_routing_enabled":false' "$TMP_HOME/config/genesis.json"
check "settlement burn_routing false" grep -q '"burn_routing_enabled":false' "$TMP_HOME/config/genesis.json"
check "escrow live_enabled false" grep -q '"escrow".*"live_enabled":false' "$TMP_HOME/config/genesis.json"
check "treasury live_enabled false" grep -q '"treasury".*"live_enabled":false' "$TMP_HOME/config/genesis.json"
check "payout live_enabled false" grep -q '"payout".*"live_enabled":false' "$TMP_HOME/config/genesis.json"

# 4. Custom modules in genesis
check "fees module in genesis" grep -q '"fees"' "$TMP_HOME/config/genesis.json"
check "merchant module in genesis" grep -q '"merchant"' "$TMP_HOME/config/genesis.json"
check "settlement module in genesis" grep -q '"settlement"' "$TMP_HOME/config/genesis.json"
check "escrow module in genesis" grep -q '"escrow"' "$TMP_HOME/config/genesis.json"
check "payout module in genesis" grep -q '"payout"' "$TMP_HOME/config/genesis.json"
check "treasury module in genesis" grep -q '"treasury"' "$TMP_HOME/config/genesis.json"

# 5. Validate genesis
check "validate-genesis passes" ./build/nexaraild validate-genesis --home "$TMP_HOME" >/dev/null 2>&1

# 6. Help commands
check "nexaraild --help" ./build/nexaraild --help >/dev/null 2>&1
check "nexaraild query --help" ./build/nexaraild query --help >/dev/null 2>&1
check "nexaraild tx --help" ./build/nexaraild tx --help >/dev/null 2>&1
check "nexaraild keys --help" ./build/nexaraild keys --help >/dev/null 2>&1

# 7. Denom in genesis
check "unxrl in genesis" grep -q '"unxrl"' "$TMP_HOME/config/genesis.json"

# Summary
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
if [ "$FAIL" -eq 0 ]; then
    echo "✅ All CLI bootstrap smoke tests passed"
else
    echo "❌ $FAIL test(s) failed"
fi

# Cleanup
rm -rf "$TMP_HOME"
