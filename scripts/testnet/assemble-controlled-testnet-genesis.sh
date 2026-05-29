#!/usr/bin/env bash
# Assemble a controlled external-validator testnet genesis from verified gentxs.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
DENOM="${NEXARAIL_DENOM:-unxrl}"
GENTX_DIR="${GENTX_DIR:-$PROJECT_DIR/rehearsals/testnet-1/gentx-collection/final}"
OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_DIR/releases/testnet-genesis/$CHAIN_ID}"
ACCOUNT_AMOUNT="${ACCOUNT_AMOUNT:-1000000000000unxrl}"
GOV_VOTING_PERIOD="${GOV_VOTING_PERIOD:-300s}"
GOV_MAX_DEPOSIT_PERIOD="${GOV_MAX_DEPOSIT_PERIOD:-600s}"
GOV_MIN_DEPOSIT="${GOV_MIN_DEPOSIT:-1000000unxrl}"
VERIFY_GENTXS=1
KEEP_WORK=0

usage() {
    cat <<EOF
Usage: scripts/testnet/assemble-controlled-testnet-genesis.sh [options]

Options:
  --gentx-dir <dir>       directory containing verified gentx JSON files
  --output-dir <dir>      output directory (default: releases/testnet-genesis/$CHAIN_ID)
  --binary <path>         nexaraild binary path
  --chain-id <id>         chain ID (default: $CHAIN_ID)
  --denom <denom>         staking denom (default: $DENOM)
  --account-amount <amt>  genesis account funding for gentx delegators (default: $ACCOUNT_AMOUNT)
  --skip-verify           skip per-gentx verification script
  --keep-work             keep temporary work home for debugging
  -h, --help              show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --gentx-dir) GENTX_DIR="$2"; shift 2 ;;
        --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
        --binary) BINARY="$2"; shift 2 ;;
        --chain-id) CHAIN_ID="$2"; shift 2 ;;
        --denom) DENOM="$2"; shift 2 ;;
        --account-amount) ACCOUNT_AMOUNT="$2"; shift 2 ;;
        --skip-verify) VERIFY_GENTXS=0; shift ;;
        --keep-work) KEEP_WORK=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ ! -x "$BINARY" ]; then
    echo "Binary not found or not executable: $BINARY" >&2
    echo "Run: make build" >&2
    exit 1
fi

if [ ! -d "$GENTX_DIR" ]; then
    echo "Gentx directory not found: $GENTX_DIR" >&2
    exit 1
fi

GENTXS=()
while IFS= read -r gentx_file; do
    GENTXS+=("$gentx_file")
done < <(find "$GENTX_DIR" -maxdepth 1 -type f -name '*.json' | sort)
if [ "${#GENTXS[@]}" -eq 0 ]; then
    echo "No gentx JSON files found in: $GENTX_DIR" >&2
    exit 1
fi

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

WORK_HOME="$(mktemp -d)"
cleanup() {
    if [ "$KEEP_WORK" -eq 1 ]; then
        echo "Work home retained: $WORK_HOME"
    else
        rm -rf "$WORK_HOME"
    fi
}
trap cleanup EXIT

echo "Controlled testnet genesis assembly"
echo "Chain ID: $CHAIN_ID"
echo "Gentx dir: $GENTX_DIR"
echo "Output dir: $OUTPUT_DIR"
echo "Gentx count: ${#GENTXS[@]}"
echo ""

if [ "$VERIFY_GENTXS" -eq 1 ]; then
    echo "Verifying gentxs"
    for gentx in "${GENTXS[@]}"; do
        "$PROJECT_DIR/scripts/testnet/verify-controlled-testnet-gentx.sh" \
            "$gentx" --binary "$BINARY" --chain-id "$CHAIN_ID" --denom "$DENOM" >/dev/null
        echo "PASS $(basename "$gentx")"
    done
    echo ""
fi

"$BINARY" init controlled-testnet-coordinator --chain-id "$CHAIN_ID" --home "$WORK_HOME" --overwrite >/dev/null 2>&1

python3 - "$WORK_HOME/config/genesis.json" "$CHAIN_ID" "$DENOM" "$GOV_VOTING_PERIOD" "$GOV_MAX_DEPOSIT_PERIOD" "$GOV_MIN_DEPOSIT" <<'PY'
import json
import sys

path, chain_id, denom, voting, deposit_period, min_deposit = sys.argv[1:7]
amount = ''.join(ch for ch in min_deposit if ch.isdigit())
min_denom = min_deposit[len(amount):] or denom

with open(path) as f:
    genesis = json.load(f)

genesis["chain_id"] = chain_id
app = genesis.setdefault("app_state", {})
app.setdefault("staking", {}).setdefault("params", {})["bond_denom"] = denom
app.setdefault("crisis", {}).setdefault("constant_fee", {})["denom"] = denom
app.setdefault("mint", {}).setdefault("params", {})["mint_denom"] = denom

gov = app.setdefault("gov", {})
params = gov.setdefault("params", {})
params["voting_period"] = voting
params["max_deposit_period"] = deposit_period
params["min_deposit"] = [{"denom": min_denom, "amount": amount or "1000000"}]
if "voting_params" in gov and gov["voting_params"] is not None:
    gov["voting_params"]["voting_period"] = voting
