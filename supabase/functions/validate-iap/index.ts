import { createClient } from "jsr:@supabase/supabase-js@2";

// Fails closed until store receipt verification is implemented server-side.
// Client passes its JWT; we resolve the user from it (never trust a user_id body field).
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { platform, store_product_id, store_txn_id, receipt } = await req.json().catch(() => ({}));
  if (!platform || !store_product_id || !store_txn_id || !receipt) {
    return new Response(JSON.stringify({ error: "missing_purchase_fields" }), { status: 400 });
  }
  if (!["ios", "android"].includes(platform)) {
    return new Response(JSON.stringify({ error: "bad_platform" }), { status: 400 });
  }

  const verifierEnv = platform === "ios"
    ? Deno.env.get("APPLE_SHARED_SECRET")
    : Deno.env.get("GOOGLE_PLAY_SA_JSON");
  if (!verifierEnv) {
    return new Response(JSON.stringify({ error: "iap_verifier_not_configured" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }
  return new Response(JSON.stringify({ error: "iap_verifier_not_implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  });
});
