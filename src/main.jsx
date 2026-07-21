import { useEffect, useMemo, useRef, useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { createRoot } from 'react-dom/client';
import currentCodexRun from '../proofs/current-codex-run.txt?raw';
import cleanRun from '../fixtures/clean-run/transcript.txt?raw';
import liedTestRun from '../fixtures/lied-test-run/transcript.txt?raw';
import blastRadiusRun from '../fixtures/blast-radius-run/transcript.txt?raw';
import './styles.css';

const API_URL = import.meta.env.VITE_RECEIPTS_API_URL || '/verify';
const HISTORY_URL = API_URL.replace(/\/verify$/, '/history');
const REQUEST_TIMEOUT_MS = 95_000;
const samples = [
  { label: 'Frozen replay · Weakened test', transcript: liedTestRun, fixture: 'lied-test-run' },
  { label: 'Frozen replay · Clean evidence', transcript: cleanRun, fixture: 'clean-run' },
  { label: 'Frozen replay · Sensitive path changed', transcript: blastRadiusRun, fixture: 'blast-radius-run' },
  { label: 'Live runtime proof · Requires authenticated Codex', transcript: currentCodexRun }
];
const verdictColor = { MERGE: 'verdict-merge', FIX: 'verdict-fix', 'RE-RUN': 'verdict-fix', ESCALATE: 'verdict-escalate' };
const verdictMotionColor = { MERGE: '#ecfdf5', FIX: '#fffbeb', 'RE-RUN': '#fffbeb', ESCALATE: '#fef2f2' };
const filters = ['ALL', 'MERGE', 'FIX', 'ESCALATE'];

function verdictPresentation(report) {
  const verdict = report.verdict.verdict;
  const contradicted = report.claimEvidence?.some((item) => item.status === 'contradicted');
  if (verdict === 'MERGE') return { signal: 'Claim supported', action: 'No evidence against this claim', detail: 'The command and repository evidence supported the agent’s claim.' };
  if (verdict === 'FIX') return { signal: contradicted ? 'Claim disproved' : 'Claim not supported', action: 'Do not merge — fix required', detail: contradicted ? 'The command result contradicted the agent’s claim.' : 'The command was green, but repository evidence shows the test was weakened.' };
  if (verdict === 'ESCALATE') return { signal: 'Human decision needed', action: 'Escalate before merge', detail: 'The claim held up, but repository evidence includes a sensitive scope signal.' };
  return { signal: 'Verification incomplete', action: 'Re-run before trusting this summary', detail: 'Receipts could not complete the evidence check.' };
}

function receiptFacts(report) {
  const facts = [];
  for (const item of report.claimEvidence || []) {
    if (item.actual?.exitCode === 0) facts.push({ tone: 'supported', text: `${item.command} executed successfully` });
    else if (item.status === 'contradicted') facts.push({ tone: 'failed', text: item.claim });
    else if (item.status === 'inconclusive') facts.push({ tone: 'failed', text: `inconclusive · ${item.claim}` });
  }
  for (const finding of report.weakenedTests || []) facts.push({ tone: 'failed', text: `${finding.type.replaceAll('_', ' ')} · ${finding.file}` });
  for (const path of report.blastRadius?.sensitivePaths || []) facts.push({ tone: 'failed', text: `sensitive path changed · ${path.path}` });
  return facts;
}

function downloadReceipt(report) {
  const lines = ['# Receipts verification receipt', '', `**Recommendation:** ${report.verdict.verdict}`, `**Reason:** ${report.verdict.reason}`, '', '## Agent claims', ...(report.parsed?.claims || []).map((claim) => `- ${claim.text}`), '', '## Evidence'];
  for (const item of report.claimEvidence || []) lines.push(`- **${item.status}** — ${item.claim}`);
  for (const finding of report.weakenedTests || []) lines.push(`- **${finding.type.replaceAll('_', ' ')}** — \`${finding.file}\`: \`${finding.line}\``);
  for (const path of report.blastRadius?.sensitivePaths || []) lines.push(`- **sensitive path changed** — \`${path.path}\``);
  const blob = new Blob([`${lines.join('\n')}\n`], { type: 'text/markdown' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url; link.download = `receipts-${report.verdict.verdict.toLowerCase()}.md`; document.body.appendChild(link); link.click(); link.remove();
  URL.revokeObjectURL(url);
}

const cardMotion = (index) => ({ initial: { opacity: 0, y: 16 }, animate: { opacity: 1, y: 0 }, transition: { delay: 0.12 + index * 0.07, duration: 0.25, ease: 'easeOut' } });
function readableError(error) {
  const message = error?.message || 'Verification could not complete.';
  if (error?.name === 'AbortError') return 'Verification timed out before the evidence server responded. Check Codex and the referenced command, then try again.';
  if (/failed to fetch/i.test(message)) return 'Couldn’t reach the evidence server. Start the pipeline server and try again.';
  if (/Transcript is too large/i.test(message)) return 'This transcript is too large to verify. Paste a shorter completion summary.';
  if (/verification is already running/i.test(message)) return 'Another verification is in progress. Wait for it to finish, then try again.';
  if (/no executable claims/i.test(message)) return 'Couldn’t find a command claim to verify in this transcript.';
  if (/not a Git repository/i.test(message)) return 'Repository evidence is unavailable because this folder is not a Git repository.';
  return message.replace(/\s+at\s+.*$/s, '');
}
const formatTimestamp = (value) => value ? new Intl.DateTimeFormat(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(value)) : 'Earlier receipt';
const claimSnippet = (entry) => entry.claim || (entry.claims ? `Earlier receipt recorded ${entry.claims} claim${entry.claims === 1 ? '' : 's'}.` : 'Claim details were not retained.');

function EvidenceCard({ item, index }) {
  const caught = item.status === 'contradicted';
  return <motion.article {...cardMotion(index)} className="evidence-card p-5 sm:p-6">
    <div className="grid gap-5 md:grid-cols-[1fr_1fr] md:gap-8">
      <section><p className="evidence-label">Agent claim</p><motion.pre animate={caught ? { color: '#a83b32', textDecorationLine: 'line-through' } : { color: '#292524' }} transition={{ delay: 0.25 + index * 0.07, duration: 0.18 }} className="evidence-text evidence-claim">{item.claim}</motion.pre></section>
      <motion.section initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.22 + index * 0.07, duration: 0.22 }} className="relative border-t border-stone-100 pt-5 md:border-l md:border-t-0 md:pt-0 md:pl-8"><span className="evidence-vs">vs</span><p className="evidence-label">Repository evidence</p><pre className="evidence-text evidence-actual">{item.output || JSON.stringify(item.actual, null, 2)}</pre>{item.actual?.outputTruncated && <p className="mt-3 text-xs text-stone-500">Output capped at 64 KB.</p>}</motion.section>
    </div>
  </motion.article>;
}

function PipelineFinding({ finding, claim, index }) {
  return <motion.article {...cardMotion(index)} className="evidence-card p-5 sm:p-6"><div className="grid gap-5 md:grid-cols-[1fr_1fr] md:gap-8">{claim && <section><p className="evidence-label">Agent claim</p><pre className="evidence-text evidence-claim">{claim.text}</pre></section>}<motion.section initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.22 + index * 0.07, duration: 0.22 }} className={claim ? 'relative border-t border-stone-100 pt-5 md:border-l md:border-t-0 md:pt-0 md:pl-8' : ''}>{claim && <span className="evidence-vs">vs</span>}<p className="evidence-label">Test-integrity evidence</p>{finding.file && <p className="evidence-location">{finding.file}</p>}<pre className="evidence-text evidence-actual">{finding.line}</pre></motion.section></div></motion.article>;
}

