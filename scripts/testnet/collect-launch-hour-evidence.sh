#!/usr/bin/env bash
# Collect first-hour controlled-testnet launch evidence from RPC/API endpoints.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
ENDPOINTS="$PROJECT_DIR/coordination/validators/endpoint-inventory.csv"
DURATION="3600"
SAMPLE_INTERVAL="60"
CHAIN_ID="nexarail-testnet-1"
EXPECTED_VALIDATORS=""
SKIP_REST="0"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
EVIDENCE_DIR="$PROJECT_DIR/rehearsals/controlled-testnet/launch-hour/evidence/$TIMESTAMP"

usage() {
    cat <<'EOF'
Usage: scripts/testnet/collect-launch-hour-evidence.sh [options]

Options:
  --endpoints <csv>              endpoint inventory CSV
  --duration <seconds>           sample duration (default: 3600)
  --sample-interval <seconds>    sample interval (default: 60)
  --evidence-dir <path>          evidence output directory
  --chain-id <id>                expected chain ID (default: nexarail-testnet-1)
  --expected-validators <n>      expected validator count
  --skip-rest                    skip REST/API checks
  -h, --help                     show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --endpoints) ENDPOINTS="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        --sample-interval) SAMPLE_INTERVAL="$2"; shift 2 ;;
        --evidence-dir) EVIDENCE_DIR="$2"; shift 2 ;;
        --chain-id) CHAIN_ID="$2"; shift 2 ;;
        --expected-validators) EXPECTED_VALIDATORS="$2"; shift 2 ;;
        --skip-rest) SKIP_REST="1"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

mkdir -p "$EVIDENCE_DIR"

python3 - "$ENDPOINTS" "$DURATION" "$SAMPLE_INTERVAL" "$EVIDENCE_DIR" "$CHAIN_ID" "$EXPECTED_VALIDATORS" "$SKIP_REST" "$PROJECT_DIR" <<'PY'
from __future__ import annotations

import csv
import json
import os
import re
import socket
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

endpoints_file, duration_raw, interval_raw, evidence_dir, expected_chain_id, expected_validators_raw, skip_rest_raw, project_dir = sys.argv[1:9]
evidence = Path(evidence_dir)
evidence.mkdir(parents=True, exist_ok=True)

def parse_int(value: str, default: int) -> int:
    try:
        return max(0, int(value))
    except ValueError as exc:
        raise SystemExit(f"Invalid integer value {value!r}") from exc

duration = parse_int(duration_raw, 3600)
interval = max(1, parse_int(interval_raw, 60))
expected_validators = int(expected_validators_raw) if expected_validators_raw.strip() else None
skip_rest = skip_rest_raw == "1"

def read_inventory(path: str) -> list[dict[str, str]]:
    p = Path(path)
    if not p.exists():
        return []
    with p.open(newline="") as f:
        reader = csv.DictReader(f)
        return [
            {key: (value or "").strip() for key, value in row.items()}
            for row in reader
            if any((value or "").strip() for value in row.values())
        ]

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

def tcp_target(value: str) -> tuple[str, int] | None:
    if not value:
        return None
    raw = value.strip()
    if "://" in raw:
        parsed = urllib.parse.urlparse(raw)
        if parsed.hostname and parsed.port:
            return parsed.hostname, parsed.port
        return None
    if "@" in raw:
        raw = raw.rsplit("@", 1)[1]
    if raw.count(":") == 1:
        host, port = raw.rsplit(":", 1)
        if port.isdigit():
            return host, int(port)
    return None

def tcp_check(value: str, timeout: float = 3.0) -> dict[str, Any]:
    target = tcp_target(value)
    if not target:
        return {"target": value, "reachable": None, "error": "no host:port target"}
    host, port = target
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return {"target": value, "reachable": True, "error": None}
    except OSError as exc:
        return {"target": value, "reachable": False, "error": str(exc)}

live_flag_paths = [
    ("settlement.live_enabled", "/nexarail/settlement/v1/params", ["params", "live_enabled"]),
    ("settlement.treasury_routing_enabled", "/nexarail/settlement/v1/params", ["params", "treasury_routing_enabled"]),
    ("settlement.burn_routing_enabled", "/nexarail/settlement/v1/params", ["params", "burn_routing_enabled"]),
    ("escrow.live_enabled", "/nexarail/escrow/v1/params", ["params", "live_enabled"]),
    ("treasury.live_enabled", "/nexarail/treasury/v1/params", ["params", "live_enabled"]),
    ("payout.live_enabled", "/nexarail/payout/v1/params", ["params", "live_enabled"]),
]

inventory = read_inventory(endpoints_file)
notes = [
    "# Launch Hour Evidence Notes",
    "",
    "Controlled testnet launch evidence collector.",
    "",
]

