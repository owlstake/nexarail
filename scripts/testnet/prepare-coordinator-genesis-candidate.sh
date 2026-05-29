#!/usr/bin/env bash
# Build an internal coordinator-only genesis candidate from local coordinator validators.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
DENOM="${NEXARAIL_DENOM:-unxrl}"
TIMESTAMP="${COORDINATOR_CANDIDATE_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_ROOT="${COORDINATOR_CANDIDATE_RUN_ROOT:-$PROJECT_DIR/rehearsals/coordinator-candidate/runs}"
RUN_DIR="$RUN_ROOT/$TIMESTAMP"
HOMES_DIR="$RUN_DIR/homes"
GENTX_DIR="$RUN_DIR/gentxs"
OUTPUT_DIR="${COORDINATOR_CANDIDATE_OUTPUT_DIR:-$PROJECT_DIR/releases/testnet-genesis/coordinator-candidate}"
ACCOUNT_AMOUNT="${ACCOUNT_AMOUNT:-1000000000000unxrl}"
SELF_DELEGATION="${SELF_DELEGATION:-500000000unxrl}"
CANDIDATE_MARKER="INTERNAL COORDINATOR CANDIDATE — NOT FINAL PUBLIC GENESIS"

AGENTS=(
    "alpha:nxrl-controlled-alpha:31657:31656:1517:9290"
    "bravo:nxrl-controlled-bravo:31667:31666:1518:9291"
    "charlie:nxrl-controlled-charlie:31677:31676:1519:9292"
    "delta:nxrl-controlled-delta:31687:31686:1520:9293"
    "echo:nxrl-controlled-echo:31697:31696:1521:9294"
)

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

