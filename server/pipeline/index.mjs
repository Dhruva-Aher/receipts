import { extractClaims } from './transcript.mjs';
import { rerunCommand, evaluateCommandClaim } from './runner.mjs';
import { gitDiff, detectWeakenedTests, classifyBlastRadius } from './diff.mjs';
import { makeVerdict } from './verdict.mjs';
import { createClaimExtractor } from './providers/index.mjs';

export async function verifyRun({ transcript, cwd, taskDescription = '', base = 'HEAD', provider }) {
  const claimExtractor = provider && typeof provider.extract === 'function' ? provider : createClaimExtractor(provider);
  const parsed = await extractClaims({ transcript, provider: claimExtractor });
  const runnable = parsed.claims.filter((claim) => claim.command && (claim.type === 'tests_pass' || claim.type === 'command_success'));
  const claimEvidence = [];
  for (const claim of runnable) claimEvidence.push(evaluateCommandClaim(claim, await rerunCommand(claim.command, { cwd })));
  const diff = await gitDiff(cwd, base);
  const weakenedTests = detectWeakenedTests(diff);
  const blastRadius = classifyBlastRadius(diff, taskDescription);
  return { parsed, claimEvidence, weakenedTests, blastRadius, verdict: makeVerdict({ claimEvidence, weakenedTests, blastRadius }) };
}
