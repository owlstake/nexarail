import {
  nodeStatus,
  treasurySummary,
  getList,
  getExists,
  getDetail,
} from './client.js';

async function queryProductState() {
  console.log('=== NexaRail Devnet — Full Product State (Node.js) ===\n');

  // 1. Node status
  console.log('--- Node Status ---');
  try {
    const ns = await nodeStatus();
    console.log(`  Height:        ${ns.sync_info?.latest_block_height ?? '?'}`);
    console.log(`  Chain ID:      ${ns.node_info?.network ?? '?'}`);
    console.log(`  Validator:     ${ns.validator_info?.address ?? '?'}`);
    console.log(`  Catch-up:      ${ns.sync_info?.catching_up ?? '?'}`);
  } catch (err) {
    console.log(`  ERROR: ${err.message}`);
  }
  console.log('');

  // 2. Treasury summary
  console.log('--- Treasury Summary ---');
  try {
    const ts = await treasurySummary();
    console.log(`  ${JSON.stringify(ts, null, 4)}`);
  } catch (err) {
    console.log(`  ERROR: ${err.message}`);
  }
  console.log('');

  // 3. Merchant list
  console.log('--- Merchant List ---');
  try {
    const merchants = await getList('treasury', 'merchant');
    const items = merchants?.merchant ?? merchants?.list ?? merchants ?? [];
    const arr = Array.isArray(items) ? items : [items];
    console.log(`  Count: ${arr.length}`);
    for (const m of arr.slice(0, 5)) {
      console.log(`    - ${JSON.stringify(m).slice(0, 200)}`);
    }
    if (arr.length > 5) console.log(`    ... and ${arr.length - 5} more`);
  } catch (err) {
    console.log(`  ERROR: ${err.message}`);
  }
  console.log('');

  // 4. Settlement list
  console.log('--- Settlement List ---');
  try {
    const settlements = await getList('settlement', 'settlement');
    const items = settlements?.settlement ?? settlements?.list ?? settlements ?? [];
    const arr = Array.isArray(items) ? items : [items];
    console.log(`  Count: ${arr.length}`);
    for (const s of arr.slice(0, 5)) {
      console.log(`    - ${JSON.stringify(s).slice(0, 200)}`);
    }
    if (arr.length > 5) console.log(`    ... and ${arr.length - 5} more`);
  } catch (err) {
    console.log(`  ERROR: ${err.message}`);
  }
  console.log('');

  // 5. Escrow list + exists (non-existent)
  console.log('--- Escrow ---');
  try {
    const escrows = await getList('escrow', 'escrow');
    const items = escrows?.escrow ?? escrows?.list ?? escrows ?? [];
    const arr = Array.isArray(items) ? items : [items];
    console.log(`  Escrow count: ${arr.length}`);
    for (const e of arr.slice(0, 3)) {
      console.log(`    - ${JSON.stringify(e).slice(0, 200)}`);
    }
  } catch (err) {
    console.log(`  ERROR: ${err.message}`);
  }

  try {
    const exists = await getExists('escrow', 'escrow', 'nonexistent-id');
    console.log(`  Escrow exists('nonexistent-id'): ${JSON.stringify(exists)}`);
  } catch (err) {
    console.log(`  Escrow exists ERROR: ${err.message}`);
  }
  console.log('');

  // 6. Payout list + exists (non-existent)
  console.log('--- Payout ---');
  try {
    const payouts = await getList('payout', 'payout');
    const items = payouts?.payout ?? payouts?.list ?? payouts ?? [];
    const arr = Array.isArray(items) ? items : [items];
    console.log(`  Payout count: ${arr.length}`);
    for (const p of arr.slice(0, 3)) {
      console.log(`    - ${JSON.stringify(p).slice(0, 200)}`);
    }
  } catch (err) {
    console.log(`  ERROR: ${err.message}`);
  }

  try {
    const exists = await getExists('payout', 'payout', 'nonexistent-id');
    console.log(`  Payout exists('nonexistent-id'): ${JSON.stringify(exists)}`);
  } catch (err) {
    console.log(`  Payout exists ERROR: ${err.message}`);
  }
  console.log('');

  // 7. Attempt a filtered query
  console.log('--- Filtered Query (example) ---');
  try {
    const filtered = await (await import('./client.js')).getFiltered('settlement', 'settlement', 'status', 'pending');
    console.log(`  Settlement filtered by status=pending: ${JSON.stringify(filtered).slice(0, 300)}`);
  } catch (err) {
    console.log(`  Filtered query (expected empty): ${err.message}`);
  }
  console.log('');

  console.log('=== Product state query complete ===');
}

queryProductState().catch(err => {
  console.error('queryProductState failed:', err);
  process.exit(1);
});
