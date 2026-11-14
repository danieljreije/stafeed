// GET /v1/config
//
// What the app may offer the Shopper: Destination Countries, currencies and
// the filters the sources really support. The lists match the app's
// onboarding (lib/app/features/shopper/models/destination_country.dart).
// The Shopper's own choices (country, currency, interests) stay on the phone
// until Shoppers have a backend identity (#17).

import type { AdSource } from './ad_source.ts';
import { getOnly, type Handler, json } from './http.ts';
import { guardSource } from './source_guard.ts';
import { supportedFilters } from './supported_filters.ts';

export const destinationCountries = ['US', 'GB', 'AE', 'LB'] as const;
export const currencies = ['USD', 'GBP', 'EUR', 'AED'] as const;

export interface ConfigHandlerOptions {
  readonly sources: readonly AdSource[];
  readonly feedPageSize: number;
}

export function createConfigHandler(options: ConfigHandlerOptions): Handler {
  const sources = options.sources.map(guardSource);

  return getOnly(async () => {
    const filters = await supportedFilters(sources);
    return json({
      apiVersion: 1,
      servesSampleData: options.sources.some((s) => s.servesSampleData),
      destinationCountries,
      currencies,
      supportedFilters: { query: true, categories: filters.categories },
      feedPageSize: options.feedPageSize,
    });
  });
}
