#!/usr/bin/env python3
"""Query full NexaRail product state: node, treasury, merchants, settlements, escrows, payouts."""

import json
import nexarail_client as nxc


def print_section(title):
    print(f"\n--- {title} ---")


def main():
    print("=== NexaRail Devnet — Full Product State (Python) ===")

    # 1. Node status
    print_section("Node Status")
    try:
        ns = nxc.node_status()
        print(f"  Height:        {ns.get('sync_info', {}).get('latest_block_height', '?')}")
        print(f"  Chain ID:      {ns.get('node_info', {}).get('network', '?')}")
        print(f"  Validator:     {ns.get('validator_info', {}).get('address', '?')}")
        print(f"  Catch-up:      {ns.get('sync_info', {}).get('catching_up', '?')}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 2. Treasury summary
    print_section("Treasury Summary")
    try:
        ts = nxc.treasury_summary()
        for k, v in ts.items():
            print(f"  {k}: {v}")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 3. Merchant list
    print_section("Merchant List")
    try:
        merchants = nxc.get_list("treasury", "merchant")
        items = merchants.get("merchant") or merchants.get("list") or []
        if isinstance(items, dict):
            items = [items]
        print(f"  Count: {len(items)}")
        for m in items[:5]:
            print(f"    - {json_dumps(m, 200)}")
        if len(items) > 5:
            print(f"    ... and {len(items) - 5} more")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 4. Settlement list
    print_section("Settlement List")
    try:
        settlements = nxc.get_list("settlement", "settlement")
        items = settlements.get("settlement") or settlements.get("list") or []
        if isinstance(items, dict):
            items = [items]
        print(f"  Count: {len(items)}")
        for s in items[:5]:
            print(f"    - {json_dumps(s, 200)}")
        if len(items) > 5:
            print(f"    ... and {len(items) - 5} more")
    except Exception as e:
        print(f"  ERROR: {e}")

    # 5. Escrow list + exists (non-existent)
    print_section("Escrow")
    try:
        escrows = nxc.get_list("escrow", "escrow")
        items = escrows.get("escrow") or escrows.get("list") or []
        if isinstance(items, dict):
            items = [items]
        print(f"  Escrow count: {len(items)}")
        for e in items[:3]:
            print(f"    - {json_dumps(e, 200)}")
    except Exception as e:
        print(f"  ERROR: {e}")

    try:
        exists = nxc.get_exists("escrow", "escrow", "nonexistent-id")
        print(f"  Escrow exists('nonexistent-id'): {exists}")
    except Exception as e:
        print(f"  Escrow exists ERROR: {e}")

    # 6. Payout list + exists (non-existent)
    print_section("Payout")
    try:
        payouts = nxc.get_list("payout", "payout")
        items = payouts.get("payout") or payouts.get("list") or []
        if isinstance(items, dict):
            items = [items]
        print(f"  Payout count: {len(items)}")
        for p in items[:3]:
            print(f"    - {json_dumps(p, 200)}")
    except Exception as e:
        print(f"  ERROR: {e}")

    try:
        exists = nxc.get_exists("payout", "payout", "nonexistent-id")
        print(f"  Payout exists('nonexistent-id'): {exists}")
    except Exception as e:
        print(f"  Payout exists ERROR: {e}")

    # 7. Filtered query attempt
    print_section("Filtered Query (example)")
    try:
        filtered = nxc.get_filtered("settlement", "settlement", "status", "pending")
        print(f"  Settlement filtered by status=pending: {json_dumps(filtered, 300)}")
    except Exception as e:
        print(f"  Filtered query: {e}")

    print("\n=== Product state query complete ===")


def json_dumps(obj, maxlen=200):
    s = json.dumps(obj, indent=2)
    return s[:maxlen] + ("..." if len(s) > maxlen else "")


if __name__ == "__main__":
    main()
