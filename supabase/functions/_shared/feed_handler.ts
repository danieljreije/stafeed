// GET /v1/feed?country=GB&category=bags&q=tote&cursor=...
//
// One page of For You for an anonymous Shopper. `country` (the Destination
// Country) is required until Shoppers have a backend identity (#17).
// Shopping Sessions (`sessionId`) come with #19.

import type { AdSource } from './ad_source.ts';
import { InvalidCursorError } from './cursor.ts';
import { getForYouPage } from './feed.ts';
import { error, getOnly, type Handler, json } from './http.ts';
import { guardSource } from './source_guard.ts';
import { supportedFilters } from './supported_filters.ts';

const maxQueryLength = 200;

export interface FeedHandlerOptions {
  readonly sources: readonly AdSource[];
  readonly pageSize: number;
}

export function createFeedHandler(options: FeedHandlerOptions): Handler {
  const sources = options.sources.map(guardSource);
  const servesSampleData = options.sources.some((s) => s.servesSampleData);

  return getOnly(async (request) => {
    const params = new URL(request.url).searchParams;

    if (params.has('sessionId')) {
      return error(400, 'sessions_not_supported', 'Shopping Sessions are not served yet.');
    }

    const country = (params.get('country') ?? '').toUpperCase();
    if (!/^[A-Z]{2}$/.test(country)) {
      return error(400, 'invalid_country', 'Give the Destination Country as a 2-letter code.');
    }

    const category = params.get('category') || null;
    if (category !== null) {
      const { categories } = await supportedFilters(sources);
      if (!categories.some((c) => c.id === category)) {
        return error(400, 'unsupported_filter', `Category "${category}" is not supported.`);
      }
    }

    const query = params.get('q') ?? '';
    if (query.length > maxQueryLength) {
      return error(400, 'invalid_query', `Keep the search under ${maxQueryLength} characters.`);
    }

    try {
      const page = await getForYouPage(
        sources,
        { destinationCountry: country, category, query },
        params.get('cursor'),
        options.pageSize,
      );
      return json({ ...page, servesSampleData });
    } catch (e) {
      if (e instanceof InvalidCursorError) return error(400, 'invalid_cursor', e.message);
      throw e;
    }
  });
}
