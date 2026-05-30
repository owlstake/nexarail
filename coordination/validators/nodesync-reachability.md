# NodeSync Reachability Tracker

**Validator:** NodeSync
**Network:** `nexarail-testnet-1`
**Status:** NOT_REACHABLE
**Last checked UTC:** 2026-05-30T01:19:37Z

## Persistent Peer

```text
2bb62d82b4dbf820fdafd843816f1e72a84ffa8f@nexarail-testnet-peer.nodesync.top:26656
```

## DNS Result

```text
nexarail-testnet-peer.nodesync.top -> 178.104.162.88
```

## TCP Result

```text
nexarail-testnet-peer.nodesync.top:26656 - connection refused
178.104.162.88:26656 - connection refused
```

## Requested Validator Action

Open and confirm listening on TCP `26656` for `nexarail-testnet-peer.nodesync.top`, then notify the coordinator for another reachability check.

## Next Recheck Command

```bash
dig +short nexarail-testnet-peer.nodesync.top
nc -vz nexarail-testnet-peer.nodesync.top 26656
nc -vz 178.104.162.88 26656
```

## Freeze Impact

Final public genesis freeze remains `FREEZE_DEFER` while NodeSync P2P TCP reachability is not confirmed. This tracker is preparation evidence only; it does not indicate that the controlled external-validator testnet is live.
