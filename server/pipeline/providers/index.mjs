import { CodexProvider } from '../codex.mjs';
import { LocalProvider } from './local-provider.mjs';
import { OpenAIProvider } from './openai-provider.mjs';

export const DEFAULT_PROVIDER = 'codex';

export function createClaimExtractor(name = process.env.RECEIPTS_CLAIM_PROVIDER || DEFAULT_PROVIDER) {
  if (name === 'codex') return new CodexProvider();
  if (name === 'local') return new LocalProvider();
  if (name === 'openai') return new OpenAIProvider();
  throw new Error(`Unknown claim provider: ${name}. Use codex or local.`);
}
