import { createServer } from 'node:http';
import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { verifyRun } from './pipeline/index.mjs';
import { verifyFixture } from './pipeline/fixture.mjs';
const send = (res, status, body) => { res.writeHead(status, { 'content-type': 'application/json' }); res.end(JSON.stringify(body)); };
const MAX_REQUEST_BODY_BYTES = 128 * 1024;
const workspacePath = process.cwd();
const historyFile = join(process.cwd(), '.receipts', 'history.json');
let historyWrite = Promise.resolve();
let verificationInProgress = false;
async function readHistory() { try { return JSON.parse(await readFile(historyFile, 'utf8')); } catch (error) { if (error.code === 'ENOENT') return []; throw error; } }
async function remember(report) {
  const write = historyWrite.catch(() => {}).then(async () => {
    const history = await readHistory();
    const entry = { id: crypto.randomUUID(), createdAt: new Date().toISOString(), verdict: report.verdict.verdict, claims: report.parsed.claims.length, evidence: report.verdict.evidenceCount };
    await mkdir(join(process.cwd(), '.receipts'), { recursive: true });
    const temp = `${historyFile}.${crypto.randomUUID()}.tmp`;
    await writeFile(temp, JSON.stringify([entry, ...history].slice(0, 20), null, 2));
    await rename(temp, historyFile);
    return entry;
  });
  historyWrite = write;
  return write;
}
createServer(async (req, res) => {
  if (req.method === 'GET' && req.url === '/history') return send(res, 200, { reports: await readHistory() });
  if (req.method !== 'POST' || req.url !== '/verify') return send(res, 404, { error: 'POST /verify' });
  if (verificationInProgress) return send(res, 429, { error: 'A verification is already running. Wait for it to finish, then try again.' });
  verificationInProgress = true;
  try {
    let raw = ''; let bytes = 0;
    for await (const chunk of req) {
      bytes += chunk.length;
      if (bytes > MAX_REQUEST_BODY_BYTES) { const error = new Error(`Request body is too large. Maximum supported size is ${MAX_REQUEST_BODY_BYTES} bytes.`); error.statusCode = 413; throw error; }
      raw += chunk;
    }
    const { transcript, repoPath, taskDescription, base, fixture } = JSON.parse(raw);
    if (repoPath && resolve(repoPath) !== workspacePath) throw new Error('External repository paths are not allowed. Receipts verifies its configured workspace only.');
    const report = fixture ? await verifyFixture(fixture) : await verifyRun({ transcript, cwd: workspacePath, taskDescription, base });
    let history = null;
    try { history = await remember(report); }
    catch (historyError) { console.warn(`Receipts history could not be saved: ${historyError.message}`); }
    send(res, 200, { ...report, history });
  }
  catch (error) { send(res, error.statusCode || 400, { error: error.message }); }
  finally { verificationInProgress = false; }
}).listen(8787, '127.0.0.1', () => console.log('Receipts evidence API listening on http://127.0.0.1:8787'));
