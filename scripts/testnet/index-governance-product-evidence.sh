#!/usr/bin/env bash
# NexaRail Phase 10B.2 - governance product-evidence indexer.
#
# TESTNET/DEVNET ONLY. Reads product-flow evidence and links governance
# proposals to expected product-flow effects and supporting readback evidence.
# Produces JSON + Markdown with evidence classification: DIRECT, INDIRECT, MISSING.
set -Eeuo pipefail

EVIDENCE_DIR=""

usage() {
    cat <<EOF
Usage: scripts/testnet/index-governance-product-evidence.sh --evidence-dir PATH
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

python3 - "$EVIDENCE_DIR" "$EVIDENCE_DIR/governance-product-evidence.json" "$EVIDENCE_DIR/governance-product-evidence.md" <<'PY'
import json
import pathlib
import re
import sys
import time

root = pathlib.Path(sys.argv[1]).resolve()
out_json = pathlib.Path(sys.argv[2])
out_md = pathlib.Path(sys.argv[3])


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


def text(path):
    try:
        return path.read_text(encoding="utf-8", errors="ignore").strip()
    except Exception:
        return ""


# ---------------------------------------------------------------------------
# Module / action parsing
# ---------------------------------------------------------------------------

def affected_module(label):
    if label.startswith("restore-"):
        if "settlement" in label:
            return "settlement"
        if "escrow" in label:
            return "escrow"
        if "treasury" in label:
            return "treasury"
        if "payout" in label:
            return "payout"
    for name in ["merchant", "settlement", "escrow", "treasury", "payout", "fees"]:
        if name in label:
            return name
    return "unknown"


def expected_change(label):
    rules = [
        ("merchant-inactive", "merchant status becomes inactive"),
        ("merchant-active", "merchant status becomes active"),
        ("settlement-live-enable", "settlement live_enabled=true"),
        ("settlement-live-disable", "settlement live_enabled=false"),
        ("settlement-treasury-routing-enable", "settlement live_enabled=true and treasury_routing_enabled=true"),
        ("settlement-treasury-routing-disable", "settlement routing flags restored false"),
        ("settlement-burn-routing-enable", "settlement live_enabled=true, treasury_routing_enabled=true, burn_routing_enabled=true"),
        ("settlement-burn-routing-disable", "settlement routing flags restored false"),
        ("escrow-enable-live", "escrow live_enabled=true"),
        ("escrow-disable-live", "escrow live_enabled=false"),
        ("treasury-enable-live", "treasury live_enabled=true"),
        ("treasury-disable-live", "treasury live_enabled=false"),
        ("treasury-create-account", "treasury account created"),
        ("treasury-create-budget", "treasury budget created"),
        ("treasury-approve-execute-spend", "treasury spend approved and executed"),
        ("payout-enable-live", "payout live_enabled=true"),
        ("payout-disable-live", "payout live_enabled=false"),
        ("payout-mark-paid", "payout marked paid and funds transferred"),
        ("restore-settlement-flags-false", "settlement live/routing flags false"),
        ("restore-escrow-live-false", "escrow live_enabled=false"),
        ("restore-treasury-live-false", "treasury live_enabled=false"),
        ("restore-payout-live-false", "payout live_enabled=false"),
        ("prereq-settlement-enable", "temporary settlement routing enabled for treasury funding prerequisite"),
        ("prereq-settlement-disable", "temporary settlement routing disabled after funding prerequisite"),
    ]
    for needle, detail in rules:
        if needle in label:
            return detail
    return "expected effect derived from proposal JSON and state readback"


def expected_values(label):
    """Return (expected_before_value, expected_after_value) parsed from label."""
    rules = [
        ("merchant-inactive", "active", "inactive"),
        ("merchant-active", "inactive", "active"),
        ("settlement-live-enable", "live_enabled=false", "live_enabled=true"),
        ("settlement-live-disable", "live_enabled=true", "live_enabled=false"),
        ("settlement-treasury-routing-enable",
         "live_enabled=false, treasury_routing_enabled=false",
         "live_enabled=true, treasury_routing_enabled=true"),
        ("settlement-treasury-routing-disable",
         "routing flags true",
         "routing flags false"),
        ("settlement-burn-routing-enable",
         "live_enabled=false, routing flags false",
         "live_enabled=true, treasury_routing+burn_routing=true"),
        ("settlement-burn-routing-disable",
         "routing flags true",
         "routing flags false"),
        ("escrow-enable-live", "live_enabled=false", "live_enabled=true"),
        ("escrow-disable-live", "live_enabled=true", "live_enabled=false"),
        ("treasury-enable-live", "live_enabled=false", "live_enabled=true"),
        ("treasury-disable-live", "live_enabled=true", "live_enabled=false"),
        ("treasury-create-account", "no account", "account created"),
        ("treasury-create-budget", "no budget", "budget created"),
        ("treasury-approve-execute-spend", "spend pending", "spend executed"),
        ("payout-enable-live", "live_enabled=false", "live_enabled=true"),
        ("payout-disable-live", "live_enabled=true", "live_enabled=false"),
        ("payout-mark-paid", "payout unpaid", "payout marked paid"),
        ("restore-settlement-flags-false",
         "various live/routing true",
         "all live/routing false"),
        ("restore-escrow-live-false", "live_enabled=true", "live_enabled=false"),
        ("restore-treasury-live-false", "live_enabled=true", "live_enabled=false"),
        ("restore-payout-live-false", "live_enabled=true", "live_enabled=false"),
        ("prereq-settlement-enable", "routing disabled", "routing enabled for prereq"),
        ("prereq-settlement-disable", "routing enabled for prereq", "routing disabled after prereq"),
    ]
    for needle, before, after in rules:
        if needle in label:
            return before, after
    return "unknown", "unknown"


# ---------------------------------------------------------------------------
# Evidence file discovery
# ---------------------------------------------------------------------------

def candidate_files(module, label, direction):
    patterns = []
    if direction == "before":
        patterns = ["*before*.json", "*pre-flags*.json", "*query-existing*.json"]
    else:
        patterns = ["*after*.json", "*post*.json", "*query*.json", "*final*.json", "final-live-flags.json"]
    matches = []
    module_roots = [root / module] if (root / module).exists() else []
    if module == "settlement":
        module_roots.append(root / "settlement")
    if "prereq" in label:
        module_roots.append(root / "preflight")
    module_roots.append(root / "final-state")
    for base in module_roots:
        if not base.exists():
            continue
        for pattern in patterns:
            for path in sorted(base.rglob(pattern)):
                if path.is_file() and len(matches) < 12:
                    matches.append(rel(path))
    return matches


def balance_delta_files(module, label):
    roots = []
    if module != "unknown" and (root / module).exists():
        roots.append(root / module)
    if module == "settlement":
        roots.append(root / "settlement")
    if module in {"treasury", "payout"}:
        roots.append(root / module)
        roots.append(root / "preflight")
    files = []
    for base in roots:
        if not base.exists():
            continue
        for path in sorted(base.rglob("*delta.txt")):
            if len(files) < 12:
                files.append(rel(path))
    return files


def related_product_flow_txs(proposal_dir):
    """Scan sibling directories for txhash.txt files from related product flows."""
    flows = []
    for sibling in sorted(proposal_dir.parent.iterdir()):
        if not sibling.is_dir() or sibling == proposal_dir:
            continue
        txpath = sibling / "txhash.txt"
        if txpath.exists():
            flows.append({
                "flow_label": sibling.name,
                "tx_hash": text(txpath),
                "tx_file": rel(txpath),
            })
    return flows


def indirect_module_evidence(proposal_dir, module, label):
    """Look for state query files inside the proposal directory when direct module
    event evidence is unavailable (fallback / indirect evidence path)."""
    if not module or module == "unknown":
        return []
    patterns = ["*query*.json", "*state*.json", "*readback*.json",
                "*final*.json", "*flags*.json", "*live*.json"]
    files = []
    for pattern in patterns:
        for path in sorted(proposal_dir.rglob(pattern)):
            if path.is_file() and len(files) < 12:
                files.append(rel(path))
    return files


def classify_evidence(state_query_after, balance_delta, final_status, state_query_before):
    """Classify as direct_event, indirect_proposal_state, or missing."""
    if state_query_after or balance_delta:
        return "direct_event"
    if final_status or state_query_before:
        return "indirect_proposal_state"
    return "missing"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

records = []
for proposal_id_file in sorted(root.rglob("proposal-id.txt")):
    proposal_dir = proposal_id_file.parent
    label = proposal_dir.name
    module = affected_module(label)
    exp_before, exp_after = expected_values(label)

    final_status = ""
    final_status_file = proposal_dir / "proposal-final-status.json"
    if final_status_file.exists():
        data = load_json(final_status_file) or {}
        final_status = data.get("proposal", data).get("status", "")

    votes = []
    vote_hash_file = proposal_dir / "vote-tx-hashes.txt"
    if vote_hash_file.exists():
        for line in text(vote_hash_file).splitlines():
            parts = line.split()
            if len(parts) >= 2:
                votes.append({"voter": parts[0], "tx_hash": parts[1]})

    submit_hash = text(proposal_dir / "txhash.txt")
    proposal_json = proposal_dir / "proposal.json"
    state_before = candidate_files(module, label, "before")
    state_after = candidate_files(module, label, "after")
    delta = balance_delta_files(module, label)
    ev_class = classify_evidence(state_after, delta, final_status, state_before)
    related_flows = related_product_flow_txs(proposal_dir)
    indirect_ev = indirect_module_evidence(proposal_dir, module, label)

    records.append({
        "label": label,
        "proposal_id": text(proposal_id_file),
        "affected_module": module,
        "expected_state_change": expected_change(label),
        "expected_before_value": exp_before,
        "expected_after_value": exp_after,
        "proposal_tx_link": submit_hash,
        "submit_tx_hash": submit_hash,
        "submit_tx_file": rel(proposal_dir / "submit-tx.json") if (proposal_dir / "submit-tx.json").exists() else "",
        "vote_txs": votes,
        "proposal_final_state": final_status,
        "proposal_json": rel(proposal_json) if proposal_json.exists() else "",
        "state_query_before": state_before,
        "state_query_after": state_after,
        "balance_delta_evidence": delta,
        "evidence_classification": ev_class,
        "related_product_flow_txs": related_flows,
        "indirect_module_evidence": indirect_ev,
        "proof_model": "indirect proof via proposal pass + state/balance readback",
    })

# Count classification
direct_count = sum(1 for r in records if r["evidence_classification"] == "direct_event")
indirect_count = sum(1 for r in records if r["evidence_classification"] == "indirect_proposal_state")
missing_count = sum(1 for r in records if r["evidence_classification"] == "missing")

summary = {
    "generated_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "evidence_root": str(root),
    "proposal_count": len(records),
    "classification": {
        "direct_event_evidence": direct_count,
        "indirect_proposal_state_evidence": indirect_count,
        "missing_event_evidence": missing_count,
    },
    "records": records,
}
out_json.write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n", encoding="utf-8")

# ---------------------------------------------------------------------------
# Markdown report
# ---------------------------------------------------------------------------

lines = [
    "# Governance Product Evidence Index",
    "",
    f"- Evidence root: `{root}`",
    f"- Generated UTC: {summary['generated_at_utc']}",
    f"- Proposal count: {len(records)}",
    "",
    "## Classification Summary",
    "",
    f"| Classification | Count |",
    "|---:|---|",
    f"| **direct_event_evidence** | {direct_count} |",
    f"| **indirect_proposal_state_evidence** | {indirect_count} |",
    f"| **missing_event_evidence** | {missing_count} |",
    "",
    "## Proposal Overview",
    "",
    "| Proposal | Label | Module | Classification | Before Value | After Value | Final state | Expected change | Submit tx |",
    "|---:|---|---|---|---|---|---|---|---|",
]
for r in records:
    ev_class_badge = {
        "direct_event": "✅ DIRECT",
        "indirect_proposal_state": "⚠️ INDIRECT",
        "missing": "❌ MISSING",
    }.get(r["evidence_classification"], r["evidence_classification"])
    lines.append(
        f"| {r['proposal_id']} | `{r['label']}` "
        f"| {r['affected_module']} "
        f"| {ev_class_badge} "
        f"| `{r['expected_before_value']}` "
        f"| `{r['expected_after_value']}` "
        f"| {r['proposal_final_state'] or 'unknown'} "
        f"| {r['expected_state_change']} "
        f"| `{r['proposal_tx_link']}` |"
    )

lines.extend(["", "## Evidence Links", ""])
for r in records:
    ev_class_icon = {
        "direct_event": "✅",
        "indirect_proposal_state": "⚠️",
        "missing": "❌",
    }.get(r["evidence_classification"], "❓")
    lines.append(f"### {ev_class_icon} Proposal {r['proposal_id']} - `{r['label']}`")
    lines.append(f"- **Evidence classification**: {r['evidence_classification']}")
    lines.append(f"- **Expected before**: `{r['expected_before_value']}` → **Expected after**: `{r['expected_after_value']}`")
    lines.append(f"- Proposal JSON: `{r['proposal_json']}`")
    lines.append(f"- Proposal tx: `{r['proposal_tx_link']}`")
    lines.append(f"- Submit tx file: `{r['submit_tx_file']}`")
    lines.append(f"- Vote txs: {len(r['vote_txs'])}")
    lines.append(f"- State query before: {', '.join('`'+p+'`' for p in r['state_query_before']) or 'not isolated'}")
    lines.append(f"- State query after: {', '.join('`'+p+'`' for p in r['state_query_after']) or 'not isolated'}")
    lines.append(f"- Balance delta evidence: {', '.join('`'+p+'`' for p in r['balance_delta_evidence']) or 'none'}")
    if r["related_product_flow_txs"]:
        flow_lines = []
        for f in r["related_product_flow_txs"]:
            flow_lines.append(f"`{f['flow_label']}` → `{f['tx_hash']}`")
        lines.append(f"- Related product flow txs: {', '.join(flow_lines)}")
    else:
        lines.append("- Related product flow txs: none")
    if r["indirect_module_evidence"]:
        lines.append(f"- Indirect module evidence: {', '.join('`'+p+'`' for p in r['indirect_module_evidence'])}")
    else:
        lines.append("- Indirect module evidence: none")
    lines.append("")

out_md.write_text("\n".join(lines), encoding="utf-8")
PY

echo "governance evidence index written: $EVIDENCE_DIR/governance-product-evidence.json"
