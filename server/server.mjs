import { createServer } from 'node:http';
import { verifyRun } from './pipeline/index.mjs';
import { verifyFixture } from './pipeline/fixture.mjs';
const send = (res, status, body) => { res.writeHead(status, { 'content-type': 'application/json', 'access-control-allow-origin': '*' }); res.end(JSON.stringify(body)); };
createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return send(res, 204, {});
  if (req.method !== 'POST' || req.url !== '/verify') return send(res, 404, { error: 'POST /verify' });
  let raw = ''; for await (const chunk of req) raw += chunk;
  try {
    const { transcript, repoPath, taskDescription, base, fixture } = JSON.parse(raw);
    send(res, 200, fixture ? await verifyFixture(fixture) : await verifyRun({ transcript, cwd: repoPath || process.cwd(), taskDescription, base }));
  }
  catch (error) { send(res, 400, { error: error.message }); }
}).listen(8787, () => console.log('Receipts evidence API listening on http://localhost:8787'));
