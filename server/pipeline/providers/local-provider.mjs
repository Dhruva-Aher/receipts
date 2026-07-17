import { ClaimExtractor } from './claim-extractor.mjs';
import { extractClaimsLocally } from '../transcript.mjs';

/** Deterministic provider for fast local development and automated tests. */
export class LocalProvider extends ClaimExtractor {
  id = 'local';

  async extract({ transcript }) {
    return extractClaimsLocally(transcript).claims;
  }
}
