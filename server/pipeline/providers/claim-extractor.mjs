/**
 * Contract for all claim-extraction providers. Providers interpret only the
 * transcript; command execution, diff analysis, and verdicting stay outside
 * this boundary.
 */
export class ClaimExtractor {
  id = 'base';

  async extract(_input) {
    throw new Error('ClaimExtractor.extract() must be implemented by a provider.');
  }
}
