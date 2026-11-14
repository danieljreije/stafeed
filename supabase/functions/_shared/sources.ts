// The sources the deployed functions use. Only Fixtures for now; Brand Ads
// (#21), Awin (#25) and Shopify (#28) join here as they are built.

import type { AdSource } from './ad_source.ts';
import { FixtureSource } from './fixture_source.ts';

export const feedPageSize = 10;

export function defaultSources(): AdSource[] {
  return [new FixtureSource()];
}
