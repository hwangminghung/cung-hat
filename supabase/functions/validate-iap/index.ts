import { createClient } from "jsr:@supabase/supabase-js@2";

// Validates a store purchase server-side, then grants the entitlement.
// Client passes its JWT; we resolve the user from it (never trust a user_id body field).
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { platform, store_product_id, store_txn_id, receipt } = await req.json();

  // TODO(prod): verify `receipt`/token with Apple App Store Server API (APPLE_*) or
  // Google Play Developer API (GOOGLE_PLAY_SA_JSON). Reject if invalid/already-consumed.
  const valid = Boolean(receipt && store_txn_id); // placeholder until store creds are wired
  if (!valid) return new Response(JSON.stringify({ error: "invalid_receipt" }), { status: 400 });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: product } = await admin.from("products")
    .select("id,type").eq("store_product_id", store_product_id).eq("platform", platform).maybeSingle();
  if (!product) return new Response(JSON.stringify({ error: "unknown_product" }), { status: 400 });

  await admin.from("purchases").upsert({
    user_id: user.id, product_id: product.id, platform,
    store_txn_id, receipt_ref: "stored", state: "validated",
  }, { onConflict: "platform,store_txn_id" });

  // boost = 24h window; see_likes/premium_filters = permanent.
  const activeUntil = product.type === "boost"
    ? new Date(Date.now() + 24 * 3600 * 1000).toISOString() : null;
  await admin.from("entitlements").upsert({
    user_id: user.id, feature: product.type,
    source: platform === "ios" ? "ios_iap" : "play_billing", active_until: activeUntil,
  }, { onConflict: "user_id,feature" });

  return new Response(JSON.stringify({ ok: true, feature: product.type }), {
    headers: { "Content-Type": "application/json" },
  });
});
