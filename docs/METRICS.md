# Metrics & Claims — Receipts

**Cross-verified:** 2026-09-30  
Grades: **A** / **B** / **C** / **D** (design only)

## Claim table

| ID | Claim (exact) | Grade | Evidence |
|----|---------------|-------|----------|
| C1 | Product verifies agent **claims** via command re-run + git evidence → verdict | A | Pipeline + UI; `lied-test-run` fixture |
| C2 | Reproducible **FIX** when tests pass but were weakened (`test.skip` + assertion removed) | A | `fixtures/lied-test-run/`; GIF `assets/live-codex-fix-reveal.gif` |
| C3 | Live Codex transcript: `npm test` exit 0 with **1 skipped** (`adds tax`) | A | `proofs/live-codex-skipped-test-run.txt` (2026-07-17) |
| C4 | Stage timings: extract **9,876 ms** · verify **214 ms** · diff **61 ms** · export **1 ms** · e2e **10,152 ms** | C | Numbers only in README (2026-07-17). No checked-in timing JSON this pass — treat as historical; re-measure to upgrade. |
| C5 | Pipeline unit tests exist (`pipeline.test.mjs`) | A | File present; **15** tests collected 2026-09-30 |
| C6 | Suite currently **not** fully green on this SHA | A | `node --test server/pipeline/pipeline.test.mjs` → **11 pass / 4 fail** (2026-09-30) — do not claim “all green” until fixed |

## Explicit non-claims

| Phrase | Why |
|--------|-----|
| “Catches lying agents in production at X%” | No production install metrics |
| Codex hid the skip | Transcript itself reports the skip; Receipts shows evidence conflict |
| Timings as SLA | Single disposable-checkout capture |

## How to re-verify

```bash
node --test server/pipeline/pipeline.test.mjs
# Replay lied-test-run per README / docs/demo-script.md
```