relative_to_project() {
    case "$1" in
        "$PROJECT_DIR"/*)
            printf '%s\n' "${1#"$PROJECT_DIR"/}"
            ;;
        "$PROJECT_DIR")
            printf '.\n'
            ;;
        *)
            printf '%s\n' "$1"
            ;;
    esac
}

json_param_update() {
    python3 - "$1" "$CHAIN_ID" "$DENOM" <<'PY'
import json
import sys

path, chain_id, denom = sys.argv[1:4]
with open(path) as f:
    genesis = json.load(f)
genesis["chain_id"] = chain_id
app = genesis.setdefault("app_state", {})
app.setdefault("staking", {}).setdefault("params", {})["bond_denom"] = denom
app.setdefault("crisis", {}).setdefault("constant_fee", {})["denom"] = denom
app.setdefault("mint", {}).setdefault("params", {})["mint_denom"] = denom
gov = app.setdefault("gov", {}).setdefault("params", {})
gov["voting_period"] = "300s"
gov["max_deposit_period"] = "600s"
gov["min_deposit"] = [{"denom": denom, "amount": "1000000"}]
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
}

assert_live_flags_false() {
    python3 - "$1" <<'PY'
import json
import sys

with open(sys.argv[1]) as f:
    genesis = json.load(f)
app = genesis.get("app_state", {})
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
}

mark_candidate_manifest() {
    python3 - "$1" "$CANDIDATE_MARKER" <<'PY'
import json
import sys

path, marker = sys.argv[1:3]
with open(path) as f:
    manifest = json.load(f)
manifest["status"] = marker
manifest["final_public_genesis"] = False
manifest["safety"] = "internal coordinator candidate only; not mainnet; not a public launch; no token sale; no monetary value"
with open(path, "w") as f:
    json.dump(manifest, f, indent=2, sort_keys=True)
    f.write("\n")
PY
}

if [ ! -x "$BINARY" ]; then
    make -C "$PROJECT_DIR" build
fi

mkdir -p "$HOMES_DIR" "$GENTX_DIR" "$OUTPUT_DIR"

echo "Internal coordinator genesis candidate"
echo "Chain ID: $CHAIN_ID"
echo "Run dir: $RUN_DIR"
echo "Output dir: $OUTPUT_DIR"
echo "Status: $CANDIDATE_MARKER"

BASE_HOME="$HOMES_DIR/alpha"

account_file() {
    printf '%s/%s-account-address.txt' "$RUN_DIR" "$1"
}

node_file() {
    printf '%s/%s-node-id.txt' "$RUN_DIR" "$1"
}

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker _rpc _p2p _api _grpc <<< "$agent"
    home="$HOMES_DIR/$name"
    mkdir -p "$home"
    "$BINARY" init "$moniker" --chain-id "$CHAIN_ID" --home "$home" --overwrite > "$RUN_DIR/${name}-init.log" 2>&1
    "$BINARY" keys add "${name}-key" --keyring-backend test --home "$home" > "$RUN_DIR/${name}-keys-add.log" 2>&1
    "$BINARY" keys show "${name}-key" -a --keyring-backend test --home "$home" > "$(account_file "$name")"
    "$BINARY" tendermint show-node-id --home "$home" > "$(node_file "$name")"
done

json_param_update "$BASE_HOME/config/genesis.json"

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name _moniker _rpc _p2p _api _grpc <<< "$agent"
    "$BINARY" add-genesis-account "$(cat "$(account_file "$name")")" "$ACCOUNT_AMOUNT" --home "$BASE_HOME" >> "$RUN_DIR/add-genesis-accounts.log" 2>&1
done

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker _rpc _p2p _api _grpc <<< "$agent"
    home="$HOMES_DIR/$name"
    if [ "$home" != "$BASE_HOME" ]; then
        cp "$BASE_HOME/config/genesis.json" "$home/config/genesis.json"
    fi
    "$BINARY" gentx "${name}-key" "$SELF_DELEGATION" \
        --chain-id "$CHAIN_ID" \
        --moniker "$moniker" \
        --commission-rate 0.05 \
        --commission-max-rate 0.20 \
        --commission-max-change-rate 0.01 \
        --min-self-delegation 1 \
        --keyring-backend test \
        --home "$home" > "$RUN_DIR/${name}-gentx.log" 2>&1
    cp "$home/config/gentx/"*.json "$GENTX_DIR/"
done

for gentx in "$GENTX_DIR"/*.json; do
    "$PROJECT_DIR/scripts/testnet/verify-controlled-testnet-gentx.sh" \
        "$gentx" --binary "$BINARY" --chain-id "$CHAIN_ID" --denom "$DENOM" \
        > "$RUN_DIR/verify-$(basename "$gentx").log"
done

"$PROJECT_DIR/scripts/testnet/assemble-controlled-testnet-genesis.sh" \
    --gentx-dir "$GENTX_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --binary "$BINARY" \
    --chain-id "$CHAIN_ID" \
    --denom "$DENOM" \
    --account-amount "$ACCOUNT_AMOUNT" \
    > "$RUN_DIR/assemble-genesis.log" 2>&1

VALIDATE_HOME="$(mktemp -d)"
cleanup_validate_home() {
    rm -rf "$VALIDATE_HOME"
}
trap cleanup_validate_home EXIT
mkdir -p "$VALIDATE_HOME/config"
cp "$OUTPUT_DIR/genesis.json" "$VALIDATE_HOME/config/genesis.json"
"$BINARY" validate-genesis --home "$VALIDATE_HOME" > "$OUTPUT_DIR/genesis-validation.txt" 2>&1
assert_live_flags_false "$OUTPUT_DIR/genesis.json"
mark_candidate_manifest "$OUTPUT_DIR/manifest.json"

GENESIS_SHA="$(sha256_file "$OUTPUT_DIR/genesis.json")"
RUN_DIR_REF="$(relative_to_project "$RUN_DIR")"
HOMES_DIR_REF="$(relative_to_project "$HOMES_DIR")"
INTAKE="$OUTPUT_DIR/internal-validator-intake.csv"
cat > "$INTAKE" <<EOF
moniker,contact_handle,operator_address,account_address,node_id,public_ip_or_dns,p2p_port,gentx_filename,gentx_sha256,build_commit_or_tag,os_arch,sentry_layout,ack_testnet_only
EOF

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker _rpc p2p _api _grpc <<< "$agent"
    gentx_file="$(find "$GENTX_DIR" -maxdepth 1 -type f -name '*.json' | sort | sed -n '1p')"
    for candidate in "$GENTX_DIR"/*.json; do
        if grep -q "$moniker" "$candidate"; then
            gentx_file="$candidate"
            break
        fi
    done
    operator="$(python3 - "$gentx_file" <<'PY'
import json
import sys
with open(sys.argv[1]) as f:
    g = json.load(f)
print(g["body"]["messages"][0]["validator_address"])
PY
)"
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$moniker" "internal-coordinator" "$operator" "$(cat "$(account_file "$name")")" "$(cat "$(node_file "$name")")" \
        "127.0.0.1" "$p2p" "$(basename "$gentx_file")" "$(sha256_file "$gentx_file")" \
        "$(git -C "$PROJECT_DIR" describe --tags --always --dirty)" "$(uname -s)-$(uname -m)" "no" "yes" \
        >> "$INTAKE"
done

mkdir -p "$OUTPUT_DIR/peers"
"$PROJECT_DIR/scripts/testnet/generate-persistent-peers.sh" \
    --input "$INTAKE" \
    --output-dir "$OUTPUT_DIR/peers" \
    > "$OUTPUT_DIR/peers/persistent-peers.stdout"

cat > "$OUTPUT_DIR/CANDIDATE_NOTICE.md" <<EOF
# Internal Coordinator Candidate

Status: $CANDIDATE_MARKER

This candidate is assembled from local/internal coordinator validators only. It is for rehearsal and readiness validation while external validator intake remains open.

It is not mainnet. It is not a public network launch. It does not establish external decentralisation. Testnet denominations have no monetary value. No token sale is announced or implied.
EOF

cat > "$OUTPUT_DIR/dry-run.env" <<EOF
COORDINATOR_CANDIDATE_GENESIS="releases/testnet-genesis/coordinator-candidate/genesis.json"
COORDINATOR_CANDIDATE_HOMES_DIR="$HOMES_DIR_REF"
COORDINATOR_CANDIDATE_CHAIN_ID="$CHAIN_ID"
COORDINATOR_CANDIDATE_VALIDATOR_COUNT="${#AGENTS[@]}"
EOF

cat > "$OUTPUT_DIR/coordinator-candidate-summary.json" <<EOF
{
  "network": "$CHAIN_ID",
  "status": "$CANDIDATE_MARKER",
  "generated_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "validator_count": ${#AGENTS[@]},
  "genesis_sha256": "$GENESIS_SHA",
  "output_dir": "releases/testnet-genesis/coordinator-candidate",
  "private_work_dir": "$RUN_DIR_REF",
  "product_live_flags": "false"
}
EOF

if grep -Eirq 'priv_key|private_key|mnemonic|seed phrase|seed_phrase|node_key|priv_validator|BEGIN (RSA|EC|OPENSSH|PRIVATE)' "$OUTPUT_DIR"; then
    echo "Unsafe secret-material pattern found in coordinator output directory" >&2
    exit 1
fi

echo "Coordinator candidate complete"
echo "Status: $CANDIDATE_MARKER"
echo "Genesis: $OUTPUT_DIR/genesis.json"
echo "SHA256: $GENESIS_SHA"
echo "Dry-run env: $OUTPUT_DIR/dry-run.env"
echo "Private local work dir: $RUN_DIR"