samples_path = evidence / "samples.tsv"
with samples_path.open("w") as f:
    f.write("sample\tsampled_utc\tnode_name\trpc_url\tchain_id\tlatest_height\tcatching_up\tpeer_count\tvalidator_count\terrors\n")

if not inventory:
    waiting_summary = {
        "status": "WAITING",
        "reason": "No endpoint inventory rows available.",
        "chain_id": expected_chain_id,
        "expected_validators": expected_validators,
        "endpoint_count": 0,
        "sample_count": 0,
        "latest_height": None,
        "block_progression": None,
        "live_flags_false": None,
        "launch_status": "NOT_LAUNCHED",
    }
    (evidence / "summary.json").write_text(json.dumps(waiting_summary, indent=2, sort_keys=True) + "\n")
    (evidence / "endpoint-health.json").write_text(json.dumps({"status": "WAITING", "endpoints": []}, indent=2) + "\n")
    (evidence / "validators-final.json").write_text(json.dumps({"status": "WAITING", "validators": []}, indent=2) + "\n")
    (evidence / "live-flags-final.json").write_text(json.dumps({"status": "SKIPPED", "reason": "No API endpoints available."}, indent=2) + "\n")
    (evidence / "panic-scan.txt").write_text("SKIP no local logs available for launch-hour scan.\n")
    notes.extend([
        "- No endpoint inventory rows were available.",
        "- No RPC/API samples were attempted.",
        "- This is a waiting state, not a launch failure.",
        "- No public testnet is live from this evidence.",
    ])
    (evidence / "notes.md").write_text("\n".join(notes) + "\n")
    (evidence / "summary.md").write_text(
        "\n".join([
            "# Launch Hour Evidence Summary",
            "",
            "- Status: WAITING",
            f"- Chain ID: `{expected_chain_id}`",
            "- Endpoint rows: 0",
            "- RPC samples: 0",
            "- Final public launch status: NOT LAUNCHED",
            "- Reason: no endpoint inventory rows available.",
        ]) + "\n"
    )
    print(f"Launch-hour evidence status: WAITING")
    print(f"Evidence: {evidence}")
    sys.exit(0)

endpoint_health: list[dict[str, Any]] = []
all_samples: list[dict[str, Any]] = []
validators_final: Any = {"status": "UNAVAILABLE"}
live_flags_final: dict[str, Any] = {"status": "SKIPPED" if skip_rest else "UNAVAILABLE", "flags": {}}

for row in inventory:
    for key in ("rpc_url", "api_url", "grpc_url", "p2p_address"):
        value = row.get(key, "")
        if value:
            endpoint_health.append({
                "node_name": row.get("node_name", ""),
                "kind": key,
                "value": value,
                "tcp": tcp_check(value) if key in ("grpc_url", "p2p_address") else None,
            })

deadline = time.monotonic() + duration
sample_no = 0
while True:
    sample_no += 1
    sampled_utc = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    for row in inventory:
        rpc = row.get("rpc_url", "").rstrip("/")
        if not rpc:
            continue
        status, status_err = fetch_json(rpc, "/status")
        net_info, net_err = fetch_json(rpc, "/net_info")
        validators, val_err = fetch_json(rpc, "/validators")
        if validators:
            validators_final = validators
        errors = [err for err in (status_err, net_err, val_err) if err]
        sample = {
            "sample": sample_no,
            "sampled_utc": sampled_utc,
            "node_name": row.get("node_name", ""),
            "rpc_url": rpc,
            "chain_id": get_path(status, ["result", "node_info", "network"]) if status else None,
            "latest_height": as_int(get_path(status, ["result", "sync_info", "latest_block_height"])) if status else None,
            "catching_up": get_path(status, ["result", "sync_info", "catching_up"]) if status else None,
            "peer_count": as_int(get_path(net_info, ["result", "n_peers"])) if net_info else None,
            "validator_count": len(get_path(validators, ["result", "validators"], [])) if validators else None,
            "errors": errors,
        }
        all_samples.append(sample)
        with samples_path.open("a") as f:
            f.write(
                f"{sample_no}\t{sampled_utc}\t{sample['node_name']}\t{rpc}\t{sample['chain_id']}\t"
                f"{sample['latest_height']}\t{sample['catching_up']}\t{sample['peer_count']}\t"
                f"{sample['validator_count']}\t{' | '.join(errors)}\n"
            )
    now = time.monotonic()
    if duration == 0 or now >= deadline:
        break
    time.sleep(min(interval, max(0, deadline - now)))

