// Edge Function: GET /functions/v1/feed (the spec's GET /v1/feed).
import { createFeedHandler } from '../_shared/feed_handler.ts';
import { defaultSources, feedPageSize } from '../_shared/sources.ts';

Deno.serve(createFeedHandler({ sources: defaultSources(), pageSize: feedPageSize }));
