#!/usr/bin/env node
/**
 * buildCommands.js
 *
 * Builds example CLI command strings using the NexaRail command builders.
 * Prints them with section headers for reference.
 *
 * ⚠  LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS ⚠
 * These commands build strings only — nothing is executed.
 */

import {
  bankSendCmd,
  merchantRegisterCmd,
  settlementCreateCmd,
  escrowCreateCmd,
  escrowReleaseCmd,
  escrowDisputeCmd,
  payoutCreateCmd,
  payoutMarkPaidCmd,
  treasurySpendRequestCmd,
  productGovCmd,
} from './client.js';

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

function heading(title) {
  console.log(`\n${'='.repeat(72)}`);
  console.log(`  ${title}`);
  console.log(`${'='.repeat(72)}`);
}

function subheading(text) {
  console.log(`\n  ► ${text}`);
  console.log(`  ${'-'.repeat(Math.min(text.length + 4, 72))}`);
}

// ---------------------------------------------------------------------------
// Disclaimer
// ---------------------------------------------------------------------------

console.log();
console.log('╔' + '═'.repeat(70) + '╗');
console.log('║' + '  ⚠  LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS'.padEnd(70) + '║');
console.log('║' + '  These are command-string BUILDERS. Nothing is executed.'.padEnd(70) + '║');
console.log('║' + '  Default targets: binary=./build/nexaraild, home=~/.nexarail-devnet'.padEnd(70) + '║');
console.log('╚' + '═'.repeat(70) + '╝');

// ---------------------------------------------------------------------------
// 1. Bank Send
// ---------------------------------------------------------------------------

heading('1. BANK SEND');

subheading('Default devnet paths');
console.log(bankSendCmd('my-key', 'nxr1recipient', 1000000, 'unxrl'));

subheading('Custom binary / home');
console.log(bankSendCmd('validator-key', 'nxr1partner', 500000, 'unxrl', {
  binary: '../releases/testnet-rc1/binaries/nexaraild-darwin-arm64',
  home: '~/.nexarail-testnet',
  chainId: 'nexarail-testnet-1',
}));

// ---------------------------------------------------------------------------
// 2. Merchant Register
// ---------------------------------------------------------------------------

heading('2. MERCHANT REGISTER');

subheading('Register a new merchant');
console.log(merchantRegisterCmd(
  'merchant-owner',
  'Acme Rail Logistics',
  'Premium rail logistics provider for the NexaRail ecosystem',
  { website: 'https://acme.example.com' },
));

subheading('Minimal registration');
console.log(merchantRegisterCmd('my-key', 'Quick Haul', 'Express freight services'));

// ---------------------------------------------------------------------------
// 3. Settlement Create
// ---------------------------------------------------------------------------

heading('3. SETTLEMENT CREATE');

subheading('Create settlement payment');
console.log(settlementCreateCmd(
  'payer-key',
  'nxr1merchant',
  1000000,
  'Order #12345 - Freight services',
));

subheading('Settlement with alternative denom');
console.log(settlementCreateCmd(
  'payer-key',
  'nxr1merchant',
  '5000000',
  'Invoice INV-2026-05',
  { denom: 'unxrl', chainId: 'nexarail-testnet-1' },
));

// ---------------------------------------------------------------------------
// 4. Escrow Create
// ---------------------------------------------------------------------------

heading('4. ESCROW CREATE');

subheading('Create escrow between buyer and seller');
console.log(escrowCreateCmd(
  'buyer-key',
  'nxr1seller',
  'merchant-1',
  2000000,
  'Invoice ABC - 30-day net',
  { escrowId: 'escrow-order-001' },
));

subheading('Escrow with defaults (auto-generated ID)');
console.log(escrowCreateCmd('buyer-key', 'nxr1seller', 'merchant-1', 1000000, 'Payment ref'));

// ---------------------------------------------------------------------------
// 5. Escrow Release
// ---------------------------------------------------------------------------

heading('5. ESCROW RELEASE');

subheading('Release escrow as buyer');
console.log(escrowReleaseCmd('escrow-order-001', { from: 'buyer-key', reference: 'Goods received' }));

subheading('Release escrow as authority');
console.log(escrowReleaseCmd('escrow-order-001', { from: 'gov-addr', reference: 'Dispute resolved' }));

// ---------------------------------------------------------------------------
// 6. Escrow Dispute
// ---------------------------------------------------------------------------

heading('6. ESCROW DISPUTE');

subheading('Open a dispute');
console.log(escrowDisputeCmd('escrow-order-001', 'Goods not delivered within agreed timeframe', { from: 'buyer-key' }));

// ---------------------------------------------------------------------------
// 7. Payout Create
// ---------------------------------------------------------------------------

heading('7. PAYOUT CREATE');

subheading('Create merchant payout');
console.log(payoutCreateCmd(
  'merchant-1',
  'nxr1recipient',
  500000,
  'Commission payout Q2 2026',
  { payoutId: 'payout-Q2-001', payoutType: 0, from: 'merchant-key' },
));

subheading('Batch-style payout with custom type');
console.log(payoutCreateCmd(
  'merchant-1',
  'nxr1partner',
  '750000',
  'Revenue share - May 2026',
  { payoutId: 'rev-share-001', payoutType: 1, from: 'merchant-key', denom: 'unxrl' },
));

// ---------------------------------------------------------------------------
// 8. Payout Mark Paid
// ---------------------------------------------------------------------------

heading('8. PAYOUT MARK PAID');

subheading('Mark payout as paid (authority only)');
console.log(payoutMarkPaidCmd('payout-Q2-001', { from: 'authority-key', extRef: 'ACH-txn-98765' }));

// ---------------------------------------------------------------------------
// 9. Treasury Spend Request
// ---------------------------------------------------------------------------

heading('9. TREASURY SPEND REQUEST');

subheading('Create a treasury spend request');
console.log(treasurySpendRequestCmd(
  'operations-fund',
  'nxr1vendor',
  2500000,
  'Infrastructure maintenance grant',
  { requestId: 'spend-grant-001', from: 'treasury-manager' },
));

subheading('Spend request for community pool');
console.log(treasurySpendRequestCmd(
  'community-pool',
  'nxr1community-member',
  '10000000',
  'Community development initiative',
  { requestId: 'spend-community-01', from: 'council-key', chainId: 'nexarail-mainnet-1' },
));

// ---------------------------------------------------------------------------
// 10. Product Governance
// ---------------------------------------------------------------------------

heading('10. PRODUCT GOVERNANCE');

subheading('Submit governance proposal');
console.log(productGovCmd('submit-proposal', {
  proposalFile: './proposals/update_fee_params.json',
  from: 'gov-proposer',
}));

subheading('Deposit to proposal');
console.log(productGovCmd('deposit', {
  proposalId: '1',
  deposit: '10000000unxrl',
  from: 'gov-proposer',
}));

subheading('Vote on proposal');
console.log(productGovCmd('vote', {
  proposalId: '1',
  voteOption: 'yes',
  from: 'validator-key',
}));

// ---------------------------------------------------------------------------
// Final reminder
// ---------------------------------------------------------------------------

console.log();
console.log('╔' + '═'.repeat(70) + '╗');
console.log('║' + '  ⚠  These are STRING BUILDERS — nothing was executed.'.padEnd(70) + '║');
console.log('║' + '  Copy-paste commands to your devnet terminal to run them.'.padEnd(70) + '║');
console.log('║' + '  LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS'.padEnd(70) + '║');
console.log('╚' + '═'.repeat(70) + '╝');
console.log();
