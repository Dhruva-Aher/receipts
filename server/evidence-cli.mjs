import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { verifyRun } from './pipeline/index.mjs';
import { verifyFixture } from './pipeline/fixture.mjs';
const args = process.argv.slice(2);
const providerFlag = args.find((arg) => arg.startsWith('--provider='));
const provider = providerFlag?.slice('--provider='.length);
const fixtureFlag = args.find((arg) => arg.startsWith('--fixture='));
const fixture = fixtureFlag?.slice('--fixture='.length);
const positional = args.filter((arg) => !arg.startsWith('--provider=') && !arg.startsWith('--fixture='));
const [transcriptPath, cwd = process.cwd(), task = 'Verify the agent run'] = positional;
if (!fixture && !transcriptPath) { console.error('Usage: npm run evidence -- <transcript.txt> [repo-path] [task description] [--provider=codex|local] | --fixture=<name>'); process.exit(2); }
const report = fixture ? await verifyFixture(fixture) : await verifyRun({ transcript: await readFile(resolve(transcriptPath), 'utf8'), cwd: resolve(cwd), taskDescription: task, provider });
console.log(JSON.stringify(report, null, 2));
