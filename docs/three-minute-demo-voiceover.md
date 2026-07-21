# Receipts — 3-minute hackathon demo voiceover

Record this at a calm pace over `assets/receipts-3-minute-hackathon-demo.mp4`. Keep the delivery precise and conversational; do not add music that competes with the voice.

## 0:00–0:24 — The trust gap

“A coding agent says the task is complete. Tests passed. Ready to merge.

Most of us trust that summary by default.

Receipts asks one question: does the repository support what the agent claimed?

Let’s prove it.”

## 0:24–0:54 — FIX

“Here, the agent claims checkout tests pass.

The command did exit successfully.

But the repository evidence found a skipped test and a removed assertion.

Receipts says FIX BEFORE MERGE.

This is not a confidence score. It is a receipt: the agent claim, the command result, and the relevant repository evidence.”

## 0:54–1:26 — The trust boundary and ESCALATE

“GPT-5.6, through the authenticated Codex CLI, extracts the agent’s free-form summary into a checkable claim.

Then the model leaves the trust chain.

Commands are re-run locally. Git diffs are inspected locally. Repository evidence decides the verdict.

In this case, the stated command held, but an authentication path changed. That is not a security finding. It is an ESCALATE signal: a human decision is needed before merge.”

## 1:26–1:58 — Evidence you can use

“The full receipt keeps the skipped test and removed assertion beside the original claim.

You can inspect the complete diff, then copy the receipt link into a PR comment.

Receipts also has memory. The Verification Ledger preserves every run as a record of what was claimed, what the repository showed, and the resulting decision.”

## 1:58–2:28 — Patterns and scope

“Claim Patterns turn retained receipts into plain facts. For example: test claims, 75 percent unsupported.

Not a score. Not a chart. Just the evidence history, stated clearly.

Receipts does not review code quality. It does not prove correctness. It does not replace CI. And it does not guarantee security.”

## 2:28–3:00 — Close

“Its scope is deliberately narrow.

Before merging an agent’s work, ask whether the repository supports the story it told.

AI agents tell stories.

Receipts checks whether they’re true.”
