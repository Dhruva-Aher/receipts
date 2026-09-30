# Decisions — Receipts

Status legend: **PROPOSED** ≠ **DECIDED** ≠ **IMPLEMENTED** ≠ **VERIFIED**  
Related: [METRICS.md](./METRICS.md)

**Cross-verify (2026-09-30):** FIX fixture + Codex transcript Grade **A**. Local stage timings Grade **A** archived. Codex e2e timings Grade **C** archived. Pipeline tests **15/15** after sandbox-safe `git init --template=`.

---

## D1 — Verify claims, not code quality

| | |
|--|--|
| **Context** | Coding agents summarize; CI only checks configured workflows. |
| **Decision** | Product question = “does the repo support what the agent claimed?” via re-run + diff evidence. |
| **Why** | Distinct from linters/test runners; interviewable trust boundary. |
| **Alternatives** | Full program analysis; LLM-as-judge of summaries. |
| **Tradeoffs** | Narrow claim subset; needs frozen fixtures for demos. |
| **Evidence** | README product insight; `server/pipeline/` |
| **Status** | DECIDED · IMPLEMENTED |

---

## D2 — Freeze reproducible FIX receipts

| | |
|--|--|
| **Context** | Live agents are non-deterministic for judges. |
| **Decision** | Ship `lied-test-run` (and siblings) with frozen transcript, command output, and expected verdict. |
| **Why** | Judges/recruiters can replay without API keys. |
| **Evidence** | `fixtures/lied-test-run/`, proofs/ |
| **Status** | DECIDED · IMPLEMENTED · VERIFIED |

---

## D3 — Local evidence beats model confidence

| | |
|--|--|
| **Context** | Model may honestly report skips while still saying “tests passed”. |
| **Decision** | Verdict from local command + git inspection; model only supplies claims. |
| **Why** | Fail-closed on evidence conflict → FIX BEFORE MERGE. |
| **Evidence** | Live Codex proof + FIX GIF |
| **Status** | DECIDED · IMPLEMENTED |

---

## D4 — Publish stage timings only with capture date

| | |
|--|--|
| **Context** | e2e ~10s is mostly Codex extract latency. |
| **Decision** | Keep July 17, 2026 numbers as Grade C until a timing artifact is checked in. |
| **Why** | Honesty over impressive latency marketing. |
| **Evidence** | `docs/METRICS.md` C4 |
| **Status** | DECIDED |

---

## D5 — Sandbox-safe `git init --template=` in tests

| | |
|--|--|
| **Context** | `git init` failed under restricted sandboxes writing default hooks (`Operation not permitted`). |
| **Decision** | Tests call `git init --template=` so no hook templates are copied. |
| **Evidence** | `server/pipeline/pipeline.test.mjs` helper; **15/15** pass |
| **Status** | DECIDED · IMPLEMENTED · VERIFIED |

---

## D6 — Dual timing artifacts (local A + Codex C)

| | |
|--|--|
| **Context** | Codex extract dominates e2e and needs auth to reproduce. |
| **Decision** | Archive LocalProvider timings as Grade A; keep July 17 Codex numbers as Grade C JSON. |
| **Evidence** | `docs/evidence/stage-timings-*.json` |
| **Status** | DECIDED · IMPLEMENTED · VERIFIED |
