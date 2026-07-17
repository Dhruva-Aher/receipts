import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { performance } from 'node:perf_hooks';
import { verifyRun } from './pipeline/index.mjs';
import { verifyFixture } from './pipeline/fixture.mjs';
import { receiptMarkdown } from './receipt-export.mjs';
const args = process.argv.slice(2);
const providerFlag = args.find((arg) => arg.startsWith('--provider='));
const provider = providerFlag?.slice('--provider='.length);
const fixtureFlag = args.find((arg) => arg.startsWith('--fixture='));
const fixture = fixtureFlag?.slice('--fixture='.length);
const outputFlag = args.find((arg) => arg.startsWith('--output='));
const output = outputFlag?.slice('--output='.length);
const measure = args.includes('--measure');
const positional = args.filter((arg) => !arg.startsWith('--provider=') && !arg.startsWith('--fixture=') && !arg.startsWith('--output=') && arg !== '--measure');
const [transcriptPath, cwd = process.cwd(), task = 'Verify the agent run'] = positional;
if (!fixture && !transcriptPath) { console.error('Usage: npm run evidence -- <transcript.txt> [repo-path] [task description] [--provider=codex|local] | --fixture=<name>'); process.exit(2); }
const startedAt = performance.now();
const report = fixture ? await verifyFixture(fixture) : await verifyRun({ transcript: await readFile(resolve(transcriptPath), 'utf8'), cwd: resolve(cwd), taskDescription: task, provider, measure });
if (output) {
  const destination = resolve(output);
  const exportStartedAt = performance.now();
  await writeFile(destination, destination.endsWith('.md') ? receiptMarkdown(report) : `${JSON.stringify(report, null, 2)}\n`);
  console.error(`Receipt written to ${destination}`);
  if (measure) console.error(`Receipt generation: ${Math.round(performance.now() - exportStartedAt)} ms`);
} else console.log(JSON.stringify(report, null, 2));
if (measure) console.error(`End-to-end elapsed: ${Math.round(performance.now() - startedAt)} ms`);
