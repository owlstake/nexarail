const API = process.env.API || 'http://localhost:1317';

export async function get(path) {
  const res = await fetch(`${API}${path}`);
  if (!res.ok) return { error: `HTTP ${res.status}` };
  return res.json();
}

export async function getParams(module) {
  return get(`/nexarail/${module}/v1/params`);
}

export async function getList(module, resource) {
  return get(`/nexarail/${module}/v1/${resource}`);
}

export async function getDetail(module, resource, id) {
  return get(`/nexarail/${module}/v1/${resource}/${id}`);
}

export async function getExists(module, resource, id) {
  return get(`/nexarail/${module}/v1/${resource}/exists/${id}`);
}

export async function getFiltered(module, resource, filter, value) {
  return get(`/nexarail/${module}/v1/${resource}/${filter}/${value}`);
}

export async function treasurySummary() {
  return get('/nexarail/treasury/v1/summary');
}

export async function nodeStatus(rpcUrl) {
  const RPC = rpcUrl || process.env.RPC || 'http://localhost:26657';
  const res = await fetch(`${RPC}/status`);
  if (!res.ok) return { error: `RPC HTTP ${res.status}` };
  const data = await res.json();
  return data.result;
}

// ---------------------------------------------------------------------------
// Command builders — these return CLI command strings, they do NOT execute txs
// All are LOCAL DEVNET ONLY — NOT MAINNET — NO REAL FUNDS
// ---------------------------------------------------------------------------

/**
 * Build a bank send command string.
 * @param {string} from - Sender address or key name
 * @param {string} to - Recipient address
 * @param {string|number} amount - Numeric amount
 * @param {string} denom - Coin denomination (e.g. 'unxrl')
 * @param {object} [opts]
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string} The full CLI command (does NOT execute)
 */
