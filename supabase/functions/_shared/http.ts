// Small helpers every Edge Function handler shares.

export type Handler = (request: Request) => Promise<Response>;

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'GET, OPTIONS',
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json; charset=utf-8' },
  });
}

export function error(status: number, code: string, message: string): Response {
  return json({ error: { code, message } }, status);
}

/** Answers CORS preflight and refuses anything but GET. */
export function getOnly(handle: (request: Request) => Promise<Response>): Handler {
  return async (request) => {
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders });
    if (request.method !== 'GET') {
      return error(405, 'method_not_allowed', 'Only GET is supported here.');
    }
    try {
      return await handle(request);
    } catch {
      // Never a bare 500: the app always gets the same error shape.
      return error(500, 'internal_error', 'Something went wrong. Try again.');
    }
  };
}
