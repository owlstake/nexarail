#!/usr/bin/env bash
# Validate external-validator intake records and submitted gentxs.
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && cd ../.. && pwd)"
REGISTRY="$PROJECT_DIR/coordination/validators/validator-intake.csv"
GENTX_DIR="$PROJECT_DIR/coordination/validators/gentxs"
VERIFIED_DIR="$PROJECT_DIR/coordination/validators/verified"
REJECTED_DIR="$PROJECT_DIR/coordination/validators/rejected"
BINARY="${NEXARAIL_BINARY:-$PROJECT_DIR/build/nexaraild}"
CHAIN_ID="${NEXARAIL_CHAIN_ID:-nexarail-testnet-1}"
DENOM="${NEXARAIL_DENOM:-unxrl}"

usage() {
    cat <<EOF
Usage: scripts/testnet/validate-validator-intake.sh [options]

Options:
  --input <csv>          validator intake CSV (default: coordination/validators/validator-intake.csv)
  --gentx-dir <dir>      submitted gentx directory (default: coordination/validators/gentxs)
  --verified-dir <dir>   verified output directory (default: coordination/validators/verified)
  --rejected-dir <dir>   rejected output directory (default: coordination/validators/rejected)
  --binary <path>        nexaraild binary path for gentx checks
  --chain-id <id>        expected chain ID (default: $CHAIN_ID)
  --denom <denom>        expected self-delegation denom (default: $DENOM)
  -h, --help             show this help
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --input) REGISTRY="$2"; shift 2 ;;
        --gentx-dir) GENTX_DIR="$2"; shift 2 ;;
        --verified-dir) VERIFIED_DIR="$2"; shift 2 ;;
        --rejected-dir) REJECTED_DIR="$2"; shift 2 ;;
        --binary) BINARY="$2"; shift 2 ;;
        --chain-id) CHAIN_ID="$2"; shift 2 ;;
        --denom) DENOM="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

mkdir -p "$GENTX_DIR" "$VERIFIED_DIR" "$REJECTED_DIR"

python3 - "$PROJECT_DIR" "$REGISTRY" "$GENTX_DIR" "$VERIFIED_DIR" "$REJECTED_DIR" "$BINARY" "$CHAIN_ID" "$DENOM" <<'PY'
import csv
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

project, registry, gentx_dir, verified_dir, rejected_dir, binary, chain_id, denom = sys.argv[1:9]
project_path = Path(project)
registry = Path(registry)
gentx_dir = Path(gentx_dir)
verified_dir = Path(verified_dir)
rejected_dir = Path(rejected_dir)
verifier = Path(project) / "scripts/testnet/verify-controlled-testnet-gentx.sh"

required_fields = [
    "validator_id",
    "moniker",
    "contact",
    "operator_address",
    "account_address",
    "node_id",
    "public_host",
    "p2p_port",
    "gentx_filename",
    "gentx_sha256",
    "os_arch",
]
expected_header = [
    "validator_id",
    "moniker",
    "contact",
    "operator_address",
    "account_address",
    "node_id",
    "public_host",
    "p2p_port",
    "gentx_filename",
    "gentx_sha256",
    "build_tag",
    "build_commit",
    "os_arch",
    "status",
    "notes",
]
node_re = re.compile(r"^[0-9a-fA-F]{40}$")

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def nonempty(value):
    return value is not None and str(value).strip() != ""

