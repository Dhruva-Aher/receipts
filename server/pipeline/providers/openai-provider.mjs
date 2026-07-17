import { ClaimExtractor } from './claim-extractor.mjs';

/**
 * Extension point only. A future direct OpenAI API integration belongs here;
 * it deliberately has no SDK import, environment-variable dependency, or
 * request code today.
 */
export class OpenAIProvider extends ClaimExtractor {
  id = 'openai';

  async extract() {
    throw new Error('OpenAIProvider is not implemented. Use provider=codex or provider=local.');
  }
}
