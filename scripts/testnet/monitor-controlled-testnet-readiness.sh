#!/usr/bin/env bash
# Sample controlled-testnet RPC/API endpoints for launch-readiness monitoring.
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/testnet/monitor-controlled-testnet-readiness.sh [options]

Options:
  --rpc-endpoints <urls>              comma-separated RPC endpoints
  --rpc-file|--endpoints-file <file>  file with RPC endpoints or CSV containing rpc_url
  --api-endpoints <urls>              optional comma-separated REST/API endpoints
  --api-file <file>                   optional file with API endpoints or CSV containing api_url
  --expected-chain-id <id>            expected chain ID
  --expected-validator-count <n>      expected validator count
  --sample-duration <seconds>         sample duration (default: 60)
  --sample-interval <seconds>         sample interval (default: 10)
  --output-json <file>                optional JSON report path
  -h, --help                          show this help

Endpoint inventory CSV files may use the columns rpc_url and api_url.
EOF
}

RPC_ENDPOINTS=""
RPC_FILE=""
API_ENDPOINTS=""
API_FILE=""
EXPECTED_CHAIN_ID="${EXPECTED_CHAIN_ID:-nexarail-testnet-1}"
EXPECTED_VALIDATOR_COUNT="${EXPECTED_VALIDATOR_COUNT:-}"
SAMPLE_DURATION="${SAMPLE_DURATION:-60}"
SAMPLE_INTERVAL="${SAMPLE_INTERVAL:-10}"
OUTPUT_JSON=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --rpc-endpoints) RPC_ENDPOINTS="$2"; shift 2 ;;
        --rpc-file|--endpoints-file) RPC_FILE="$2"; shift 2 ;;
        --api-endpoints) API_ENDPOINTS="$2"; shift 2 ;;
        --api-file) API_FILE="$2"; shift 2 ;;
        --expected-chain-id) EXPECTED_CHAIN_ID="$2"; shift 2 ;;
        --expected-validator-count) EXPECTED_VALIDATOR_COUNT="$2"; shift 2 ;;
        --sample-duration) SAMPLE_DURATION="$2"; shift 2 ;;
        --sample-interval) SAMPLE_INTERVAL="$2"; shift 2 ;;
        --output-json) OUTPUT_JSON="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ -z "$RPC_ENDPOINTS" ] && [ -z "$RPC_FILE" ]; then
    usage >&2
    exit 2
fi

python3 - "$RPC_ENDPOINTS" "$RPC_FILE" "$API_ENDPOINTS" "$API_FILE" "$EXPECTED_CHAIN_ID" "$EXPECTED_VALIDATOR_COUNT" "$SAMPLE_DURATION" "$SAMPLE_INTERVAL" "$OUTPUT_JSON" <<'PY'
from __future__ import annotations

import argparse
import csv
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

rpc_endpoints, rpc_file, api_endpoints, api_file, expected_chain_id, expected_validator_count, sample_duration, sample_interval, output_json = sys.argv[1:10]

def endpoint_list(value: str) -> list[str]:
    return [item.strip().rstrip("/") for item in value.split(",") if item.strip()]

def endpoints_from_file(path: str, column: str) -> list[str]:
    if not path:
        return []
    p = Path(path)
    if not p.exists():
        raise SystemExit(f"Endpoint file not found: {path}")
    text = p.read_text().strip()
    if not text:
        return []
    first_line = text.splitlines()[0]
    if "," in first_line and column in first_line.split(","):
        with p.open(newline="") as f:
            return [
                (row.get(column) or "").strip().rstrip("/")
                for row in csv.DictReader(f)
                if (row.get(column) or "").strip()
            ]
    values: list[str] = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "," in line:
            values.extend(endpoint_list(line))
        else:
            values.append(line.rstrip("/"))
    return values

def fetch_json(base: str, path: str, timeout: float = 5.0) -> tuple[Any | None, str | None]:
    url = f"{base.rstrip('/')}{path}"
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8")), None
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as exc:
        return None, f"{url}: {exc}"

