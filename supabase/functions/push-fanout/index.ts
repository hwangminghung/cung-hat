import { createClient } from "jsr:@supabase/supabase-js@2";

// Invoked (by DB trigger via pg_net, or directly) with {user_ids, title, body, data}.
// Looks up FCM tokens (service role) and sends via FCM HTTP v1. Secrets Edge-only.
Deno.serve(async (req) => {
  if (req.headers.get("x-fanout-secret") !== Deno.env.get("PUSH_FANOUT_SECRET")) {
    return new Response("forbidden", { status: 403 });
  }
  const { user_ids, title, body, data } = await req.json();
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: tokens } = await admin.from("device_tokens")
    .select("fcm_token").in("user_id", user_ids ?? []);
  // TODO(prod): obtain an OAuth access token from GOOGLE_FCM_SA_JSON and POST to
  // https://fcm.googleapis.com/v1/projects/<project>/messages:send for each token.
  const sent = (tokens ?? []).length;
  console.log(`[push-fanout] would send "${title}" to ${sent} tokens`, { data });
  return new Response(JSON.stringify({ sent }), { headers: { "Content-Type": "application/json" } });
});