function BlastRadius({ blastRadius, index }) {
  const hasEvidence = blastRadius?.sensitivePaths?.length || blastRadius?.oversized;
  if (!hasEvidence) return null;
  return <motion.article {...cardMotion(index)} className="evidence-card p-5 sm:p-6"><p className="evidence-label">Actual result</p><pre className="evidence-text evidence-actual">{JSON.stringify(blastRadius, null, 2)}</pre></motion.article>;
}

function DiffViewer({ diff }) {
  if (!diff) return null;
  return <details className="diff-details"><summary>View full diff</summary><div className="diff-caption">Repository patch at verification time</div><pre className="evidence-text evidence-actual diff-code">{diff.split('\n').map((line, index) => <span key={`${index}-${line}`} className={line.startsWith('+') && !line.startsWith('+++') ? 'diff-add' : line.startsWith('-') && !line.startsWith('---') ? 'diff-remove' : line.startsWith('@@') ? 'diff-hunk' : ''}>{line}{'\n'}</span>)}</pre></details>;
}

function ReceiptActions({ report, receipt, onShare }) {
  return <div className="mt-10 flex flex-wrap gap-3"><button onClick={() => downloadReceipt(report)} className="bg-stone-950 px-4 py-2 text-sm font-medium text-white">Download receipt</button>{receipt?.id && <button onClick={() => onShare(receipt.id)} className="border border-stone-300 bg-white px-4 py-2 text-sm font-medium">Copy receipt link</button>}</div>;
}

