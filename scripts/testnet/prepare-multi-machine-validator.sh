#!/usr/bin/env bash
# NexaRail multi-machine validator preparation helper.
# TESTNET ONLY. This script does not launch mainnet and does not enable live flags.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
HOME_DIR="${NEXARAIL_HOME:-$HOME/.nexarail}"
MONIKER="${NEXARAIL_MONIKER:-}"
GENESIS_FILE="${GENESIS_FILE:-}"
GENESIS_URL="${GENESIS_URL:-}"
GENESIS_SHA256="${GENESIS_SHA256:-}"
PERSISTENT_PEERS="${PERSISTENT_PEERS:-}"
MIN_GAS_PRICES="${MIN_GAS_PRICES:-0.025unxrl}"
KEY_NAME="${KEY_NAME:-}"
GENTX_AMOUNT="${GENTX_AMOUNT:-500000000unxrl}"
CREATE_KEY=0
CREATE_GENTX=0

usage() {
    cat <<EOF
Usage: $0 --moniker <name> [options]

Options:
  --binary <path>             nexaraild binary path (default: $BINARY)
  --home <path>               node home (default: $HOME_DIR)
  --chain-id <id>             chain ID (default: $CHAIN_ID)
  --moniker <name>            validator moniker (required)
  --genesis-file <path>       genesis.json to install
  --genesis-url <url>         genesis.json URL to download
  --genesis-sha256 <hash>     expected genesis SHA256
  --persistent-peers <list>   comma-separated nodeID@host:26656 list
  --min-gas-prices <value>    minimum gas prices (default: $MIN_GAS_PRICES)
  --key-name <name>           validator account key name
  --create-key                create KEY_NAME if it does not exist
  --create-gentx              create gentx after genesis/account funding is ready
  -h, --help                  show this help

Environment variables with the same names are also supported.

This helper configures a testnet validator node. It never asks for, prints, or
submits private keys or mnemonics.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --binary) BINARY="$2"; shift 2 ;;
        --home) HOME_DIR="$2"; shift 2 ;;
        --chain-id) CHAIN_ID="$2"; shift 2 ;;
        --moniker) MONIKER="$2"; shift 2 ;;
        --genesis-file) GENESIS_FILE="$2"; shift 2 ;;
        --genesis-url) GENESIS_URL="$2"; shift 2 ;;
        --genesis-sha256) GENESIS_SHA256="$2"; shift 2 ;;
        --persistent-peers) PERSISTENT_PEERS="$2"; shift 2 ;;
        --min-gas-prices) MIN_GAS_PRICES="$2"; shift 2 ;;
        --key-name) KEY_NAME="$2"; shift 2 ;;
        --create-key) CREATE_KEY=1; shift ;;
        --create-gentx) CREATE_GENTX=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

if [ -z "$MONIKER" ]; then
    echo "Missing required --moniker." >&2
    usage
    exit 1
fi

if [ "$CREATE_GENTX" -eq 1 ] && [ -z "$KEY_NAME" ]; then
    echo "--create-gentx requires --key-name." >&2
    exit 1
fi

if [ ! -x "$BINARY" ]; then
    echo "Binary not found or not executable: $BINARY" >&2
    echo "Build with: make build" >&2
    exit 1
fi

if [ "$(uname -s)" != "Linux" ]; then
    echo "WARNING: this rehearsal helper is intended for Linux validators."
fi

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

sha256_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

replace_toml_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    if [ ! -f "$file" ]; then
        echo "Config file missing: $file" >&2
        return 1
    fi
    if grep -qE "^[[:space:]]*$key[[:space:]]=" "$file"; then
        perl -0pi -e "s|(?m)^([[:space:]]*\\Q$key\\E[[:space:]]*=[[:space:]]*).*|\${1}\"$value\"|" "$file"
    else
        printf '\n%s = "%s"\n' "$key" "$value" >> "$file"
    fi
}

require_cmd curl
require_cmd awk
mkdir -p "$HOME_DIR"

echo "=== NexaRail multi-machine validator preparation ==="
echo "Chain ID: $CHAIN_ID"
echo "Moniker:  $MONIKER"
echo "Home:     $HOME_DIR"
echo "Binary:   $BINARY"
echo ""

if [ ! -f "$HOME_DIR/config/config.toml" ]; then
    echo "--- Initialising node home ---"
    "$BINARY" init "$MONIKER" --chain-id "$CHAIN_ID" --home "$HOME_DIR"
else
    echo "--- Node home already initialised ---"
fi

if [ -n "$GENESIS_FILE" ] && [ -n "$GENESIS_URL" ]; then
    echo "Use either --genesis-file or --genesis-url, not both." >&2
    exit 1
fi

if [ -n "$GENESIS_FILE" ]; then
    echo "--- Installing genesis from file ---"
    cp "$GENESIS_FILE" "$HOME_DIR/config/genesis.json"
elif [ -n "$GENESIS_URL" ]; then
    echo "--- Downloading genesis ---"
    curl -fsSL "$GENESIS_URL" -o "$HOME_DIR/config/genesis.json"
fi

if [ -f "$HOME_DIR/config/genesis.json" ]; then
    actual_sha="$(sha256_file "$HOME_DIR/config/genesis.json")"
    echo "Genesis SHA256: $actual_sha"
    if [ -n "$GENESIS_SHA256" ] && [ "$actual_sha" != "$GENESIS_SHA256" ]; then
        echo "Genesis checksum mismatch. Expected $GENESIS_SHA256" >&2
        exit 1
    fi
    "$BINARY" validate-genesis --home "$HOME_DIR"
else
    echo "WARNING: genesis not installed yet. Add genesis.json before launch."
fi

if [ -n "$PERSISTENT_PEERS" ]; then
    echo "--- Configuring persistent peers ---"
    replace_toml_value "$HOME_DIR/config/config.toml" "persistent_peers" "$PERSISTENT_PEERS"
fi

echo "--- Configuring minimum gas prices ---"
replace_toml_value "$HOME_DIR/config/app.toml" "minimum-gas-prices" "$MIN_GAS_PRICES"

if [ "$CREATE_KEY" -eq 1 ]; then
    if [ -z "$KEY_NAME" ]; then
        echo "--create-key requires --key-name." >&2
        exit 1
    fi
    if "$BINARY" keys show "$KEY_NAME" --keyring-backend file --home "$HOME_DIR" >/dev/null 2>&1; then
        echo "Key already exists: $KEY_NAME"
    else
        echo "--- Creating key: $KEY_NAME ---"
        "$BINARY" keys add "$KEY_NAME" --keyring-backend file --home "$HOME_DIR"
    fi
fi

if [ "$CREATE_GENTX" -eq 1 ]; then
    echo "--- Creating gentx ---"
    "$BINARY" gentx "$KEY_NAME" "$GENTX_AMOUNT" \
        --chain-id "$CHAIN_ID" \
        --commission-rate 0.05 \
        --commission-max-rate 0.20 \
        --commission-max-change-rate 0.01 \
        --min-self-delegation 1 \
        --keyring-backend file \
        --home "$HOME_DIR"
fi

echo "--- Node identifiers ---"
"$BINARY" tendermint show-node-id --home "$HOME_DIR" || true
"$BINARY" tendermint show-validator --home "$HOME_DIR" || true

cat <<EOF

Preparation complete.

Before launch, confirm with the coordinator:
- genesis checksum matches;
- persistent peers are final;
- node ID, validator pubkey, operator address, moniker, and host are recorded;
- all live flags remain false in the final genesis;
- no private keys, mnemonics, node keys, or validator signing keys were shared.
EOF