def get_path(data: Any, parts: list[str], default: Any = None) -> Any:
    cur = data
    for part in parts:
        if isinstance(cur, dict):
            cur = cur.get(part, default)
        elif isinstance(cur, list):
            try:
                cur = cur[int(part)]
            except Exception:
                return default
        else:
            return default
    return cur

def as_int(value: Any) -> int | None:
    try:
        return int(value)
    except Exception:
        return None

def is_false(value: Any) -> bool:
    return value is False or str(value).lower() == "false"

try:
    duration = max(0, int(sample_duration))
    interval = max(1, int(sample_interval))
except ValueError as exc:
    raise SystemExit(f"Invalid sample timing: {exc}") from exc

expected_validators = as_int(expected_validator_count) if expected_validator_count else None
rpcs = endpoint_list(rpc_endpoints) + endpoints_from_file(rpc_file, "rpc_url")
apis = endpoint_list(api_endpoints) + endpoints_from_file(api_file, "api_url")
rpcs = list(dict.fromkeys(rpcs))
apis = list(dict.fromkeys(apis))
if not rpcs:
    raise SystemExit("No RPC endpoints provided")

samples: dict[str, list[dict[str, Any]]] = {rpc: [] for rpc in rpcs}
api_samples: dict[str, dict[str, Any]] = {}
notes: list[str] = []

deadline = time.monotonic() + duration
sample_no = 0
while True:
    sample_no += 1
    sampled_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    for rpc in rpcs:
        status, status_err = fetch_json(rpc, "/status")
        net_info, net_err = fetch_json(rpc, "/net_info")
        validators, val_err = fetch_json(rpc, "/validators")
        entry = {
            "sample": sample_no,
            "sampled_utc": sampled_at,
            "rpc": rpc,
            "chain_id": get_path(status, ["result", "node_info", "network"]) if status else None,
            "latest_height": as_int(get_path(status, ["result", "sync_info", "latest_block_height"])) if status else None,
            "catching_up": get_path(status, ["result", "sync_info", "catching_up"]) if status else None,
            "peer_count": as_int(get_path(net_info, ["result", "n_peers"])) if net_info else None,
            "validator_count": len(get_path(validators, ["result", "validators"], [])) if validators else None,
            "errors": [err for err in (status_err, net_err, val_err) if err],
        }
        samples[rpc].append(entry)
        notes.extend([f"{rpc}: {err}" for err in entry["errors"]])

    now = time.monotonic()
    if duration == 0 or now >= deadline:
        break
    time.sleep(min(interval, max(0, deadline - now)))

live_flag_paths = [
    ("settlement.live_enabled", "/nexarail/settlement/v1/params", ["params", "live_enabled"]),
    ("settlement.treasury_routing_enabled", "/nexarail/settlement/v1/params", ["params", "treasury_routing_enabled"]),
    ("settlement.burn_routing_enabled", "/nexarail/settlement/v1/params", ["params", "burn_routing_enabled"]),
    ("escrow.live_enabled", "/nexarail/escrow/v1/params", ["params", "live_enabled"]),
    ("treasury.live_enabled", "/nexarail/treasury/v1/params", ["params", "live_enabled"]),
    ("payout.live_enabled", "/nexarail/payout/v1/params", ["params", "live_enabled"]),
]

for api in apis:
    flags: dict[str, Any] = {}
    errors: list[str] = []
    for name, path, parts in live_flag_paths:
        data, err = fetch_json(api, path)
        if err:
            errors.append(err)
            continue
        flags[name] = get_path(data, parts)
    api_samples[api] = {
        "api": api,
        "live_flags": flags,
        "live_flags_false": bool(flags) and all(is_false(value) for value in flags.values()),
        "errors": errors,
    }
    notes.extend([f"{api}: {err}" for err in errors])

