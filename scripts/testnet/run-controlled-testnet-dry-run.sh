#!/usr/bin/env bash
# Local five-validator dry-run for the controlled external-validator testnet path.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
DENOM="${NEXARAIL_DENOM:-unxrl}"
TIMESTAMP="${DRY_RUN_TIMESTAMP:-$(date -u +%Y%m%dT%H%M%SZ)}"
ROOT_DIR="${DRY_RUN_ROOT:-$PROJECT_DIR/rehearsals/controlled-testnet/dry-run}"
RUN_DIR="$ROOT_DIR/runs/$TIMESTAMP"
EVIDENCE_DIR="$ROOT_DIR/evidence/$TIMESTAMP"
HOMES_DIR="$RUN_DIR/homes"
GENTX_DIR="$EVIDENCE_DIR/gentxs"
GENESIS_OUT="$EVIDENCE_DIR/testnet-genesis/$CHAIN_ID"
PEERS_OUT="$EVIDENCE_DIR/peers"
PIDS_DIR="$RUN_DIR/pids"
LOGS_DIR="$EVIDENCE_DIR/logs"
MIN_HEIGHT="${MIN_HEIGHT:-20}"

AGENTS=(
    "alpha:nxrl-controlled-alpha:31657:31656:1517:9290"
    "bravo:nxrl-controlled-bravo:31667:31666:1518:9291"
    "charlie:nxrl-controlled-charlie:31677:31676:1519:9292"
    "delta:nxrl-controlled-delta:31687:31686:1520:9293"
    "echo:nxrl-controlled-echo:31697:31696:1521:9294"
)

PASS=0
FAIL=0

pass() { echo "PASS $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL $1"; FAIL=$((FAIL + 1)); }

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

json_get() {
    python3 - "$1" "$2" <<'PY'
import json
import sys
path, expr = sys.argv[1], sys.argv[2].split(".")
with open(path) as f:
    data = json.load(f)
cur = data
for part in expr:
    if not part:
        continue
    if isinstance(cur, list):
        cur = cur[int(part)]
    else:
        cur = cur.get(part, "")
print(cur if cur is not None else "")
PY
}