export function bankSendCmd(from, to, amount, denom, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  return `${binary} tx bank send ${from} ${to} ${amount}${denom} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build a merchant register command string.
 * @param {string} owner - Owner address or key name (passed as --from)
 * @param {string} name - Merchant name
 * @param {string} description - Merchant description
 * @param {object} [opts]
 * @param {string} [opts.website=''] - Optional website URL
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function merchantRegisterCmd(owner, name, description, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const website = opts.website || '';
  return `${binary} tx merchant register "${name}" "${description}" "${website}" --from ${owner} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build a settlement create command string.
 * @param {string} payer - Payer address or key name (passed as --from)
 * @param {string} merchant - Merchant owner address
 * @param {string|number} amount - Numeric amount
 * @param {string} reference - Settlement reference/metadata
 * @param {object} [opts]
 * @param {string} [opts.denom='unxrl']
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function settlementCreateCmd(payer, merchant, amount, reference, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const denom = opts.denom || 'unxrl';
  return `${binary} tx settlement create ${merchant} ${amount}${denom} --metadata "${reference}" --from ${payer} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build an escrow create command string.
 * @param {string} buyer - Buyer address or key name (passed as --from)
 * @param {string} seller - Seller address
 * @param {string} merchant - Merchant ID or address
 * @param {string|number} amount - Numeric amount
 * @param {string} reference - Payment reference
 * @param {object} [opts]
 * @param {string} [opts.denom='unxrl']
 * @param {string} [opts.escrowId='escrow-1'] - Custom escrow ID
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function escrowCreateCmd(buyer, seller, merchant, amount, reference, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const denom = opts.denom || 'unxrl';
  const escrowId = opts.escrowId || 'escrow-1';
  return `${binary} tx escrow create ${escrowId} ${seller} ${merchant} ${amount}${denom} --payment-reference "${reference}" --from ${buyer} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build an escrow release command string.
 * @param {string} escrowId - Escrow ID to release
 * @param {object} [opts]
 * @param {string} [opts.from] - Signer address/key (default: first arg)
 * @param {string} [opts.reference=''] - Release reference
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function escrowReleaseCmd(escrowId, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const from = opts.from || 'buyer';
  const ref = opts.reference ? ` --release-reference "${opts.reference}"` : '';
  return `${binary} tx escrow release ${escrowId}${ref} --from ${from} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build an escrow dispute command string.
 * @param {string} escrowId - Escrow ID to dispute
 * @param {string} reason - Dispute reason
 * @param {object} [opts]
 * @param {string} [opts.from] - Signer address/key
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function escrowDisputeCmd(escrowId, reason, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const from = opts.from || 'buyer';
  return `${binary} tx escrow dispute ${escrowId} "${reason}" --from ${from} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build a payout create command string.
 * @param {string} merchant - Merchant ID
 * @param {string} recipient - Recipient address
 * @param {string|number} amount - Numeric amount
 * @param {string} reference - Payout reference
 * @param {object} [opts]
 * @param {string} [opts.denom='unxrl']
 * @param {string} [opts.payoutId='payout-1']
 * @param {number} [opts.payoutType=0] - Payout type enum
 * @param {string} [opts.from] - Signer address/key
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function payoutCreateCmd(merchant, recipient, amount, reference, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const denom = opts.denom || 'unxrl';
  const payoutId = opts.payoutId || 'payout-1';
  const payoutType = opts.payoutType != null ? opts.payoutType : 0;
  const from = opts.from || 'merchant';
  return `${binary} tx payout create ${payoutId} ${merchant} ${recipient} ${amount}${denom} ${payoutType} --payout-reference "${reference}" --from ${from} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build a payout mark-paid command string.
 * @param {string} payoutId - Payout ID to mark as paid
 * @param {object} [opts]
 * @param {string} [opts.extRef='offchain-ref'] - External reference
 * @param {string} [opts.from] - Signer address/key
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function payoutMarkPaidCmd(payoutId, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const from = opts.from || 'authority';
  const extRef = opts.extRef || 'offchain-ref';
  return `${binary} tx payout mark-paid ${payoutId} ${extRef} --from ${from} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build a treasury spend request command string.
 * @param {string} accountId - Treasury account ID
 * @param {string} recipient - Recipient address
 * @param {string|number} amount - Numeric amount
 * @param {string} purpose - Spend purpose description
 * @param {object} [opts]
 * @param {string} [opts.denom='unxrl']
 * @param {string} [opts.requestId='spend-1']
 * @param {string} [opts.from] - Signer address/key
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function treasurySpendRequestCmd(accountId, recipient, amount, purpose, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const denom = opts.denom || 'unxrl';
  const requestId = opts.requestId || 'spend-1';
  const from = opts.from || 'treasury-manager';
  return `${binary} tx treasury create-spend ${requestId} ${accountId} ${recipient} ${amount}${denom} "${purpose}" --from ${from} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
}

/**
 * Build a product governance command string.
 * Wraps cosmos-sdk gov submit-proposal for NexaRail product parameter changes.
 * @param {string} action - Governance action type (e.g. 'submit-proposal', 'deposit', 'vote')
 * @param {object} [opts]
 * @param {string} [opts.proposalFile] - Path to proposal JSON file (for submit-proposal)
 * @param {string} [opts.proposalId] - Proposal ID (for deposit/vote)
 * @param {string} [opts.deposit] - Deposit amount/denom
 * @param {string} [opts.voteOption] - Vote option (yes/no/abstain/no_with_veto)
 * @param {string} [opts.from] - Signer address/key
 * @param {string} [opts.binary='./build/nexaraild']
 * @param {string} [opts.home='~/.nexarail-devnet']
 * @param {string} [opts.chainId='nexarail-devnet-1']
 * @param {string} [opts.keyring='test']
 * @returns {string}
 */
export function productGovCmd(action, opts = {}) {
  const binary = opts.binary || './build/nexaraild';
  const home = opts.home || '~/.nexarail-devnet';
  const chainId = opts.chainId || 'nexarail-devnet-1';
  const keyring = opts.keyring || 'test';
  const from = opts.from || 'gov-proposer';

  let cmd = `${binary} tx gov`;

  switch (action) {
    case 'submit-proposal':
      cmd += ` submit-proposal ${opts.proposalFile || 'proposal.json'}`;
      break;
    case 'deposit':
      cmd += ` deposit ${opts.proposalId || '1'} ${opts.deposit || '10000000unxrl'}`;
      break;
    case 'vote':
      cmd += ` vote ${opts.proposalId || '1'} ${opts.voteOption || 'yes'}`;
      break;
    default:
      cmd += ` ${action}`;
  }

  cmd += ` --from ${from} --chain-id ${chainId} --home ${home} --keyring-backend ${keyring} --yes`;
  return cmd;
}
