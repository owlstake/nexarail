# NexaRail Known Limitations Index

## Release Candidate Status
- RC1 is public for controlled local evaluation.
- `v0.1.0-rc1-cli-hotfix` is the current public source tag for validator CLI helper commands.
- RC2 is under evaluation and should not be tagged until the canonical one-hour soak rerun and targeted post-fix governance/product-flow replay are complete.

## Devnet Limitations
- RC1 binaries (`v0.1.0-rc1`) shipped without the `tendermint`/`comet`/`cometbft` helper command group, so `tendermint show-node-id` and related helpers return `unknown command`. Source builds need `v0.1.0-rc1-cli-hotfix` or later; see `docs/release/VALIDATOR_CLI_HOTFIX_NOTES.md`.
- Prebuilt hotfix binary upload remains blocked by GitHub release-token permissions; external-validator onboarding uses source builds until assets and checksums are published.
- RC1 binaries are single-node oriented; post-RC1 `main` includes local five-agent validator-agent evidence
- Five-agent evidence is local single-machine evidence only
- Voting period shortened to 30 seconds (not realistic for mainnet)
- No persistent validator set management across restarts
- REST API gateway uses default Cosmos SDK proxy (limited configurability)

## REST API Limitations
See [REST Readback Limitations](../api/REST_READBACK_LIMITATIONS.md) for full list.
- Read-only queries only — no TX submission via REST
- Single-node REST gateway is unreliable for some complex queries
- Some governance-executed events have limited indexing

## SDK Package Limitations
- Version 0.1.0-dev — API not yet stable
- Local install only — NOT published to npm or PyPI
- No wallet integration
- No private key or mnemonic handling
- No TX execution from SDK — command builders return strings only
- Node.js SDK requires ESM and Node 18+
- Python SDK requires Python 3.9+ and stdlib only

## Public Testnet Limitations
- Controlled external-validator testnet launch: NOT LAUNCHED
- Phase 17A local dry-run passed with five local validators through height 20
- Phase 17B intake workflow is ready, but no external validator records or gentxs are submitted yet
- Phase 18A internal coordinator candidate is rehearsal-only and is not final public genesis
- NodeSync public metadata and gentx have been received and verified; DNS peer is confirmed and the gentx memo IP difference is noted
- Phase 18B final genesis freeze decision is `FREEZE_DEFER` because no external gentxs are verified
- Endpoint inventory contains NodeSync P2P-only DNS metadata; RPC/API/gRPC endpoints remain pending
- Launch-window template is prepared, but launch date/time remains pending
- Requires: accepted validator intake, external gentxs, final genesis, persistent peers, launch window, monitoring, and coordinator evidence

## Mainnet Limitations
- Mainnet: NO-GO
- Requires: public testnet, external validator evidence, community governance, legal/economic review

## External Validator Limitations
- External validators: PENDING
- ValConsensus-based validator set supported but untested with external nodes
- No accepted external validator has been configured or run against this chain
- One external gentx has been verified, but no final controlled-testnet genesis candidate has been frozen
- External decentralisation is not claimed until accepted external validators are running and evidenced

## Governance Limitations
- On-chain governance exists but has not been tested with external proposers
- Governance UX is script-heavy
- Product toggle proposals require exact parameter JSON construction
- Phase 16A.7 fixed local vote routing/sequence handling, but a targeted post-fix replay remains recommended before RC2 tag

## Audit and Legal
- No external security audit has been performed
- No legal review has been performed
- No token economics audit has been performed

## Publishing
- npm: NOT PUBLISHED
- PyPI: NOT PUBLISHED
- Docker: NO DOCKER IMAGE

## Additional
- Burn routing has local product-flow evidence, but remains devnet-only
- Dashboard is read-only static HTML — no live data refresh
- Portal is static HTML — no server-side rendering
- Developer bundle is generated locally — not distributed via CDN
