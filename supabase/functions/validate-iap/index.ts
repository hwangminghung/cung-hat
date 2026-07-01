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
  const { data: product, error: productError } = await admin.from("products")
    .select("id,type,sku")
    .eq("store_product_id", store_product_id)
    .eq("platform", platform)
    .eq("is_active", true)
    .maybeSingle();
  if (productError) {
    return new Response(JSON.stringify({ error: productError.message }), { status: 500 });
  }
  if (!product) return new Response(JSON.stringify({ error: "unknown_product" }), { status: 400 });

  const { data: delivery, error: deliveryError } = await admin.rpc("record_validated_purchase", {
    p_user_id: user.id,
    p_product_id: product.id,
    p_platform: platform,
    p_store_txn_id: store_txn_id,
    p_receipt_ref: "stored",
  });
  if (deliveryError) {
    return new Response(JSON.stringify({ error: deliveryError.message }), { status: 400 });
  }

  return new Response(JSON.stringify({ ok: true, feature: product.type, sku: product.sku, delivery }), {
    headers: { "Content-Type": "application/json" },
  });
});