def write_outputs(summary):
    verified_dir.mkdir(parents=True, exist_ok=True)
    json_path = verified_dir / "intake-validation-summary.json"
    md_path = verified_dir / "intake-validation-summary.md"
    with open(json_path, "w") as f:
        json.dump(summary, f, indent=2)
        f.write("\n")

    lines = [
        "# Validator Intake Validation Summary",
        "",
        f"- Network: `{summary['chain_id']}`",
        f"- Status: {summary['status']}",
        f"- Validators submitted: {summary['submitted_count']}",
        f"- Gentxs verified: {summary['verified_count']}",
        f"- Gentxs rejected: {summary['rejected_count']}",
        f"- Waiting count: {summary['waiting_count']}",
        "",
        "| Validator ID | Moniker | Status | Reasons |",
        "|---|---|---|---|",
    ]
    for item in summary["validators"]:
        reasons = "<br>".join(item.get("reasons", [])) if item.get("reasons") else "-"
        lines.append(f"| {item.get('validator_id', '')} | {item.get('moniker', '')} | {item.get('status', '')} | {reasons} |")
    if not summary["validators"]:
        lines.append("| - | - | WAITING | No validator intake rows submitted. |")
    lines.extend([
        "",
        "No private keys, mnemonics, node keys, validator signing keys, keyrings, node data, or database files are required for this validation.",
    ])
    with open(md_path, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Summary JSON: {json_path}")
    print(f"Summary MD: {md_path}")

def display_path(path):
    path = Path(path)
    try:
        return str(path.resolve().relative_to(project_path.resolve()))
    except ValueError:
        return str(path)

if not registry.exists():
    print(f"FAIL registry not found: {registry}", file=sys.stderr)
    sys.exit(1)

with open(registry, newline="") as f:
    reader = csv.DictReader(f)
    header = reader.fieldnames or []
    rows = [row for row in reader if any(nonempty(v) for v in row.values())]

header_missing = [field for field in expected_header if field not in header]
summary = {
    "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "chain_id": chain_id,
    "registry": display_path(registry),
    "gentx_dir": display_path(gentx_dir),
    "status": "WAITING",
    "submitted_count": len(rows),
    "verified_count": 0,
    "rejected_count": 0,
    "waiting_count": 0,
    "header_missing": header_missing,
    "validators": [],
}

if header_missing:
    summary["status"] = "FAIL"
    summary["rejected_count"] = len(rows)
    summary["validators"].append({
        "validator_id": "registry",
        "moniker": "registry",
        "status": "FAIL",
        "reasons": [f"missing CSV columns: {', '.join(header_missing)}"],
    })
    write_outputs(summary)
    print(f"FAIL missing CSV columns: {', '.join(header_missing)}", file=sys.stderr)
    sys.exit(1)

if not rows:
    summary["status"] = "WAITING"
    summary["waiting_count"] = 0
    write_outputs(summary)
    print("WAITING no validator intake rows submitted")
    sys.exit(0)

for row in rows:
    validator_id = (row.get("validator_id") or "").strip()
    moniker = (row.get("moniker") or "").strip()
    result = {
        "validator_id": validator_id,
        "moniker": moniker,
        "status": "PASS",
        "reasons": [],
    }

    missing = [field for field in required_fields if not nonempty(row.get(field))]
    if missing:
        result["reasons"].append(f"missing required fields: {', '.join(missing)}")

    if not nonempty(row.get("build_tag")) and not nonempty(row.get("build_commit")):
        result["reasons"].append("missing build_tag or build_commit")

    node_id = (row.get("node_id") or "").strip()
    if node_id and not node_re.match(node_id):
        result["reasons"].append("node_id must be 40 hex chars")

    port = (row.get("p2p_port") or "").strip()
    if port and (not port.isdigit() or int(port) <= 0 or int(port) > 65535):
        result["reasons"].append("p2p_port must be numeric and between 1 and 65535")

    gentx_name = (row.get("gentx_filename") or "").strip()
    gentx_path = None
    if gentx_name:
        if os.path.basename(gentx_name) != gentx_name:
            result["reasons"].append("gentx_filename must be a file name, not a path")
        else:
            gentx_path = gentx_dir / gentx_name
            if not gentx_path.exists():
                result["reasons"].append(f"gentx file not found: {gentx_name}")

    expected_sha = (row.get("gentx_sha256") or "").strip().lower()
    if expected_sha and not re.match(r"^[0-9a-f]{64}$", expected_sha):
        result["reasons"].append("gentx_sha256 must be 64 lowercase hex chars")

    if gentx_path and gentx_path.exists() and expected_sha:
        actual_sha = sha256(gentx_path)
        if actual_sha != expected_sha:
            result["reasons"].append(f"gentx SHA256 mismatch: expected {expected_sha} got {actual_sha}")

    if gentx_path and gentx_path.exists() and not result["reasons"]:
        cmd = [str(verifier), str(gentx_path), "--binary", binary, "--chain-id", chain_id, "--denom", denom]
        proc = subprocess.run(cmd, text=True, capture_output=True)
        if proc.returncode != 0:
            fail_lines = [
                line.strip()
                for line in (proc.stdout + "\n" + proc.stderr).splitlines()
                if line.strip().startswith("FAIL")
            ]
            result["reasons"].extend(fail_lines or [f"gentx verifier failed with exit code {proc.returncode}"])

    if result["reasons"]:
        result["status"] = "FAIL"
        summary["rejected_count"] += 1
        if gentx_path and gentx_path.exists():
            dest = rejected_dir / gentx_path.name
            if gentx_path.resolve() != dest.resolve():
                shutil.copy2(gentx_path, dest)
            reason_id = validator_id or moniker or gentx_path.stem
            with open(rejected_dir / f"{reason_id}.reason.txt", "w") as f:
                f.write("\n".join(result["reasons"]) + "\n")
        print(f"FAIL {validator_id or moniker}: {'; '.join(result['reasons'])}")
    else:
        summary["verified_count"] += 1
        dest = verified_dir / gentx_path.name
        if gentx_path.resolve() != dest.resolve():
            shutil.copy2(gentx_path, dest)
        print(f"PASS {validator_id or moniker}: gentx verified")

    summary["validators"].append(result)

if summary["rejected_count"] > 0:
    summary["status"] = "FAIL"
elif summary["verified_count"] > 0:
    summary["status"] = "PASS"
else:
    summary["status"] = "WAITING"

write_outputs(summary)
sys.exit(1 if summary["status"] == "FAIL" else 0)
PY
