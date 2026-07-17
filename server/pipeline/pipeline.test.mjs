import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { extractClaimsLocally } from './transcript.mjs';
import { rerunCommand, evaluateCommandClaim } from './runner.mjs';
import { gitDiff, detectWeakenedTests, classifyBlastRadius } from './diff.mjs';
import { makeVerdict } from './verdict.mjs';
import { parseCodexClaims } from './codex.mjs';
import { createClaimExtractor, DEFAULT_PROVIDER } from './providers/index.mjs';
import { verifyFixture } from './fixture.mjs';
const exec = promisify(execFile);

test('extracts executable claims from narration rather than a hardcoded list', () => {
  const result = extractClaimsLocally('I completed the task. Build passed. No breaking changes.\nRan: npm run build');
  assert.equal(result.claims.length, 2);
  assert.equal(result.claims[0].command, 'npm run build');
});

test('captures true and false outcomes from real process execution', async () => {
  const trueClaim = extractClaimsLocally('Command passed.\nRan: node --version').claims[0];
  const falseClaim = extractClaimsLocally('Command passed.\nRan: node --definitely-not-a-node-option').claims[0];
  const trueEvidence = evaluateCommandClaim(trueClaim, await rerunCommand(trueClaim.command));
  const falseEvidence = evaluateCommandClaim(falseClaim, await rerunCommand(falseClaim.command));
  assert.equal(trueEvidence.status, 'supported');
  assert.equal(falseEvidence.status, 'contradicted');
});

test('accepts structured claim extraction from Codex stdout', () => {
  const claims = parseCodexClaims('{"claims":[{"id":"claim-a","type":"command_success","text":"Build passed.","expected":{"exitCode":0},"command":"npm run build"}]}', ['npm run build']);
  assert.equal(claims[0].source, 'codex-exec');
  assert.equal(claims[0].command, 'npm run build');
});

test('uses CodexProvider by default and LocalProvider only when selected', () => {
  assert.equal(DEFAULT_PROVIDER, 'codex');
  assert.equal(createClaimExtractor().id, 'codex');
  assert.equal(createClaimExtractor('local').id, 'local');
});

test('replays frozen demo fixtures with byte-stable evidence', async () => {
  for (const name of ['clean-run', 'lied-test-run', 'blast-radius-run']) {
    const first = await verifyFixture(name);
    const second = await verifyFixture(name);
    const expected = JSON.parse(await (await import('node:fs/promises')).readFile(`fixtures/${name}/expected-verdict.json`, 'utf8'));
    assert.equal(JSON.stringify(first), JSON.stringify(second));
    assert.deepEqual(first, expected);
  }
});

test('flags weakened test logic from an actual git diff', async () => {
  const repo = await mkdtemp(join(tmpdir(), 'receipts-real-diff-'));
  await exec('git', ['init'], { cwd: repo });
  await exec('git', ['config', 'user.email', 'proof@example.test'], { cwd: repo });
  await exec('git', ['config', 'user.name', 'Receipts Proof'], { cwd: repo });
  await writeFile(join(repo, 'checkout.test.js'), "import test from 'node:test';\ntest('tax', () => { assert.equal(total, 3); });\n");
  await exec('git', ['add', '.'], { cwd: repo }); await exec('git', ['commit', '-m', 'baseline'], { cwd: repo });
  await writeFile(join(repo, 'checkout.test.js'), "import test from 'node:test';\ntest.skip('tax', () => { /* assertion removed */ });\nconst command = 'checkout || true';\n");
  const diff = await gitDiff(repo);
  const findings = detectWeakenedTests(diff);
  assert.deepEqual(findings.map((item) => item.type).sort(), ['masked_failure', 'removed_assertion', 'skipped_test']);
  const radius = classifyBlastRadius({ ...diff, files: [...diff.files, { status: 'M', path: 'auth/session.js' }] }, 'Change checkout copy');
  assert.equal(radius.status, 'surprise');
  assert.equal(makeVerdict({ claimEvidence: [], weakenedTests: findings, blastRadius: radius }).verdict, 'FIX');
});
