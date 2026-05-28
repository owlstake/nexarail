import { getParams, nodeStatus } from './client.js';

async function checkFlags() {
  console.log('=== NexaRail Devnet — Live Flag Check (Node.js) ===\n');

  const modules = ['settlement', 'escrow', 'treasury', 'payout'];
  const results = {};

  for (const mod of modules) {
    try {
      const params = await getParams(mod);
      const live = params?.live_enabled;
      const extra = {};
      if (params && mod === 'settlement') {
        extra.treasury_routing = params.treasury_routing_enabled;
        extra.burn_routing = params.burn_routing_enabled;
      }
      results[mod] = { live, ...extra };
      process.stdout.write(`  ${mod.padEnd(12)} live_enabled: ${String(live ?? 'MISSING')}`);
      if (mod === 'settlement') {
        process.stdout.write(`  treasury_routing: ${String(extra.treasury_routing ?? '?')}  burn_routing: ${String(extra.burn_routing ?? '?')}`);
      }
      process.stdout.write('\n');
    } catch (err) {
      results[mod] = { error: err.message };
      console.log(`  ${mod.padEnd(12)} ERROR: ${err.message}`);
    }
  }

  // Summary: all should be false (devnet not live)
  let pass = true;
  let count = 0;
  for (const [mod, r] of Object.entries(results)) {
    if (r.error) { pass = false; continue; }
    if (r.live === true) { pass = false; }
    count++;
  }

  console.log('');
  console.log(`  Summary: ${pass ? 'PASS' : 'FAIL'} (${count}/${Object.keys(results).length} modules checked)`);
  if (!pass) {
    const flagged = Object.entries(results).filter(([, r]) => r.live === true).map(([m]) => m);
    if (flagged.length) console.log(`  Flagged as live: ${flagged.join(', ')}`);
  }

  // Also check node status for context
  try {
    const ns = await nodeStatus();
    console.log(`\n  Node: height=${ns.sync_info?.latest_block_height ?? '?'}  chain=${ns.node_info?.network ?? '?'}`);
  } catch {
    console.log('\n  Node status: unreachable');
  }
}

checkFlags().catch(err => {
  console.error('checkLiveFlags failed:', err);
  process.exit(1);
});
