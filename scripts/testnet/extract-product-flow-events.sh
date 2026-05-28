#!/usr/bin/env bash
# NexaRail Phase 10B.2 - product-flow event summary extractor.
#
# TESTNET/DEVNET ONLY. Reads an existing product-flow evidence directory and
# writes event-summary.json plus event-summary.md.
set -Eeuo pipefail

EVIDENCE_DIR=""

usage() {
    cat <<EOF
Usage: scripts/testnet/extract-product-flow-events.sh --evidence-dir PATH
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

python3 - "$EVIDENCE_DIR" "$EVIDENCE_DIR/event-summary.json" "$EVIDENCE_DIR/event-summary.md" <<'PY'
import json
import pathlib
import sys
import time

root = pathlib.Path(sys.argv[1]).resolve()
out_json = pathlib.Path(sys.argv[2])
out_md = pathlib.Path(sys.argv[3])

groups = {
    "merchant": [],
    "settlement": [],
    "escrow": [],
    "treasury": [],
    "payout": [],
    "bank_transfer": [],
    "burn": [],
    "governance": [],
    "param_or_live_flag": [],
    "other": [],
}

def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None

def rel(path):
    try:
        return str(path.relative_to(root))
    except Exception:
        return str(path)

def attrs_to_dict(attrs):
    out = {}
    for attr in attrs or []:
        if not isinstance(attr, dict):
            continue
        key = str(attr.get("key", ""))
        value = str(attr.get("value", ""))
        if key:
            out.setdefault(key, []).append(value)
    return out

def classify(event_type, attrs):
    text = " ".join([event_type] + [str(k) for k in attrs] + [str(v) for values in attrs.values() for v in values]).lower()
    matched = []
    if "merchant" in text:
        matched.append("merchant")
    if "settlement" in text:
        matched.append("settlement")
    if "escrow" in text:
        matched.append("escrow")
    if "treasury" in text or "spend_request" in text or "spend" in text:
        matched.append("treasury")
    if "payout" in text:
        matched.append("payout")
    if event_type in {"coin_spent", "coin_received", "transfer"}:
        matched.append("bank_transfer")
    if event_type == "burn" or "burn_routed" in text:
        matched.append("burn")
    if "proposal" in text or "vote" in text or event_type.startswith("gov"):
        matched.append("governance")
    if "params" in text or "param" in text or "live_enabled" in text or "routing_enabled" in text:
        matched.append("param_or_live_flag")
    return matched or ["other"]

def tx_hash_from_file(path, data):
    for candidate in [
        data.get("txhash") if isinstance(data, dict) else None,
        data.get("result", {}).get("hash") if isinstance(data, dict) else None,
        data.get("tx_response", {}).get("txhash") if isinstance(data, dict) else None,
    ]:
        if candidate:
            return candidate
    txhash_file = path.parent / "txhash.txt"
    if txhash_file.exists():
        return txhash_file.read_text(encoding="utf-8", errors="ignore").strip()
    return ""

def events_from(data):
    if not isinstance(data, dict):
        return []
    if isinstance(data.get("result"), dict):
        events = data["result"].get("tx_result", {}).get("events")
        if isinstance(events, list):
            return events
    if isinstance(data.get("tx_response"), dict):
        events = data["tx_response"].get("events")
        if isinstance(events, list):
            return events
    return []

candidate_names = {"included-tx.json", "submit-tx.json"}
candidate_suffixes = ("-vote-tx.json", "broadcast-cometbft.json")
seen = set()

for path in sorted(root.rglob("*.json")):
    if path.name not in candidate_names and not path.name.endswith(candidate_suffixes):
        continue
    if path in seen:
        continue
    seen.add(path)
    data = load_json(path)
    events = events_from(data)
    if not events:
        continue
    tx_hash = tx_hash_from_file(path, data)
    flow = rel(path.parent)
    for event in events:
        event_type = str(event.get("type", "")) if isinstance(event, dict) else ""
        attrs = attrs_to_dict(event.get("attributes", []) if isinstance(event, dict) else [])
        record = {
            "event_type": event_type,
            "tx_hash": tx_hash,
            "flow": flow,
            "evidence_file": rel(path),
            "attributes": attrs,
        }
        for group in classify(event_type, attrs):
            groups[group].append(record)

governance_notes = []
for proposal_id_file in sorted(root.rglob("proposal-id.txt")):
    proposal_dir = proposal_id_file.parent
    final_status = ""
    final_status_file = proposal_dir / "proposal-final-status.json"
    if final_status_file.exists():
        data = load_json(final_status_file) or {}
        final_status = data.get("proposal", data).get("status", "")
    governance_notes.append({
        "proposal_id": proposal_id_file.read_text(encoding="utf-8", errors="ignore").strip(),
        "proposal_dir": rel(proposal_dir),
        "final_status": final_status,
        "proof_model": "indirect proof via proposal pass + state/balance readback",
    })

summary = {
    "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "evidence_root": str(root),
    "event_counts": {name: len(events) for name, events in groups.items()},
    "groups": groups,
    "governance_execution_notes": governance_notes,
}
out_json.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")

lines = [
    "# Product Flow Event Summary",
    "",
    f"- Evidence root: `{root}`",
    f"- Generated UTC: {summary['generated_at_utc']}",
    "",
    "## Counts",
    "",
    "| Group | Events |",
    "|---|---:|",
]
for name, events in groups.items():
    lines.append(f"| {name} | {len(events)} |")

lines.extend([
    "",
    "## Governance Execution Notes",
    "",
    "| Proposal | Directory | Final status | Proof model |",
    "|---:|---|---|---|",
])
for note in governance_notes:
    lines.append(
        f"| {note['proposal_id']} | `{note['proposal_dir']}` | {note['final_status'] or 'unknown'} | {note['proof_model']} |"
    )

lines.extend([
    "",
    "## Event Files",
    "",
    "| Group | Event type | Flow | Tx hash | Evidence |",
    "|---|---|---|---|---|",
])
for group_name, events in groups.items():
    for record in events[:120]:
        lines.append(
            f"| {group_name} | {record['event_type']} | `{record['flow']}` | `{record['tx_hash']}` | `{record['evidence_file']}` |"
        )
    if len(events) > 120:
        lines.append(f"| {group_name} | ... | ... | ... | {len(events) - 120} more events omitted from markdown; see JSON |")

out_md.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

echo "event summary written: $EVIDENCE_DIR/event-summary.json"
