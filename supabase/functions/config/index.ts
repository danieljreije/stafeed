// Edge Function: GET /functions/v1/config (the spec's GET /v1/config).
import { createConfigHandler } from '../_shared/config_handler.ts';
import { defaultSources, feedPageSize } from '../_shared/sources.ts';

Deno.serve(createConfigHandler({ sources: defaultSources(), feedPageSize }));
