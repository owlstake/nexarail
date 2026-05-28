import json
import os
import urllib.request
import urllib.error
import sys


def api_url():
    return os.environ.get("API", "http://localhost:1317")


def rpc_url():
    return os.environ.get("RPC", "http://localhost:26657")


def get(path):
    url = f"{api_url()}{path}"
    try:
        with urllib.request.urlopen(url, timeout=5) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode() if e.code != 404 else "{}"
        try:
            return json.loads(body) if body else {"error": f"HTTP {e.code}"}
        except json.JSONDecodeError:
            return {"error": f"HTTP {e.code}: {body[:200]}"}
    except Exception as e:
        return {"error": str(e)}


def get_params(module):
    return get(f"/nexarail/{module}/v1/params")


def get_list(module, resource):
    return get(f"/nexarail/{module}/v1/{resource}")


def get_detail(module, resource, id_):
    return get(f"/nexarail/{module}/v1/{resource}/{id_}")


def get_filtered(module, resource, filter_name, value):
    return get(f"/nexarail/{module}/v1/{resource}/{filter_name}/{value}")


def get_exists(module, resource, id_):
    return get(f"/nexarail/{module}/v1/{resource}/exists/{id_}")


def treasury_summary():
    return get("/nexarail/treasury/v1/summary")


def node_status():
    with urllib.request.urlopen(f"{rpc_url()}/status", timeout=5) as resp:
        return json.loads(resp.read())["result"]


# ---------------------------------------------------------------------------
# Command builders — these return CLI command strings, they do NOT execute txs
# LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS
# ---------------------------------------------------------------------------


def bank_send_cmd(
    from_addr,
    to,
    amount,
    denom="unxrl",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build a bank send command string.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f"{binary} tx bank send {from_addr} {to} {amount}{denom}"
        f" --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def merchant_register_cmd(
    owner,
    name,
    description,
    website="",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build a merchant register command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f'{binary} tx merchant register "{name}" "{description}" "{website}"'
        f" --from {owner} --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def settlement_create_cmd(
    payer,
    merchant,
    amount,
    reference,
    denom="unxrl",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build a settlement create command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f'{binary} tx settlement create {merchant} {amount}{denom}'
        f' --metadata "{reference}" --from {payer}'
        f" --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def escrow_create_cmd(
    buyer,
    seller,
    merchant,
    amount,
    reference,
    escrow_id="escrow-1",
    denom="unxrl",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build an escrow create command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f'{binary} tx escrow create {escrow_id} {seller} {merchant} {amount}{denom}'
        f' --payment-reference "{reference}" --from {buyer}'
        f" --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def escrow_release_cmd(
    escrow_id,
    from_addr="buyer",
    reference="",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build an escrow release command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    cmd = f"{binary} tx escrow release {escrow_id}"
    if reference:
        cmd += f' --release-reference "{reference}"'
    cmd += f" --from {from_addr} --chain-id {chain_id} --home {home}"
    cmd += f" --keyring-backend {keyring} --yes"
    return cmd


def escrow_dispute_cmd(
    escrow_id,
    reason,
    from_addr="buyer",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build an escrow dispute command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f'{binary} tx escrow dispute {escrow_id} "{reason}"'
        f" --from {from_addr} --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def payout_create_cmd(
    merchant,
    recipient,
    amount,
    reference,
    payout_id="payout-1",
    payout_type=0,
    denom="unxrl",
    from_addr="merchant",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build a payout create command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f'{binary} tx payout create {payout_id} {merchant} {recipient} {amount}{denom} {payout_type}'
        f' --payout-reference "{reference}" --from {from_addr}'
        f" --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def payout_mark_paid_cmd(
    payout_id,
    ext_ref="offchain-ref",
    from_addr="authority",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build a payout mark-paid command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f"{binary} tx payout mark-paid {payout_id} {ext_ref}"
        f" --from {from_addr} --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def treasury_spend_request_cmd(
    account_id,
    recipient,
    amount,
    purpose,
    request_id="spend-1",
    denom="unxrl",
    from_addr="treasury-manager",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build a treasury spend request command.

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    return (
        f'{binary} tx treasury create-spend {request_id} {account_id} {recipient} {amount}{denom} "{purpose}"'
        f" --from {from_addr} --chain-id {chain_id} --home {home}"
        f" --keyring-backend {keyring} --yes"
    )


def product_gov_cmd(
    action,
    from_addr="gov-proposer",
    proposal_file="proposal.json",
    proposal_id="1",
    deposit="10000000unxrl",
    vote_option="yes",
    binary="releases/testnet-rc1/binaries/nexaraild-darwin-arm64",
    home="~/.nexarail-devnet",
    chain_id="nexarail-devnet-1",
    keyring="test",
):
    """Build a governance command string.

    Wraps cosmos-sdk gov module for NexaRail product parameter proposals.
    Actions: submit-proposal, deposit, vote

    LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS.
    Returns a string — does NOT execute.
    """
    cmd = f"{binary} tx gov"
    if action == "submit-proposal":
        cmd += f" submit-proposal {proposal_file}"
    elif action == "deposit":
        cmd += f" deposit {proposal_id} {deposit}"
    elif action == "vote":
        cmd += f" vote {proposal_id} {vote_option}"
    else:
        cmd += f" {action}"
    cmd += f" --from {from_addr} --chain-id {chain_id} --home {home}"
    cmd += f" --keyring-backend {keyring} --yes"
    return cmd