if "deposit_params" in gov and gov["deposit_params"] is not None:
    gov["deposit_params"]["max_deposit_period"] = deposit_period
    gov["deposit_params"]["min_deposit"] = [{"denom": min_denom, "amount": amount or "1000000"}]

settlement = app.setdefault("settlement", {}).setdefault("params", {})
settlement["live_enabled"] = False
settlement["treasury_routing_enabled"] = False
settlement["burn_routing_enabled"] = False
for module in ("escrow", "treasury", "payout"):
    app.setdefault(module, {}).setdefault("params", {})["live_enabled"] = False

with open(path, "w") as f:
    json.dump(genesis, f, indent=2, sort_keys=True)
    f.write("\n")
PY

SEEN_ACCOUNTS_FILE="$WORK_HOME/seen-accounts.txt"
: > "$SEEN_ACCOUNTS_FILE"
for gentx in "${GENTXS[@]}"; do
    delegator="$(python3 - "$gentx" <<'PY'
import json
import sys
with open(sys.argv[1]) as f:
    g = json.load(f)
print(g["body"]["messages"][0].get("delegator_address", ""))
PY
)"
    if [ -z "$delegator" ]; then
        echo "Missing delegator_address in $(basename "$gentx")" >&2
        exit 1
    fi
    if ! grep -Fxq "$delegator" "$SEEN_ACCOUNTS_FILE"; then
        "$BINARY" add-genesis-account "$delegator" "$ACCOUNT_AMOUNT" --home "$WORK_HOME" >/dev/null
        printf '%s\n' "$delegator" >> "$SEEN_ACCOUNTS_FILE"
    fi
done

mkdir -p "$WORK_HOME/config/gentx"
cp "${GENTXS[@]}" "$WORK_HOME/config/gentx/"
"$BINARY" collect-gentxs --home "$WORK_HOME" --gentx-dir "$WORK_HOME/config/gentx" >/dev/null

COLLECTED="$(python3 - "$WORK_HOME/config/genesis.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as f:
    g = json.load(f)
print(len(g["app_state"]["genutil"]["gen_txs"]))
PY
)"
if [ "$COLLECTED" != "${#GENTXS[@]}" ]; then
    echo "Collected gentx mismatch: collected=$COLLECTED expected=${#GENTXS[@]}" >&2
    exit 1
fi

"$BINARY" validate-genesis --home "$WORK_HOME" >/dev/null

python3 - "$WORK_HOME/config/genesis.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as f:
    g = json.load(f)
app = g.get("app_state", {})
checks = [
    ("settlement.live_enabled", app.get("settlement", {}).get("params", {}).get("live_enabled")),
    ("settlement.treasury_routing_enabled", app.get("settlement", {}).get("params", {}).get("treasury_routing_enabled")),
    ("settlement.burn_routing_enabled", app.get("settlement", {}).get("params", {}).get("burn_routing_enabled")),
    ("escrow.live_enabled", app.get("escrow", {}).get("params", {}).get("live_enabled")),
    ("treasury.live_enabled", app.get("treasury", {}).get("params", {}).get("live_enabled")),
    ("payout.live_enabled", app.get("payout", {}).get("params", {}).get("live_enabled")),
]
bad = [(name, value) for name, value in checks if value is not False]
if bad:
    for name, value in bad:
        print(f"{name}={value}", file=sys.stderr)
    sys.exit(1)
PY

mkdir -p "$OUTPUT_DIR"
cp "$WORK_HOME/config/genesis.json" "$OUTPUT_DIR/genesis.json"
GENESIS_SHA="$(sha256_file "$OUTPUT_DIR/genesis.json")"
printf '%s  genesis.json\n' "$GENESIS_SHA" > "$OUTPUT_DIR/SHA256SUMS"

cat > "$OUTPUT_DIR/manifest.json" <<EOF
{
  "network": "$CHAIN_ID",
  "status": "controlled-testnet-genesis-candidate",
  "generated_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "source_ref": "$(git -C "$PROJECT_DIR" describe --tags --always --dirty 2>/dev/null || echo unknown)",
  "gentx_count": $COLLECTED,
  "genesis_sha256": "$GENESIS_SHA",
  "denom": "$DENOM",
  "account_amount": "$ACCOUNT_AMOUNT",
  "gov_voting_period": "$GOV_VOTING_PERIOD",
  "product_live_flags": "false",
  "safety": "testnet only; not mainnet; no token sale; no monetary value"
}
EOF

if grep -Eirq 'priv_key|private_key|mnemonic|seed phrase|seed_phrase|node_key|priv_validator|BEGIN (RSA|EC|OPENSSH|PRIVATE)' "$OUTPUT_DIR"; then
    echo "Unsafe private material pattern found in output directory" >&2
    exit 1
fi

echo "Genesis assembly complete"
echo "Genesis: $OUTPUT_DIR/genesis.json"
echo "SHA256: $GENESIS_SHA"
echo "Manifest: $OUTPUT_DIR/manifest.json"
