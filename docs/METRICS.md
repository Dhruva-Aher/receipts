# Metrics & Claims — Receipts

**Cross-verified:** 2026-09-30

| ID | Claim (exact) | Grade | Evidence |
|----|---------------|-------|----------|
| C1 | Verifies agent claims via re-run + git evidence | A | pipeline + UI |
| C2 | Reproducible FIX on weakened tests | A | `fixtures/lied-test-run/` |
| C3 | Live Codex transcript shows skip + exit 0 | A | `proofs/live-codex-skipped-test-run.txt` |
| C4 | Local stage timings total **233 ms** (extract 1 / verify 192 / diff 40) | A | [`docs/evidence/stage-timings-local-2026-09-30.json`](./evidence/stage-timings-local-2026-09-30.json) |
| C5 | Historical Codex e2e **10,152 ms** (extract **9,876 ms**) | C | [`docs/evidence/stage-timings-codex-2026-07-17.json`](./evidence/stage-timings-codex-2026-07-17.json) |
| C6 | Pipeline tests **15/15** pass | A | `node --test server/pipeline/pipeline.test.mjs` (2026-09-30); `git init --template=` |

## Re-verify

```bash
node --test server/pipeline/pipeline.test.mjs
node scripts/capture-stage-timings.mjs
```