function Ledger({ history, loading, onOpenReceipt }) {
  const [filter, setFilter] = useState('ALL');
  const [query, setQuery] = useState('');
  const visible = useMemo(() => history.filter((entry) => (filter === 'ALL' || entry.verdict === filter) && claimSnippet(entry).toLowerCase().includes(query.trim().toLowerCase())), [filter, history, query]);
  const agents = useMemo(() => Object.entries(history.reduce((all, entry) => {
    const key = entry.agent || 'Earlier receipt runs';
    all[key] ||= { total: 0, MERGE: 0, FIX: 0, ESCALATE: 0 };
    all[key].total += 1;
    all[key][entry.verdict] = (all[key][entry.verdict] || 0) + 1;
    return all;
  }, {})), [history]);
  return <section className="w-full max-w-4xl"><div className="page-intro"><p className="eyebrow">Verification ledger</p><h1 className="page-title">A record of what was claimed.</h1><p className="page-deck">Every receipt preserves the claim, repository evidence, and recommendation—not an agent’s retrospective summary.</p></div><div className="mt-10 grid gap-8 lg:grid-cols-[1fr_17rem]"><div><div className="ledger-controls"><label className="search-field"><span className="sr-only">Search claims</span><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search claim text" /></label><div className="filter-row" aria-label="Filter receipts by verdict">{filters.map((item) => <button key={item} className={filter === item ? 'is-active' : ''} onClick={() => setFilter(item)}>{item}</button>)}</div></div><div className="mt-5 space-y-3">{loading && <p className="empty-copy">Loading retained receipts…</p>}{!loading && visible.map((entry) => <article key={entry.id} className="ledger-card"><div className="ledger-card-top"><p className="ledger-time">{formatTimestamp(entry.createdAt)}</p><span className={`history-status history-${entry.verdict?.toLowerCase()}`}>{entry.verdict}</span></div><p className="ledger-claim">{claimSnippet(entry)}</p><div className="ledger-meta"><span>{entry.repo || 'configured repository'}</span><span>{entry.branch || 'earlier branch'}</span><span>{entry.agent || 'earlier receipt'}</span></div>{entry.report && <button className="ledger-open" onClick={() => onOpenReceipt(entry)}>Open receipt <span aria-hidden="true">→</span></button>}</article>)}{!loading && !visible.length && <p className="empty-copy">No retained receipts match this filter.</p>}</div></div><aside className="track-record"><p className="evidence-label">Verification track record</p><p className="track-record-note">Counts, not a score. A receipt earns its own evidence.</p>{agents.map(([agent, counts]) => <div className="agent-line" key={agent}><p>{agent}</p><span>{counts.MERGE || 0} verified, {counts.FIX || 0} fixed, {counts.ESCALATE || 0} escalated</span></div>)}{!agents.length && <p className="empty-copy">Run a verification to begin the record.</p>}</aside></div></section>;
}

function ClaimPatterns({ history }) {
  const patterns = useMemo(() => {
    const recorded = history.filter((entry) => entry.claim || entry.claimKind);
    const testRuns = recorded.filter((entry) => entry.claimKind === 'test claim' || /\b(test|npm)\b/i.test(entry.claim || ''));
    const sensitiveRuns = recorded.filter((entry) => entry.hasSensitivePath || entry.claimKind === 'sensitive-path claim' || /\bauth\b/i.test(entry.claim || ''));
    const rows = [
      { label: 'all recorded claims', total: recorded.length, count: recorded.filter((entry) => ['FIX', 'ESCALATE', 'RE-RUN'].includes(entry.verdict)).length, phrase: 'needed a follow-up' },
      { label: 'test claims', total: testRuns.length, count: testRuns.filter((entry) => ['FIX', 'RE-RUN'].includes(entry.verdict)).length, phrase: 'unsupported' },
      { label: 'sensitive-path claims', total: sensitiveRuns.length, count: sensitiveRuns.filter((entry) => entry.verdict === 'ESCALATE').length, phrase: 'escalated' }
    ];
    return rows.filter((row) => row.total > 0).map((row) => ({ ...row, percent: Math.round((row.count / row.total) * 100) }));
  }, [history]);
  return <section className="w-full max-w-3xl"><div className="page-intro"><p className="eyebrow">Claim patterns</p><h1 className="page-title">The stories that fail most often.</h1><p className="page-deck">Patterns are calculated only from retained receipts. They do not measure code quality, security, or agent capability.</p></div><div className="pattern-list mt-12">{patterns.map((pattern) => <article className="pattern-row" key={pattern.label}><div className="pattern-heading"><code>{pattern.label}</code><p><strong>{pattern.percent}%</strong> {pattern.phrase}</p></div><p className="pattern-note" aria-label={`${pattern.label}: ${pattern.percent}% ${pattern.phrase}`}>{pattern.count} of {pattern.total} retained receipts</p></article>)}{!patterns.length && <p className="empty-copy">Patterns appear after Receipts retains claim metadata in the ledger.</p>}</div></section>;
}

