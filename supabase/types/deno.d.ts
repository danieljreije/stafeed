// The one Deno API the Edge Function entry points use, so `tsc` can check
// them under Node. Deno itself never reads this file.
declare const Deno: {
  serve(handler: (request: Request) => Response | Promise<Response>): unknown;
};
