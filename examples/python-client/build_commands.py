#!/usr/bin/env python3
"""
build_commands.py

Builds example CLI command strings using the NexaRail Python command builders.
Prints them with section headers for reference.

⚠  LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS ⚠
These commands build strings only — nothing is executed.
"""

from nexarail_client import (
    bank_send_cmd,
    merchant_register_cmd,
    settlement_create_cmd,
    escrow_create_cmd,
    escrow_release_cmd,
    escrow_dispute_cmd,
    payout_create_cmd,
    payout_mark_paid_cmd,
    treasury_spend_request_cmd,
    product_gov_cmd,
)

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

def heading(title):
    print()
    print("=" * 72)
    print(f"  {title}")
    print("=" * 72)


def subheading(text):
    print()
    print(f"  \u25ba {text}")
    print(f"  {'-' * min(len(text) + 4, 72)}")


# ---------------------------------------------------------------------------
# Disclaimer
# ---------------------------------------------------------------------------

print()
print("\u2554" + "\u2550" * 70 + "\u2557")
print("\u2551" + "  \u26a0  LOCAL DEVNET ONLY \u2014 NOT MAINNET \u2014 NO REAL FUNDS".ljust(70) + "\u2551")
print("\u2551" + "  These are command-string BUILDERS. Nothing is executed.".ljust(70) + "\u2551")
print("\u2551" + "  Default binary: releases/testnet-rc1/binaries/nexaraild-darwin-arm64".ljust(70) + "\u2551")
print("\u255a" + "\u2550" * 70 + "\u255d")

# ---------------------------------------------------------------------------
# 1. Bank Send
# ---------------------------------------------------------------------------

heading("1. BANK SEND")

subheading("Default devnet paths (Mac ARM binary)")
print(bank_send_cmd("my-key", "nxr1recipient", 1000000, "unxrl"))

subheading("Custom binary / home")
print(bank_send_cmd(
    "validator-key", "nxr1partner", 500000, "unxrl",
    binary="./build/nexaraild",
    home="~/.nexarail-testnet",
    chain_id="nexarail-testnet-1",
))

# ---------------------------------------------------------------------------
# 2. Merchant Register
# ---------------------------------------------------------------------------

heading("2. MERCHANT REGISTER")

subheading("Register a new merchant")
print(merchant_register_cmd(
    "merchant-owner",
    "Acme Rail Logistics",
    "Premium rail logistics provider for the NexaRail ecosystem",
    website="https://acme.example.com",
))

subheading("Minimal registration")
print(merchant_register_cmd("my-key", "Quick Haul", "Express freight services"))

# ---------------------------------------------------------------------------
# 3. Settlement Create
# ---------------------------------------------------------------------------

heading("3. SETTLEMENT CREATE")

subheading("Create settlement payment")
print(settlement_create_cmd(
    "payer-key",
    "nxr1merchant",
    1000000,
    "Order #12345 - Freight services",
))

subheading("Settlement with alternative denom")
print(settlement_create_cmd(
    "payer-key",
    "nxr1merchant",
    "5000000",
    "Invoice INV-2026-05",
    denom="unxrl",
    chain_id="nexarail-testnet-1",
))

# ---------------------------------------------------------------------------
# 4. Escrow Create
# ---------------------------------------------------------------------------

heading("4. ESCROW CREATE")

subheading("Create escrow between buyer and seller")
print(escrow_create_cmd(
    "buyer-key",
    "nxr1seller",
    "merchant-1",
    2000000,
    "Invoice ABC - 30-day net",
    escrow_id="escrow-order-001",
))

subheading("Escrow with defaults")
print(escrow_create_cmd("buyer-key", "nxr1seller", "merchant-1", 1000000, "Payment ref"))

# ---------------------------------------------------------------------------
# 5. Escrow Release
# ---------------------------------------------------------------------------

heading("5. ESCROW RELEASE")

subheading("Release escrow as buyer")
print(escrow_release_cmd("escrow-order-001", from_addr="buyer-key", reference="Goods received"))

subheading("Release escrow as authority")
print(escrow_release_cmd("escrow-order-001", from_addr="gov-addr", reference="Dispute resolved"))

# ---------------------------------------------------------------------------
# 6. Escrow Dispute
# ---------------------------------------------------------------------------

heading("6. ESCROW DISPUTE")

subheading("Open a dispute")
print(escrow_dispute_cmd(
    "escrow-order-001",
    "Goods not delivered within agreed timeframe",
    from_addr="buyer-key",
))

# ---------------------------------------------------------------------------
# 7. Payout Create
# ---------------------------------------------------------------------------

heading("7. PAYOUT CREATE")

subheading("Create merchant payout")
print(payout_create_cmd(
    "merchant-1",
    "nxr1recipient",
    500000,
    "Commission payout Q2 2026",
    payout_id="payout-Q2-001",
    payout_type=0,
    from_addr="merchant-key",
))

subheading("Batch-style payout with custom type")
print(payout_create_cmd(
    "merchant-1",
    "nxr1partner",
    "750000",
    "Revenue share - May 2026",
    payout_id="rev-share-001",
    payout_type=1,
    from_addr="merchant-key",
))

# ---------------------------------------------------------------------------
# 8. Payout Mark Paid
# ---------------------------------------------------------------------------

heading("8. PAYOUT MARK PAID")

subheading("Mark payout as paid (authority only)")
print(payout_mark_paid_cmd("payout-Q2-001", ext_ref="ACH-txn-98765", from_addr="authority-key"))

# ---------------------------------------------------------------------------
# 9. Treasury Spend Request
# ---------------------------------------------------------------------------

heading("9. TREASURY SPEND REQUEST")

subheading("Create a treasury spend request")
print(treasury_spend_request_cmd(
    "operations-fund",
    "nxr1vendor",
    2500000,
    "Infrastructure maintenance grant",
    request_id="spend-grant-001",
    from_addr="treasury-manager",
))

subheading("Spend request for community pool")
print(treasury_spend_request_cmd(
    "community-pool",
    "nxr1community-member",
    "10000000",
    "Community development initiative",
    request_id="spend-community-01",
    from_addr="council-key",
    chain_id="nexarail-mainnet-1",
))

# ---------------------------------------------------------------------------
# 10. Product Governance
# ---------------------------------------------------------------------------

heading("10. PRODUCT GOVERNANCE")

subheading("Submit governance proposal")
print(product_gov_cmd(
    "submit-proposal",
    from_addr="gov-proposer",
    proposal_file="./proposals/update_fee_params.json",
))

subheading("Deposit to proposal")
print(product_gov_cmd(
    "deposit",
    from_addr="gov-proposer",
    proposal_id="1",
    deposit="10000000unxrl",
))

subheading("Vote on proposal")
print(product_gov_cmd(
    "vote",
    from_addr="validator-key",
    proposal_id="1",
    vote_option="yes",
))

# ---------------------------------------------------------------------------
# Final reminder
# ---------------------------------------------------------------------------

print()
print("\u2554" + "\u2550" * 70 + "\u2557")
print("\u2551" + "  \u26a0  These are STRING BUILDERS \u2014 nothing was executed.".ljust(70) + "\u2551")
print("\u2551" + "  Copy-paste commands to your devnet terminal to run them.".ljust(70) + "\u2551")
print("\u2551" + "  LOCAL DEVNET ONLY \u2014 NOT MAINNET \u2014 NO REAL FUNDS".ljust(70) + "\u2551")
print("\u255a" + "\u2550" * 70 + "\u255d")
print()
