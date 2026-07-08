import { createClient } from "jsr:@supabase/supabase-js@2";
import { json } from "../_shared/hmac.ts";
import { verifyGooglePurchase } from "../_shared/google_play.ts";
import { verifyAppleReceipt } from "../_shared/apple_iap.ts";

// Verify receipt THAT roi moi cap entitlement. Fail-closed khi thieu creds store.
// Client gui JWT; user resolve tu JWT (khong bao gio tin user_id trong body).
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { platform, store_product_id, store_txn_id, receipt } =
    await req.json().catch(() => ({}));
  if (!platform || !store_product_id || !store_txn_id || !receipt) {
    return json(400, { error: "missing_purchase_fields" });
  }
  if (!["ios", "android"].includes(platform)) return json(400, { error: "bad_platform" });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: product } = await admin.from("products")
    .select("id,type").eq("store_product_id", store_product_id)
    .eq("platform", platform).maybeSingle();
  if (!product) return json(400, { error: "unknown_product" });

  // Txn id authoritative de dedup: Google = orderId tu response DA verify (khong tin
  // client; fallback purchaseToken khi license-tester thieu orderId — token van unique
  // theo purchase). Apple = store_txn_id (da bind vao receipt qua txn matching).
  let authoritativeTxnId: string;

  if (platform === "android") {
    const saJson = Deno.env.get("GOOGLE_PLAY_SA_JSON");
    const packageName = Deno.env.get("ANDROID_PACKAGE_NAME");
    if (!saJson || !packageName) return json(503, { error: "iap_verifier_not_configured" });
    const v = await verifyGooglePurchase({
      saJson, packageName, productId: store_product_id, purchaseToken: receipt,
    });
    if (!v.ok) return json(400, { error: "invalid_receipt", reason: v.reason });
    // Defense-in-depth: boost la consumable — token da consume khong duoc cap lai.
    if (product.type === "boost" && v.consumptionState === 1) {
      return json(400, { error: "invalid_receipt", reason: "already_consumed" });
    }
    authoritativeTxnId = v.orderId ?? receipt;
  } else {
    const bundleId = Deno.env.get("APP_BUNDLE_ID");
    if (!bundleId) return json(503, { error: "iap_verifier_not_configured" });
    const environment = Deno.env.get("APPLE_ENVIRONMENT") ?? "Sandbox";
    // appAppleId: thu vien Apple BAT BUOC khi env=Production -> fail-closed truoc khi verify.
    const appAppleIdRaw = Deno.env.get("APPLE_APP_APPLE_ID");
    if (environment === "Production" && !appAppleIdRaw) {
      return json(503, { error: "iap_verifier_not_configured" });
    }
    const appAppleId = appAppleIdRaw ? Number(appAppleIdRaw) : undefined;
    if (appAppleIdRaw && Number.isNaN(appAppleId)) {
      return json(503, { error: "iap_verifier_not_configured" });
    }
    const v = await verifyAppleReceipt({
      receipt, bundleId, environment, appAppleId,
      sharedSecret: Deno.env.get("APPLE_SHARED_SECRET"),
      expectedTxnId: String(store_txn_id), expectedProductId: store_product_id,
    });
    if (!v.ok) return json(400, { error: "invalid_receipt", reason: v.reason });
    authoritativeTxnId = String(store_txn_id);
  }

  // Grant CHI lan dau cho moi purchase (1 giao dich = 1 lan cap quyen). Re-POST
  // receipt cu -> insert bi ignore (duplicate) -> KHONG refresh entitlement, van 200
  // de idempotent voi retry cua store/client.
  const { data: inserted, error: purErr } = await admin.from("purchases")
    .upsert({
      user_id: user.id, product_id: product.id, platform,
      store_txn_id: authoritativeTxnId, receipt_ref: "stored", state: "validated",
    }, { onConflict: "platform,store_txn_id", ignoreDuplicates: true })
    .select("id");
  if (purErr) {
    console.error("[validate-iap] purchase insert failed", purErr);
    return json(500, { error: "grant_failed" });
  }
  if (inserted && inserted.length > 0) {
    // boost = cua so 24h; con lai vinh vien (active_until null).
    const activeUntil = product.type === "boost"
      ? new Date(Date.now() + 24 * 3600 * 1000).toISOString() : null;
    const { error: entErr } = await admin.from("entitlements").upsert({
      user_id: user.id, feature: product.type,
      source: platform === "ios" ? "ios_iap" : "play_billing", active_until: activeUntil,
    }, { onConflict: "user_id,feature" });
    if (entErr) {
      console.error("[validate-iap] entitlement grant failed", entErr);
      // Compensate: xoa purchase row vua insert de retry cua store lam lai tu dau.
      const { error: delErr } = await admin.from("purchases")
        .delete().eq("id", inserted[0].id);
      if (delErr) console.error("[validate-iap] compensation delete failed", delErr);
      return json(500, { error: "grant_failed" });
    }
  } else {
    // Duplicate txn: self-heal truong hop hiem purchase da ghi nhung entitlement thieu
    // (crash giua 2 buoc truoc khi co compensating delete). CHI khi purchase row thuoc
    // CHINH user nay — replay receipt cua user khac thi KHONG cap gi, van 200 nhu cu.
    const { data: owned, error: ownErr } = await admin.from("purchases").select("id")
      .eq("platform", platform).eq("store_txn_id", authoritativeTxnId)
      .eq("user_id", user.id).maybeSingle();
    if (ownErr) {
      console.error("[validate-iap] duplicate ownership lookup failed", ownErr);
      return json(500, { error: "grant_failed" });
    }
    if (owned) {
      const { data: ent, error: entSelErr } = await admin.from("entitlements")
        .select("user_id").eq("user_id", user.id).eq("feature", product.type).maybeSingle();
      if (entSelErr) {
        // Khong xac dinh duoc trang thai -> KHONG upsert bua (tranh refresh boost oan).
        console.error("[validate-iap] entitlement lookup failed", entSelErr);
        return json(500, { error: "grant_failed" });
      }
      if (!ent) {
        const activeUntil = product.type === "boost"
          ? new Date(Date.now() + 24 * 3600 * 1000).toISOString() : null;
        const { error: entErr } = await admin.from("entitlements").upsert({
          user_id: user.id, feature: product.type,
          source: platform === "ios" ? "ios_iap" : "play_billing", active_until: activeUntil,
        }, { onConflict: "user_id,feature" });
        if (entErr) {
          console.error("[validate-iap] self-heal entitlement failed", entErr);
          return json(500, { error: "grant_failed" });
        }
      }
    }
  }

  return json(200, { ok: true, feature: product.type });
});
