import { createClient } from "jsr:@supabase/supabase-js@2";

// Validates a store purchase server-side, then grants the entitlement.
// Client passes its JWT; we resolve the user from it (never trust a user_id body field).
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  const { platform, store_product_id, store_txn_id, receipt } = await req.json();
  if (platform !== "ios" && platform !== "android") {
    return json({ error: "invalid_platform" }, 400);
  }

  // TODO(prod): verify `receipt`/token with Apple App Store Server API (APPLE_*) or
  // Google Play Developer API (GOOGLE_PLAY_SA_JSON). Reject if invalid/already-consumed.
  const valid = Boolean(receipt && store_txn_id); // placeholder until store creds are wired
  if (!valid) return json({ error: "invalid_receipt" }, 400);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: product, error: productError } = await admin
    .from("products")
    .select("id,type,sku")
    .eq("store_product_id", store_product_id)
    .eq("platform", platform)
    .eq("is_active", true)
    .maybeSingle();

  if (productError) return json({ error: productError.message }, 500);
  if (!product) return json({ error: "unknown_product" }, 400);

  const { data, error } = await admin.rpc("record_validated_purchase", {
    p_user_id: user.id,
    p_product_id: product.id,
    p_platform: platform,
    p_store_txn_id: store_txn_id,
    p_receipt_ref: "stored",
  });

  if (error) return json({ error: error.message }, 400);
  return json({ ok: true, feature: product.type, sku: product.sku, delivery: data }, 200);
});

function json(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
