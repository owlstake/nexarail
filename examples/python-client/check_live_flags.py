#!/usr/bin/env python3
"""Check live_enabled flags on all 4 NexaRail modules."""

import nexarail_client as nxc


def main():
    print("=== NexaRail Devnet — Live Flag Check (Python) ===\n")

    modules = ["settlement", "escrow", "treasury", "payout"]
    results = {}

    for mod in modules:
        try:
            params = nxc.get_params(mod)
            live = params.get("live_enabled")
            extra = {}
            if mod == "settlement" and params:
                extra["treasury_routing"] = params.get("treasury_routing_enabled")
                extra["burn_routing"] = params.get("burn_routing_enabled")
            results[mod] = {"live": live, **extra}

            line = f"  {mod:<12} live_enabled: {live}"
            if mod == "settlement":
                line += (
                    f"  treasury_routing: {extra.get('treasury_routing', '?')}"
                    f"  burn_routing: {extra.get('burn_routing', '?')}"
                )
            print(line)
        except Exception as e:
            results[mod] = {"error": str(e)}
            print(f"  {mod:<12} ERROR: {e}")

    # Summary: all should be false (devnet not live)
    pass_ = True
    count = 0
    for mod, r in results.items():
        if "error" in r:
            pass_ = False
            continue
        if r.get("live") is True:
            pass_ = False
        count += 1

    print("")
    print(f"  Summary: {'PASS' if pass_ else 'FAIL'} ({count}/{len(modules)} modules checked)")
    if not pass_:
        flagged = [m for m, r in results.items() if r.get("live") is True]
        if flagged:
            print(f"  Flagged as live: {', '.join(flagged)}")

    # Also check node status for context
    try:
        ns = nxc.node_status()
        print(f"\n  Node: height={ns.get('sync_info', {}).get('latest_block_height', '?')}  "
              f"chain={ns.get('node_info', {}).get('network', '?')}")
    except Exception:
        print("\n  Node status: unreachable")


if __name__ == "__main__":
    main()
