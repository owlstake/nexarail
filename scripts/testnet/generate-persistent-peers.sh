#!/usr/bin/env bash
# Generate CometBFT persistent_peers strings from validator intake CSV or JSON.
set -Eeuo pipefail

INPUT=""
OUTPUT_DIR=""

usage() {
    cat <<EOF
Usage: scripts/testnet/generate-persistent-peers.sh --input <intake.csv|intake.json> [--output-dir <dir>]

Expected CSV fields include:
  moniker,node_id,public_host,p2p_port

JSON may be either a list of validator objects or {"validators": [...]}.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --input) INPUT="$2"; shift 2 ;;
        --output-dir|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
    usage >&2
    exit 2
fi

if [ -n "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
fi

python3 - "$INPUT" "$OUTPUT_DIR" <<'PY'
import csv
import json
import os
import re
import sys

path, outdir = sys.argv[1], sys.argv[2]

def load_records(path):
    if path.endswith(".json"):
        with open(path) as f:
            data = json.load(f)
        if isinstance(data, dict):
            return data.get("validators", [])
        return data
    with open(path, newline="") as f:
        return list(csv.DictReader(f))

def get(record, *names):
    for name in names:
        value = record.get(name)
        if value not in (None, ""):
            return str(value).strip()
    return ""

records = load_records(path)
valid = []
warnings = []
node_re = re.compile(r"^[0-9a-fA-F]{40}$")

for idx, record in enumerate(records, 1):
    moniker = get(record, "moniker", "name") or f"validator-{idx}"
    node_id = get(record, "node_id", "nodeID", "nodeid")
    host = get(record, "public_host", "public_ip_or_dns", "host", "public_ip", "dns", "ip")
    port = get(record, "p2p_port", "port") or "26656"
    missing = []
    if not node_id:
        missing.append("node_id")
    if node_id and not node_re.match(node_id):
        missing.append("node_id_format")
    if not host:
        missing.append("public_ip_or_dns")
    if not port:
        missing.append("p2p_port")
    if missing:
        warnings.append(f"{moniker}: missing_or_invalid={','.join(missing)}")
        continue
    valid.append({"moniker": moniker, "node_id": node_id.lower(), "host": host, "port": str(port)})

if not valid:
    status = "WAITING" if not records else "NO_VALID_PEERS"
    for warning in warnings:
        print(f"WARN {warning}", file=sys.stderr)
    print(f"{status} no valid peers generated", file=sys.stderr)
    if outdir:
        os.makedirs(outdir, exist_ok=True)
        for filename in ("persistent-peers.txt", "persistent_peers.txt"):
            with open(os.path.join(outdir, filename), "w") as f:
                f.write("")
        with open(os.path.join(outdir, "per-validator-config.toml"), "w") as f:
            f.write("# Waiting for complete validator intake records.\n")
        with open(os.path.join(outdir, "warnings.txt"), "w") as f:
            for warning in warnings:
                f.write(warning + "\n")
        with open(os.path.join(outdir, "peers.json"), "w") as f:
            json.dump({"status": status, "validators": [], "persistent_peers": "", "warnings": warnings}, f, indent=2)
            f.write("\n")
    sys.exit(0)

peer_entries = [f"{v['node_id']}@{v['host']}:{v['port']}" for v in valid]
peer_string = ",".join(peer_entries)
print(peer_string)

snippets = []
for validator in valid:
    peers = [
        f"{v['node_id']}@{v['host']}:{v['port']}"
        for v in valid
        if v["node_id"] != validator["node_id"]
    ]
    snippets.append(f"# {validator['moniker']}\npersistent_peers = \"{','.join(peers)}\"\n")

if outdir:
    for filename in ("persistent-peers.txt", "persistent_peers.txt"):
        with open(os.path.join(outdir, filename), "w") as f:
            f.write(peer_string + "\n")
    with open(os.path.join(outdir, "per-validator-config.toml"), "w") as f:
        f.write("\n".join(snippets))
    with open(os.path.join(outdir, "warnings.txt"), "w") as f:
        for warning in warnings:
            f.write(warning + "\n")
    with open(os.path.join(outdir, "peers.json"), "w") as f:
        json.dump({"status": "READY", "validators": valid, "persistent_peers": peer_string, "warnings": warnings}, f, indent=2)
        f.write("\n")

for warning in warnings:
    print(f"WARN {warning}", file=sys.stderr)
PY