endpoint_results: list[dict[str, Any]] = []
failures: list[str] = []
warnings: list[str] = []

for rpc, entries in samples.items():
    valid_heights = [item["latest_height"] for item in entries if item.get("latest_height") is not None]
    first_height = valid_heights[0] if valid_heights else None
    latest_height = valid_heights[-1] if valid_heights else None
    delta = (latest_height - first_height) if first_height is not None and latest_height is not None else None
    last = entries[-1] if entries else {}
    result = {
        "rpc": rpc,
        "first_height": first_height,
        "latest_height": latest_height,
        "height_delta": delta,
        "chain_id": last.get("chain_id"),
        "catching_up": last.get("catching_up"),
        "peer_count": last.get("peer_count"),
        "validator_count": last.get("validator_count"),
        "sample_count": len(entries),
        "errors": [err for item in entries for err in item.get("errors", [])],
    }
    endpoint_results.append(result)
    if result["chain_id"] != expected_chain_id:
        failures.append(f"{rpc}: chain ID {result['chain_id']} != {expected_chain_id}")
    if expected_validators is not None and result["validator_count"] != expected_validators:
        failures.append(f"{rpc}: validator count {result['validator_count']} != {expected_validators}")
    if duration > 0 and (delta is None or delta <= 0):
        failures.append(f"{rpc}: no block progression observed")
    if result["catching_up"] is True or str(result["catching_up"]).lower() == "true":
        warnings.append(f"{rpc}: catching_up=true")
    if result["peer_count"] in (None, 0):
        warnings.append(f"{rpc}: peer count is {result['peer_count']}")
    if result["errors"]:
        warnings.append(f"{rpc}: {len(result['errors'])} endpoint fetch error(s)")

for api, item in api_samples.items():
    if item["errors"]:
        warnings.append(f"{api}: REST/API fetch errors present")
    if item["live_flags"] and not item["live_flags_false"]:
        failures.append(f"{api}: one or more live flags are not false")
if not apis:
    warnings.append("REST/API endpoints not provided; live-flag checks skipped")
    notes.append("Panic log scan is unavailable in endpoint-only mode unless operators provide host logs.")

status = "PASS" if not failures else "FAIL"
if warnings and not failures:
    status = "WARN"

report = {
    "status": status,
    "expected_chain_id": expected_chain_id,
    "expected_validator_count": expected_validators,
    "sample_duration_seconds": duration,
    "sample_interval_seconds": interval,
    "rpc_results": endpoint_results,
    "api_results": list(api_samples.values()),
    "failures": failures,
    "warnings": warnings,
    "health_notes": notes[:100],
}

print("Controlled testnet readiness monitor")
print(f"Status: {status}")
print(f"Expected chain ID: {expected_chain_id}")
print(f"Expected validator count: {expected_validators if expected_validators is not None else 'not set'}")
print("")
for result in endpoint_results:
    print(f"RPC: {result['rpc']}")
    print(f"  latest_height: {result['latest_height']}")
    print(f"  block_progression: {result['height_delta']}")
    print(f"  catching_up: {result['catching_up']}")
    print(f"  peer_count: {result['peer_count']}")
    print(f"  validator_count: {result['validator_count']}")
    print(f"  chain_id: {result['chain_id']}")
if api_samples:
    print("")
    for api, item in api_samples.items():
        print(f"API: {api}")
        print(f"  live_flags_false: {item['live_flags_false']}")
        print(f"  live_flags: {json.dumps(item['live_flags'], sort_keys=True)}")
if warnings:
    print("")
    print("Warnings:")
    for warning in warnings:
        print(f"  - {warning}")
if failures:
    print("")
    print("Failures:")
    for failure in failures:
        print(f"  - {failure}")

if output_json:
    Path(output_json).parent.mkdir(parents=True, exist_ok=True)
    Path(output_json).write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(f"\nJSON report: {output_json}")

sys.exit(1 if failures else 0)
PY