if not skip_rest:
    api_flags: dict[str, dict[str, Any]] = {}
    for row in inventory:
        api = row.get("api_url", "").rstrip("/")
        if not api:
            continue
        flags: dict[str, Any] = {}
        errors: list[str] = []
        for name, path, parts in live_flag_paths:
            data, err = fetch_json(api, path)
            if err:
                errors.append(err)
            else:
                flags[name] = get_path(data, parts)
        api_flags[api] = {"flags": flags, "errors": errors, "live_flags_false": bool(flags) and all(is_false(v) for v in flags.values())}
    live_flags_final = {"status": "READY" if api_flags else "UNAVAILABLE", "by_api": api_flags}

panic_hits: list[str] = []
log_roots = [
    evidence / "logs",
    Path(project_dir) / "rehearsals/controlled-testnet/launch-hour/logs",
]
for env_name in ("LAUNCH_LOG_DIR", "CONTROLLED_TESTNET_LOG_DIR"):
    if os.environ.get(env_name):
        log_roots.append(Path(os.environ[env_name]))
patterns = re.compile(r"panic|fatal|unrecoverable|segmentation fault", re.IGNORECASE)
for root in log_roots:
    if not root.exists():
        continue
    for path in root.rglob("*.log"):
        try:
            for line_no, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
                if patterns.search(line):
                    panic_hits.append(f"{path}:{line_no}:{line[:300]}")
        except OSError:
            continue

heights = [sample["latest_height"] for sample in all_samples if sample.get("latest_height") is not None]
latest_height = heights[-1] if heights else None
block_progression = (heights[-1] - heights[0]) if len(heights) >= 2 else None
failures: list[str] = []
warnings: list[str] = []
if all_samples:
    for sample in all_samples:
        if sample.get("chain_id") and sample["chain_id"] != expected_chain_id:
            failures.append(f"{sample['rpc_url']}: chain ID {sample['chain_id']} != {expected_chain_id}")
        if expected_validators is not None and sample.get("validator_count") is not None and sample["validator_count"] != expected_validators:
            failures.append(f"{sample['rpc_url']}: validator count {sample['validator_count']} != {expected_validators}")
        if sample.get("catching_up") is True or str(sample.get("catching_up")).lower() == "true":
            warnings.append(f"{sample['rpc_url']}: catching_up=true")
        if sample.get("errors"):
            warnings.append(f"{sample['rpc_url']}: {' | '.join(sample['errors'])}")
else:
    warnings.append("Endpoint inventory has rows but no rpc_url values were sampled.")
if panic_hits:
    failures.append("panic/fatal markers found in local logs")
if not skip_rest and live_flags_final.get("by_api"):
    for api, item in live_flags_final["by_api"].items():
        if item["flags"] and not item["live_flags_false"]:
            failures.append(f"{api}: one or more live flags are not false")

status = "PASS" if not failures else "FAIL"
if warnings and not failures:
    status = "WARN"

(evidence / "endpoint-health.json").write_text(json.dumps({"status": status, "endpoints": endpoint_health}, indent=2, sort_keys=True) + "\n")
(evidence / "validators-final.json").write_text(json.dumps(validators_final, indent=2, sort_keys=True) + "\n")
(evidence / "live-flags-final.json").write_text(json.dumps(live_flags_final, indent=2, sort_keys=True) + "\n")
(evidence / "panic-scan.txt").write_text("\n".join(panic_hits or ["PASS no panic/fatal markers found in configured local logs."]) + "\n")

summary = {
    "status": status,
    "chain_id": expected_chain_id,
    "expected_validators": expected_validators,
    "endpoint_count": len(inventory),
    "sample_count": len(all_samples),
    "latest_height": latest_height,
    "block_progression": block_progression,
    "live_flags_final": live_flags_final,
    "panic_hits": len(panic_hits),
    "failures": failures,
    "warnings": sorted(set(warnings)),
    "launch_status": "NOT_LAUNCHED",
}
(evidence / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
(evidence / "notes.md").write_text("\n".join(notes + ["", "- Evidence captured from endpoint inventory.", "- This evidence does not claim a public launch."]) + "\n")
(evidence / "summary.md").write_text(
    "\n".join([
        "# Launch Hour Evidence Summary",
        "",
        f"- Status: {status}",
        f"- Chain ID: `{expected_chain_id}`",
        f"- Endpoint rows: {len(inventory)}",
        f"- RPC samples: {len(all_samples)}",
        f"- Latest height: {latest_height}",
        f"- Block progression: {block_progression}",
        f"- Panic/fatal markers: {len(panic_hits)}",
        "- Final public launch status: NOT LAUNCHED",
        "",
        "## Warnings",
        *(f"- {warning}" for warning in sorted(set(warnings)) or ["-"]),
        "",
        "## Failures",
        *(f"- {failure}" for failure in failures or ["-"]),
    ]) + "\n"
)

print(f"Launch-hour evidence status: {status}")
print(f"Evidence: {evidence}")
sys.exit(1 if failures else 0)
PY
