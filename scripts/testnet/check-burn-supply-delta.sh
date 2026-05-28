#!/usr/bin/env bash
# NexaRail Phase 10B.2 - burn-routing total-supply proof.
#
# TESTNET/DEVNET ONLY. Validates burn-routing evidence captured by the product
# flow harness. It does not mutate chain state.
set -Eeuo pipefail

EVIDENCE_DIR=""

usage() {
    cat <<EOF
Usage: scripts/testnet/check-burn-supply-delta.sh --evidence-dir PATH
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --evidence-dir)
            EVIDENCE_DIR="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ -z "$EVIDENCE_DIR" ] || [ ! -d "$EVIDENCE_DIR" ]; then
    echo "missing --evidence-dir or directory does not exist: ${EVIDENCE_DIR:-}" >&2
    exit 2
fi

python3 - "$EVIDENCE_DIR" "$EVIDENCE_DIR/burn-supply-delta.json" "$EVIDENCE_DIR/burn-supply-delta.md" <<'PY'
import json
import pathlib
import re
import sys
import time

root = pathlib.Path(sys.argv[1]).resolve()
out_json = pathlib.Path(sys.argv[2])
out_md = pathlib.Path(sys.argv[3])
burn_dir = root / "settlement" / "burn-routing"

def load(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None

def amount_from_balance(path, denom="unxrl"):
    data = load(path) or {}
    balances = data.get("balances") or []
    for item in balances:
        if item.get("denom") == denom:
            return int(item.get("amount", "0"))
    amount = data.get("amount")
    if isinstance(amount, dict) and amount.get("denom") == denom:
        return int(amount.get("amount", "0"))
    return 0

def amount_from_total(path, denom="unxrl"):
    data = load(path) or {}
    amount = data.get("amount")
    if isinstance(amount, dict):
        return int(amount.get("amount", "0"))
    if isinstance(amount, str):
        return int(amount or "0")
    for item in data.get("supply", []) or []:
        if item.get("denom") == denom:
            return int(item.get("amount", "0"))
    return 0

def first_settlement_file():
    files = sorted(burn_dir.glob("settlement-*.json"))
    return files[0] if files else None

if not burn_dir.exists():
    result = {
        "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "evidence_root": str(root),
        "status": "fail",
        "reason": "settlement/burn-routing evidence directory missing",
    }
    out_json.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text("# Burn Supply Delta\n\n- Status: fail\n- Reason: settlement/burn-routing evidence directory missing\n", encoding="utf-8")
    raise SystemExit(1)

settlement_file = first_settlement_file()
settlement = (load(settlement_file) or {}).get("settlement", {}) if settlement_file else {}
burn_share = int(settlement.get("burn_share", {}).get("amount", "0") or 0)
settlement_amount = int(settlement.get("amount", {}).get("amount", "0") or 0)
fee_amount = int(settlement.get("fee_amount", {}).get("amount", "0") or 0)

supply_before = amount_from_total(burn_dir / "supply-before.json")
supply_after = amount_from_total(burn_dir / "supply-after.json")
burner_before = amount_from_balance(burn_dir / "burner-before.json")
burner_after = amount_from_balance(burn_dir / "burner-after.json")
payer_before = amount_from_balance(burn_dir / "alpha-before.json")
payer_after = amount_from_balance(burn_dir / "alpha-after.json")

checks = [
    {
        "name": "total supply decreases by burn share",
        "expected": -burn_share,
        "actual": supply_after - supply_before,
        "pass": (supply_before - supply_after) == burn_share and burn_share > 0,
    },
    {
        "name": "burner module does not retain burned funds",
        "expected": 0,
        "actual": burner_after,
        "pass": burner_after == 0,
    },
    {
        "name": "burn evidence settlement flag",
        "expected": True,
        "actual": settlement.get("burn_executed"),
        "pass": settlement.get("burn_executed") is True,
    },
]

status = "pass" if all(c["pass"] for c in checks) else "fail"
result = {
    "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "evidence_root": str(root),
    "status": status,
    "settlement_file": str(settlement_file.relative_to(root)) if settlement_file else "",
    "settlement_amount": settlement_amount,
    "fee_amount": fee_amount,
    "burn_share": burn_share,
    "total_supply_before": supply_before,
    "total_supply_after": supply_after,
    "total_supply_delta": supply_after - supply_before,
    "burner_module_balance_before": burner_before,
    "burner_module_balance_after": burner_after,
    "payer_balance_before": payer_before,
    "payer_balance_after": payer_after,
    "payer_balance_delta": payer_after - payer_before,
    "checks": checks,
}
out_json.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")

lines = [
    "# Burn Supply Delta",
    "",
    f"- Evidence root: `{root}`",
    f"- Status: {status}",
    f"- Settlement amount: {settlement_amount}",
    f"- Fee amount: {fee_amount}",
    f"- Burn share: {burn_share}",
    f"- Total supply before: {supply_before}",
    f"- Total supply after: {supply_after}",
    f"- Total supply delta: {supply_after - supply_before}",
    f"- Burner module balance before: {burner_before}",
    f"- Burner module balance after: {burner_after}",
    f"- Payer balance before: {payer_before}",
    f"- Payer balance after: {payer_after}",
    "",
    "| Check | Expected | Actual | Status |",
    "|---|---:|---:|---|",
]
for check in checks:
    lines.append(f"| {check['name']} | {check['expected']} | {check['actual']} | {'pass' if check['pass'] else 'fail'} |")
out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")

if status != "pass":
    raise SystemExit(1)
PY

echo "burn supply delta written: $EVIDENCE_DIR/burn-supply-delta.json"
