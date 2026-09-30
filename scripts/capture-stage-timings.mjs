import { mkdir, writeFile, rm } from 'node:fs/promises';
import { join } from 'node:path';
import { execFile, spawnSync } from 'node:child_process';
import { promisify } from 'node:util';
import { performance } from 'node:perf_hooks';
import { verifyRun } from '../server/pipeline/index.mjs';
import { verifyFixture } from '../server/pipeline/fixture.mjs';
import { LocalProvider } from '../server/pipeline/providers/local-provider.mjs';
import { receiptMarkdown } from '../server/receipt-export.mjs';

const exec = promisify(execFile);
const repo = join(process.cwd(), '.tmp-measure-lied');
await rm(repo, { recursive: true, force: true });
await mkdir(repo, { recursive: true });
await exec('git', ['init', '--template='], { cwd: repo });
await exec('git', ['config', 'user.email', 'measure@example.test'], { cwd: repo });
await exec('git', ['config', 'user.name', 'Measure'], { cwd: repo });
await writeFile(
  join(repo, 'package.json'),
  JSON.stringify({ name: 'checkout', scripts: { test: 'node --test checkout.test.mjs' } }, null, 2) + '\n',
);
await writeFile(
  join(repo, 'checkout.test.mjs'),
  "import test from 'node:test';\ntest('adds tax', () => { if (1 + 2 !== 3) throw new Error('fail'); });\n",
);
await exec('git', ['add', '.'], { cwd: repo });
await exec('git', ['commit', '-m', 'baseline'], { cwd: repo });
await writeFile(
  join(repo, 'checkout.test.mjs'),
  "import test from 'node:test';\ntest.skip('adds tax', () => { /* assertion removed */ });\n",
);

const transcript =
  'Checkout tests pass.\nRan: npm test\nnpm test completed successfully (exit code 0).\n';
const report = await verifyRun({
  transcript,
  cwd: repo,
  provider: new LocalProvider(),
  measure: true,
  taskDescription: 'Fix checkout tax tests',
});
const exportStarted = performance.now();
receiptMarkdown(report);
const receiptExportMs = Math.round(performance.now() - exportStarted);
const fixtureStarted = performance.now();
const fixtureReport = await verifyFixture('lied-test-run');
const fixtureReplayMs = Math.round(performance.now() - fixtureStarted);

await mkdir('docs/evidence', { recursive: true });
const local = {
  captured_at: new Date().toISOString(),
  host: `${process.platform} ${process.arch}`,
  node: process.version,
  method: 'verifyRun LocalProvider on disposable lied checkout in-repo .tmp-measure-lied',
  grade: 'A',
  timing_ms: {
    claimExtractionMs: report.timing.claimExtractionMs,
    commandVerificationMs: report.timing.commandVerificationMs,
    diffInspectionMs: report.timing.diffInspectionMs,
    receiptExportMs,
    totalMs: report.timing.totalMs + receiptExportMs,
  },
  verdict: report.verdict,
  fixture_replay_ms: fixtureReplayMs,
  fixture_verdict: fixtureReport.verdict.verdict,
};
await writeFile('docs/evidence/stage-timings-local-2026-09-30.json', `${JSON.stringify(local, null, 2)}\n`);

const historical = {
  captured_at: '2026-07-17',
  grade: 'C',
  source: 'README measured live run + proofs/live-codex-skipped-test-run.txt',
  model: 'gpt-5.6-terra via authenticated Codex CLI',
  note: 'Codex claim extraction dominates. Not re-run this pass (requires Codex auth). Local Grade A timings archived separately.',
  timing_ms: {
    claimExtractionMs: 9876,
    commandVerificationMs: 214,
    diffInspectionMs: 61,
    receiptExportMs: 1,
    totalMs: 10152,
  },
};
await writeFile('docs/evidence/stage-timings-codex-2026-07-17.json', `${JSON.stringify(historical, null, 2)}\n`);
await rm(repo, { recursive: true, force: true });
console.log(JSON.stringify(local, null, 2));

const t = spawnSync('node', ['--test', 'server/pipeline/pipeline.test.mjs'], { encoding: 'utf8' });
console.log(t.stdout.split(/\n/).filter((l) => l.startsWith('# ')).slice(-8).join('\n'));
console.log('exit', t.status);