function App() {
  const [transcript, setTranscript] = useState('');
  const [screen, setScreen] = useState('input');
  const [report, setReport] = useState(null);
  const [receipt, setReceipt] = useState(null);
  const [history, setHistory] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(true);
  const [error, setError] = useState('');
  const [inputError, setInputError] = useState('');
  const [taskDescription, setTaskDescription] = useState('');
  const [fixture, setFixture] = useState(null);
  const [selectedSample, setSelectedSample] = useState('');
  const [shareNotice, setShareNotice] = useState('');
  const transcriptRef = useRef(null);

  async function loadHistory() {
    setHistoryLoading(true);
    try { const response = await fetch(HISTORY_URL); const body = await response.json(); if (!response.ok) throw new Error(body.error); setHistory(body.reports || []); }
    catch { setHistory([]); }
    finally { setHistoryLoading(false); }
  }
  async function openReceipt(entry) {
    try { const response = await fetch(`${HISTORY_URL}/${encodeURIComponent(entry.id)}`); const body = await response.json(); if (!response.ok) throw new Error(body.error); setReport(body.report); setReceipt(body.receipt); setScreen('verdict'); window.location.hash = `receipt=${entry.id}`; }
    catch (loadError) { setError(readableError(loadError)); setScreen('error'); }
  }
  useEffect(() => { loadHistory(); const id = new URLSearchParams(window.location.hash.slice(1)).get('receipt'); if (id) openReceipt({ id }); }, []);

  function selectSample(event) {
    const value = event.target.value; const sample = samples[Number(value)];
    if (sample) { setTranscript(sample.transcript); setFixture(sample.fixture || null); setSelectedSample(value); setInputError(''); }
  }
  function updateTranscript(event) { setTranscript(event.target.value); setFixture(null); setSelectedSample(''); setInputError(''); }
  function submitWithShortcut(event) { if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') event.currentTarget.form?.requestSubmit(); }
  async function checkRun(event) {
    event.preventDefault();
    if (!transcript.trim()) { setInputError('Paste a transcript before checking the run.'); transcriptRef.current?.focus(); return; }
    setScreen('loading'); setError(''); setReport(null); setReceipt(null); window.history.replaceState(null, '', window.location.pathname);
    const controller = new AbortController(); const timer = window.setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const response = await fetch(API_URL, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(fixture ? { transcript, fixture } : { transcript, taskDescription }), signal: controller.signal });
      const body = await response.json().catch(() => ({})); if (!response.ok) throw new Error(body.error || `Pipeline request failed with HTTP ${response.status}.`); if (!body.verdict) throw new Error('The pipeline returned no verdict.');
      setReport(body); setReceipt(body.history || null); if (body.history) setHistory((current) => [body.history, ...current.filter((entry) => entry.id !== body.history.id)]); setScreen('verdict'); if (body.history?.id) window.location.hash = `receipt=${body.history.id}`;
    } catch (requestError) { setError(readableError(requestError)); setScreen('error'); }
    finally { window.clearTimeout(timer); }
  }
  function startOver() { setScreen('input'); setReport(null); setReceipt(null); setError(''); setInputError(''); setShareNotice(''); window.history.replaceState(null, '', window.location.pathname); window.setTimeout(() => transcriptRef.current?.focus(), 0); }
  function navigate(next) { setShareNotice(''); if (next === 'input') return startOver(); setScreen(next); }
  async function shareReceipt(id) {
    const url = `${window.location.origin}${window.location.pathname}#receipt=${encodeURIComponent(id)}`;
    try { await navigator.clipboard.writeText(url); setShareNotice('Receipt link copied'); }
    catch { window.prompt('Copy this receipt link', url); setShareNotice('Receipt link ready to copy'); }
  }

  const navigation = [['input', 'Verify'], ['ledger', 'Ledger'], ['patterns', 'Patterns']];
  return <main className="min-h-screen bg-stone-50 text-stone-900"><header className="border-b border-stone-200 bg-stone-50"><div className="mx-auto flex h-16 max-w-5xl items-center gap-3 px-6"><button onClick={() => navigate('input')} className="brand-lockup"><span className="brand-mark" aria-hidden="true">✓</span><span className="wordmark font-serif text-2xl font-bold">receipts<span className="text-red-700">.</span></span></button><nav className="ml-4 flex gap-1" aria-label="Receipts sections">{navigation.map(([key, label]) => <button key={key} className={`top-nav ${screen === key || (key === 'input' && ['loading', 'error', 'verdict'].includes(screen)) ? 'is-active' : ''}`} onClick={() => navigate(key)}>{label}</button>)}</nav><span className="ml-auto hidden font-mono text-[.58rem] uppercase tracking-[.16em] text-stone-400 sm:block">Evidence-based agent verification</span></div></header><div className="mx-auto flex max-w-5xl justify-center px-6 py-14 sm:py-20">
    {screen === 'input' && <form onSubmit={checkRun} className="w-full max-w-2xl space-y-6"><div><p className="eyebrow">Evidence-based verification for coding-agent summaries</p><h1 className="mt-3 font-serif text-5xl font-semibold tracking-tight sm:text-6xl">The agent made a claim.<br /><em>Does the repository support it?</em></h1><p className="mt-5 max-w-lg text-sm leading-6 text-stone-600">1. Agent claim &nbsp; 2. Repository evidence &nbsp; 3. Your decision</p></div><label className="block"><span className="evidence-label">Open a reproducible proof</span><select onChange={selectSample} value={selectedSample} className="mt-2 w-full border border-stone-300 bg-white px-3 py-3 text-sm outline-none focus:border-stone-800"><option value="" disabled>Choose a replay or live proof</option>{samples.map((sample, index) => <option key={sample.label} value={index}>{sample.label}</option>)}</select></label><label className="block"><span className="evidence-label">Agent completion summary</span><textarea ref={transcriptRef} value={transcript} onChange={updateTranscript} onKeyDown={submitWithShortcut} aria-invalid={Boolean(inputError)} aria-describedby={inputError ? 'transcript-error' : undefined} placeholder="Paste the agent’s final summary and referenced commands" className="mt-2 min-h-72 w-full resize-y border border-stone-300 bg-white p-4 font-mono text-sm leading-6 outline-none focus:border-stone-800" /></label><label className="block"><span className="evidence-label">Original task/request <span className="normal-case tracking-normal">(optional)</span></span><textarea value={taskDescription} onChange={(event) => setTaskDescription(event.target.value)} placeholder="What was the agent asked to change?" className="mt-2 min-h-24 w-full resize-y border border-stone-300 bg-white p-4 text-sm leading-6 outline-none focus:border-stone-800" /></label>{inputError && <p id="transcript-error" role="alert" className="-mt-3 text-sm text-red-700">{inputError}</p>}<p className="text-sm leading-6 text-stone-600">Receipts verifies stated commands and selected repository evidence. It does not review code quality or prove security.</p><button type="submit" aria-keyshortcuts="Control+Enter Meta+Enter" title="Verify the summary (Ctrl/⌘ + Enter)" className="bg-stone-950 px-5 py-3 text-sm font-medium text-white transition hover:bg-stone-700">Verify the summary <span className="ml-2 hidden text-stone-400 sm:inline">⌘↵</span></button></form>}
    {screen === 'loading' && <section role="status" aria-live="polite" aria-busy="true" className="w-full max-w-2xl border border-stone-200 bg-white p-8 sm:p-12"><p className="eyebrow">Receipts</p><h1 className="mt-3 font-serif text-4xl font-semibold tracking-tight">Checking what the agent claimed</h1><p className="mt-4 max-w-md text-sm leading-6 text-stone-600">{fixture ? 'Loading captured command and repository evidence...' : 'This can take a moment: Receipts is waiting on real command and Git-diff evidence.'}</p><div className="mt-8 h-px overflow-hidden bg-stone-200"><motion.div className="h-full bg-stone-700" animate={{ scaleX: [0.08, 0.72, 0.28] }} transition={{ duration: 2.4, ease: 'easeInOut', repeat: Infinity }} style={{ transformOrigin: 'left' }} /></div><p className="mt-4 font-mono text-[.68rem] uppercase tracking-[.12em] text-stone-400">No staged progress — results appear when evidence is ready.</p></section>}
    {screen === 'error' && <section aria-live="assertive" className="w-full max-w-2xl border border-red-200 bg-red-50 p-8 sm:p-12"><p className="eyebrow text-red-700">Couldn’t check this run</p><p className="mt-4 font-mono text-sm leading-6 text-red-950">{error}</p><p className="mt-4 text-sm leading-6 text-red-900">Your transcript is still here. Correct it or restore the evidence server, then submit again.</p><button onClick={startOver} className="mt-7 border border-red-300 px-4 py-2 text-sm font-medium text-red-950">Back to transcript</button></section>}
    {screen === 'ledger' && <Ledger history={history} loading={historyLoading} onOpenReceipt={openReceipt} />}
    {screen === 'patterns' && <ClaimPatterns history={history} />}
    <AnimatePresence mode="wait">{screen === 'verdict' && report && <motion.section key={receipt?.id || report.verdict.verdict} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.15 }} className="w-full max-w-3xl"><motion.div initial={{ opacity: 0, scale: 0.78, backgroundColor: '#fafaf9' }} animate={{ opacity: 1, scale: 1, backgroundColor: verdictMotionColor[report.verdict.verdict] || '#f5f5f4' }} transition={{ scale: { type: 'spring', stiffness: 420, damping: 17, mass: 0.8 }, opacity: { duration: 0.18 }, backgroundColor: { duration: 0.34 } }} className={`receipt-card p-7 sm:p-11 ${verdictColor[report.verdict.verdict] || 'text-stone-950'}`}><div className="receipt-top"><p className="evidence-label">Receipt · {report.replay ? 'frozen evidence replay' : 'independent verification'}</p><span className="receipt-id">{report.verdict.verdict}</span></div>{report.replay && <p className="mt-3 font-mono text-[.68rem] uppercase tracking-[.12em] text-stone-400">Captured on {report.replay.capturedAt}</p>}<div className="receipt-rule" /><p className="receipt-section">Agent claim</p><p className="receipt-claim">{report.parsed?.claims?.[0]?.text || 'No executable claim was extracted.'}</p><p className="receipt-section mt-7">Repository evidence</p><ul className="receipt-facts">{receiptFacts(report).map((fact, index) => <li key={`${fact.text}-${index}`} className={fact.tone}>{fact.text}</li>)}</ul><div className="receipt-rule mt-8" /><h1 className="verdict-word mt-6 font-serif font-semibold">{verdictPresentation(report).signal}</h1><p className="verdict-action mt-7">{verdictPresentation(report).action}</p><p className="verdict-summary mt-3">{verdictPresentation(report).detail}</p></motion.div><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.2, duration: 0.18 }} className="mt-16 space-y-4"><p className="evidence-label">Full repository evidence</p>{report.claimEvidence?.map((item, index) => <EvidenceCard key={item.claimId} item={item} index={index} />)}{report.weakenedTests?.map((finding, index) => <PipelineFinding key={`${finding.file}-${index}`} finding={finding} index={(report.claimEvidence?.length || 0) + index} claim={report.parsed?.claims?.find((item) => item.type === 'tests_pass')} />)}<BlastRadius blastRadius={report.blastRadius} index={(report.claimEvidence?.length || 0) + (report.weakenedTests?.length || 0)} /><DiffViewer diff={report.evidenceDiff} />{!report.claimEvidence?.length && !report.weakenedTests?.length && !report.blastRadius?.oversized && !report.blastRadius?.sensitivePaths?.length && <p className="text-sm text-stone-600">Receipts completed, but the pipeline returned no additional repository evidence for this run.</p>}</motion.div><ReceiptActions report={report} receipt={receipt} onShare={shareReceipt} />{shareNotice && <p role="status" className="mt-3 font-mono text-xs text-stone-500">{shareNotice}</p>}<button onClick={startOver} className="mt-3 border border-stone-300 bg-white px-4 py-2 text-sm font-medium">Verify another summary</button></motion.section>}</AnimatePresence>
  </div></main>;
}
createRoot(document.getElementById('root')).render(<App />);