stop_runtime() {
    if [ -d "$PIDS_DIR" ]; then
        for pid_file in "$PIDS_DIR"/*.pid; do
            [ -f "$pid_file" ] || continue
            pid="$(cat "$pid_file" 2>/dev/null || true)"
            if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
                kill "$pid" >/dev/null 2>&1 || true
            fi
        done
        sleep 2
        for pid_file in "$PIDS_DIR"/*.pid; do
            [ -f "$pid_file" ] || continue
            pid="$(cat "$pid_file" 2>/dev/null || true)"
            if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
                kill -KILL "$pid" >/dev/null 2>&1 || true
            fi
        done
    fi
}
trap stop_runtime EXIT

wait_for_rpc() {
    local name="$1"
    local rpc="$2"
    local file="$EVIDENCE_DIR/${name}-status.json"
    for _ in $(seq 1 60); do
        curl -s --max-time 3 "http://127.0.0.1:$rpc/status" > "$file" 2>"$file.err" || true
        if python3 - "$file" <<'PY' >/dev/null 2>&1
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
raise SystemExit(0 if data.get("result", {}).get("node_info", {}).get("network") else 1)
PY
        then
            rm -f "$file.err"
            return 0
        fi
        sleep 2
    done
    return 1
}

configure_home() {
    local home="$1"
    local peers="$2"
    local rpc="$3"
    local p2p="$4"
    local api="$5"
    local grpc="$6"
    python3 - "$home/config/config.toml" "$home/config/app.toml" "$peers" "$rpc" "$p2p" "$api" "$grpc" <<'PY'
import sys

config_path, app_path, peers, rpc, p2p, api, grpc = sys.argv[1:8]

def rewrite_toml(path, replacements, section_replacements=None):
    section_replacements = section_replacements or {}
    section = ""
    out = []
    seen = set()
    with open(path) as f:
        for line in f:
            stripped = line.strip()
            if stripped.startswith("[") and stripped.endswith("]"):
                section = stripped
            key = stripped.split("=", 1)[0].strip() if "=" in stripped else ""
            repl = None
            if (section, key) in section_replacements:
                repl = section_replacements[(section, key)]
                seen.add((section, key))
            elif key in replacements:
                repl = replacements[key]
                seen.add(key)
            if repl is not None:
                line = f'{key} = "{repl}"\n' if isinstance(repl, str) else f"{key} = {str(repl).lower()}\n"
            out.append(line)
    with open(path, "w") as f:
        f.writelines(out)

rewrite_toml(
    config_path,
    {
        "persistent_peers": peers,
        "addr_book_strict": False,
        "allow_duplicate_ip": True,
        "pex": True,
    },
    {
        ("[rpc]", "laddr"): f"tcp://127.0.0.1:{rpc}",
        ("[p2p]", "laddr"): f"tcp://0.0.0.0:{p2p}",
    },
)

rewrite_toml(
    app_path,
    {"minimum-gas-prices": "0unxrl"},
    {
        ("[api]", "enable"): True,
        ("[api]", "address"): f"tcp://127.0.0.1:{api}",
        ("[grpc]", "enable"): True,
        ("[grpc]", "address"): f"127.0.0.1:{grpc}",
        ("[grpc-web]", "enable"): False,
        ("[rosetta]", "enable"): False,
    },
)
PY
}

mkdir -p "$EVIDENCE_DIR" "$HOMES_DIR" "$GENTX_DIR" "$GENESIS_OUT" "$PEERS_OUT" "$PIDS_DIR" "$LOGS_DIR"

{
    echo "Timestamp UTC: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Project: $PROJECT_DIR"
    echo "Chain ID: $CHAIN_ID"
    echo "Evidence: $EVIDENCE_DIR"
    echo "Run dir: $RUN_DIR"
} > "$EVIDENCE_DIR/run-context.txt"

if [ ! -x "$BINARY" ]; then
    make -C "$PROJECT_DIR" build
fi

echo "Controlled testnet dry-run"
echo "Evidence: $EVIDENCE_DIR"

BASE_HOME="$HOMES_DIR/alpha"

account_file() {
    printf '%s/%s-account-address.txt' "$EVIDENCE_DIR" "$1"
}

node_file() {
    printf '%s/%s-node-id.txt' "$EVIDENCE_DIR" "$1"
}

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker rpc p2p api grpc <<< "$agent"
    home="$HOMES_DIR/$name"
    mkdir -p "$home"
    "$BINARY" init "$moniker" --chain-id "$CHAIN_ID" --home "$home" --overwrite > "$EVIDENCE_DIR/${name}-init.log" 2>&1
    "$BINARY" keys add "${name}-key" --keyring-backend test --home "$home" > "$EVIDENCE_DIR/${name}-keys-add.log" 2>&1
    "$BINARY" keys show "${name}-key" -a --keyring-backend test --home "$home" > "$(account_file "$name")"
    "$BINARY" tendermint show-node-id --home "$home" > "$(node_file "$name")"
done
pass "five validator homes initialised"

python3 - "$BASE_HOME/config/genesis.json" "$CHAIN_ID" "$DENOM" <<'PY'
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

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name _moniker _rpc _p2p _api _grpc <<< "$agent"
    "$BINARY" add-genesis-account "$(cat "$(account_file "$name")")" "1000000000000$DENOM" --home "$BASE_HOME" >> "$EVIDENCE_DIR/add-genesis-accounts.log" 2>&1
done
pass "genesis accounts added"

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name moniker _rpc _p2p _api _grpc <<< "$agent"
    home="$HOMES_DIR/$name"
    if [ "$home" != "$BASE_HOME" ]; then
        cp "$BASE_HOME/config/genesis.json" "$home/config/genesis.json"
    fi
    "$BINARY" gentx "${name}-key" "500000000$DENOM" \
        --chain-id "$CHAIN_ID" \
        --moniker "$moniker" \
        --commission-rate 0.05 \
        --commission-max-rate 0.20 \
        --commission-max-change-rate 0.01 \
        --min-self-delegation 1 \
        --keyring-backend test \
        --home "$home" > "$EVIDENCE_DIR/${name}-gentx.log" 2>&1
    cp "$home/config/gentx/"*.json "$GENTX_DIR/"
done
pass "five gentxs generated"

for gentx in "$GENTX_DIR"/*.json; do
    scripts/testnet/verify-controlled-testnet-gentx.sh "$gentx" --binary "$BINARY" \
        > "$EVIDENCE_DIR/verify-$(basename "$gentx").log"
done
pass "gentx verification passed"

scripts/testnet/assemble-controlled-testnet-genesis.sh \
    --gentx-dir "$GENTX_DIR" \
    --output-dir "$GENESIS_OUT" \
    --binary "$BINARY" \
    > "$EVIDENCE_DIR/assemble-genesis.log"
pass "controlled genesis assembled"

GENESIS_SHA="$(awk '{print $1}' "$GENESIS_OUT/SHA256SUMS")"

INTAKE="$EVIDENCE_DIR/validator-intake.csv"
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
import json, sys
with open(sys.argv[1]) as f:
    g = json.load(f)
print(g["body"]["messages"][0]["validator_address"])
PY
)"
    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$moniker" "local-dry-run" "$operator" "$(cat "$(account_file "$name")")" "$(cat "$(node_file "$name")")" \
        "127.0.0.1" "$p2p" "$(basename "$gentx_file")" "$(sha256_file "$gentx_file")" \
        "$(git -C "$PROJECT_DIR" describe --tags --always --dirty)" "$(uname -s)-$(uname -m)" "no" "yes" \
        >> "$INTAKE"
done

PEER_STRING="$(scripts/testnet/generate-persistent-peers.sh --input "$INTAKE" --output-dir "$PEERS_OUT")"
pass "persistent peers generated"

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name _moniker rpc p2p api grpc <<< "$agent"
    home="$HOMES_DIR/$name"
    cp "$GENESIS_OUT/genesis.json" "$home/config/genesis.json"
    self="$(cat "$(node_file "$name")")@127.0.0.1:${p2p}"
    peers="$(python3 - "$PEER_STRING" "$self" <<'PY'
import sys
peers = [p for p in sys.argv[1].split(",") if p and p != sys.argv[2]]
print(",".join(peers))
PY
)"
    configure_home "$home" "$peers" "$rpc" "$p2p" "$api" "$grpc"
done
pass "validator homes configured with final genesis and peers"

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name _moniker rpc p2p api grpc <<< "$agent"
    home="$HOMES_DIR/$name"
    log="$LOGS_DIR/${name}.log"
    "$BINARY" start --home "$home" --minimum-gas-prices "0$DENOM" \
        --api.enable --api.address "tcp://127.0.0.1:${api}" \
        --grpc.enable --grpc.address "127.0.0.1:${grpc}" \
        --rpc.laddr "tcp://127.0.0.1:${rpc}" \
        --p2p.laddr "tcp://0.0.0.0:${p2p}" \
        --p2p.persistent_peers "$(python3 - "$PEER_STRING" "$(cat "$(node_file "$name")")@127.0.0.1:${p2p}" <<'PY'
import sys
print(",".join([p for p in sys.argv[1].split(",") if p and p != sys.argv[2]]))
PY
)" \
        > "$log" 2>&1 &
    echo "$!" > "$PIDS_DIR/${name}.pid"
    sleep 2
done
pass "five validator processes started"

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name _moniker rpc _p2p _api _grpc <<< "$agent"
    wait_for_rpc "$name" "$rpc" || { fail "$name RPC ready"; exit 1; }
done
pass "all validator RPC endpoints ready"

ALPHA_RPC=31657
HEIGHT=0
for _ in $(seq 1 90); do
    curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/status" > "$EVIDENCE_DIR/alpha-status-latest.json" || true
    HEIGHT="$(json_get "$EVIDENCE_DIR/alpha-status-latest.json" "result.sync_info.latest_block_height" 2>/dev/null || echo 0)"
    if [ "${HEIGHT:-0}" -ge "$MIN_HEIGHT" ] 2>/dev/null; then
        break
    fi
    sleep 2
done

if [ "${HEIGHT:-0}" -lt "$MIN_HEIGHT" ] 2>/dev/null; then
    fail "height reached $MIN_HEIGHT"
    exit 1
fi
pass "first $MIN_HEIGHT blocks produced"

curl -s --max-time 3 "http://127.0.0.1:$ALPHA_RPC/validators" > "$EVIDENCE_DIR/alpha-validators.json"
VAL_COUNT="$(json_get "$EVIDENCE_DIR/alpha-validators.json" "result.validators" | python3 -c 'import ast,sys; print(len(ast.literal_eval(sys.stdin.read())))' 2>/dev/null || python3 - "$EVIDENCE_DIR/alpha-validators.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    print(len(json.load(f)["result"]["validators"]))
PY
)"
if [ "$VAL_COUNT" = "5" ]; then
    pass "validator set count is 5"
else
    fail "validator set count is $VAL_COUNT"
    exit 1
fi

for agent in "${AGENTS[@]}"; do
    IFS=':' read -r name _moniker _rpc _p2p _api _grpc <<< "$agent"
    home="$HOMES_DIR/$name"
    tm_id="$("$BINARY" tendermint show-node-id --home "$home")"
    comet_id="$("$BINARY" comet show-node-id --home "$home")"
    if [ "$tm_id" = "$comet_id" ] && [ "${#tm_id}" -eq 40 ]; then
        echo "$tm_id" > "$EVIDENCE_DIR/${name}-node-id.txt"
    else
        fail "$name node ID helper commands"
        exit 1
    fi
done
pass "tendermint/comet node ID helpers verified"

for item in \
    "settlement:live_enabled" \
    "settlement:treasury_routing_enabled" \
    "settlement:burn_routing_enabled" \
    "escrow:live_enabled" \
    "treasury:live_enabled" \
    "payout:live_enabled"; do
    IFS=':' read -r module field <<< "$item"
    curl -s --max-time 5 "http://127.0.0.1:1517/nexarail/${module}/v1/params" > "$EVIDENCE_DIR/${module}-params.json"
    value="$(json_get "$EVIDENCE_DIR/${module}-params.json" "params.${field}")"
    if [ "$value" != "False" ] && [ "$value" != "false" ]; then
        fail "${module}.${field} expected false got ${value:-missing}"
        exit 1
    fi
done
pass "product live flags false"

cat > "$EVIDENCE_DIR/summary.json" <<EOF
{
  "timestamp_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "chain_id": "$CHAIN_ID",
  "validator_count": 5,
  "height_verified": $HEIGHT,
  "genesis_sha256": "$GENESIS_SHA",
  "pass": $PASS,
  "fail": $FAIL,
  "status": "PASS"
}
EOF

cat > "$EVIDENCE_DIR/summary.md" <<EOF
# Controlled Testnet Dry-Run Summary

- Chain ID: $CHAIN_ID
- Validators: 5 local validators
- Height verified: $HEIGHT
- Validator set count: 5
- Genesis SHA256: $GENESIS_SHA
- Product live flags: false
- Tendermint/comet node ID helpers: pass
- Result: PASS

Evidence path: $EVIDENCE_DIR
EOF

echo "Dry-run complete"
echo "Summary: $EVIDENCE_DIR/summary.md"
