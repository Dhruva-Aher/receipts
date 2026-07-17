export function receiptMarkdown(report) {
  const lines = [
    '# Receipts verification receipt',
    '',
    `**Recommendation:** ${report.verdict.verdict}`,
    `**Reason:** ${report.verdict.reason}`,
    '',
    '## Agent claims',
    ''
  ];
  for (const claim of report.parsed.claims) lines.push(`- ${claim.text}${claim.command ? ` — \`${claim.command}\`` : ''}`);
  lines.push('', '## Evidence', '');
  for (const item of report.claimEvidence) lines.push(`- **${item.status}** — ${item.claim}`, item.output ? `  - Output: \`${item.output.replace(/\s+/g, ' ').slice(0, 240)}\`` : '');
  for (const finding of report.weakenedTests) lines.push(`- **${finding.type.replaceAll('_', ' ')}** — \`${finding.file}\`: \`${finding.line}\``);
  for (const path of report.blastRadius?.sensitivePaths || []) lines.push(`- **sensitive path changed** — \`${path.path}\``);
  return `${lines.filter(Boolean).join('\n')}\n`;
}
