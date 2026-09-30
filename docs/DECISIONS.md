# Decisions — Receipts

Status legend: **PROPOSED** ≠ **DECIDED** ≠ **IMPLEMENTED** ≠ **VERIFIED**  
Related: [METRICS.md](./METRICS.md)

**Cross-verify (2026-09-30):** FIX fixture + Codex transcript Grade **A**. Stage timings Grade **C** (README-only). Pipeline tests **11/15** passing — do not pitch full green CI until fixed.

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

## D5 — Do not claim green suite while tests fail

| | |
|--|--|
| **Context** | 2026-09-30 local run: 4 failing pipeline tests. |
| **Decision** | README/CI badge ≠ “all tests pass”; METRICS records current fail count. |
| **Status** | DECIDED · VERIFIED (observation) |
