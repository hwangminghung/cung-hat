import { createClient } from "jsr:@supabase/supabase-js@2";
import { hmacSha256Hex, json } from "../_shared/hmac.ts";

// Dat coc phong hat (dich vu that -> MoMo/ZaloPay, KHONG IAP — store-policy split).
// So tien do SERVER quyet tu venues.booking_deposit_minor. Fail-closed khi thieu env.
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { plan_id, venue_id, gateway } = await req.json().catch(() => ({}));
  if (!plan_id || !venue_id) return json(400, { error: "missing_payment_fields" });
  if (!["momo", "zalopay"].includes(gateway)) return json(400, { error: "bad_gateway" });

  const redirectUrl = Deno.env.get("PAYMENTS_REDIRECT_URL");
  const webhookBase = Deno.env.get("PAYMENTS_WEBHOOK_URL");
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  const { data: venue } = await admin.from("venues")
    .select("id,booking_deposit_minor,is_active").eq("id", venue_id).maybeSingle();
  if (!venue?.is_active) return json(400, { error: "unknown_venue" });
  const amount = venue.booking_deposit_minor as number;

  if (gateway === "momo") {
    const partnerCode = Deno.env.get("MOMO_PARTNER_CODE");
    const accessKey = Deno.env.get("MOMO_ACCESS_KEY");
    const secretKey = Deno.env.get("MOMO_SECRET_KEY");
    const endpoint = Deno.env.get("MOMO_ENDPOINT"); // sandbox: https://test-payment.momo.vn
    if (!partnerCode || !accessKey || !secretKey || !endpoint || !redirectUrl || !webhookBase) {
      return json(503, { error: "payment_gateway_not_configured" });
    }
    const orderId = crypto.randomUUID();
    const { error: insErr } = await admin.from("venue_bookings").insert({
      plan_id, venue_id, user_id: user.id, amount_minor: amount,
      gateway, gateway_ref: orderId, state: "initiated",
    });
    if (insErr) return json(400, { error: insErr.message });

    const requestId = orderId;
    const orderInfo = "Coc phong hat Cung Hat";
    const extraData = "";
    const ipnUrl = `${webhookBase}?gateway=momo`;
    // Chuoi ky create-order theo docs MoMo v2 (thu tu alphabet, HMAC-SHA256 secretKey).
    const raw =
      `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}` +
      `&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}` +
      `&partnerCode=${partnerCode}&redirectUrl=${redirectUrl}` +
      `&requestId=${requestId}&requestType=captureWallet`;
    const signature = await hmacSha256Hex(secretKey, raw);
    const res = await fetch(`${endpoint}/v2/gateway/api/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        partnerCode, requestId, amount, orderId, orderInfo,
        redirectUrl, ipnUrl, lang: "vi", extraData,
        requestType: "captureWallet", signature,
      }),
    }).catch(() => null);
    const data = res ? await res.json().catch(() => null) : null;
    if (!res?.ok || data?.resultCode !== 0 || !data?.payUrl) {
      await admin.from("venue_bookings").update({ state: "failed" })
        .eq("gateway_ref", orderId);
      return json(502, { error: "gateway_create_failed", detail: data?.message ?? null });
    }
    return json(200, { pay_url: data.payUrl, gateway_ref: orderId });
  }

  // zalopay
  const appId = Deno.env.get("ZALOPAY_APP_ID");
  const key1 = Deno.env.get("ZALOPAY_KEY1");
  const endpoint = Deno.env.get("ZALOPAY_ENDPOINT"); // sandbox: https://sb-openapi.zalopay.vn
  if (!appId || !key1 || !endpoint || !redirectUrl || !webhookBase) {
    return json(503, { error: "payment_gateway_not_configured" });
  }
  const now = new Date();
  const yy = String(now.getFullYear()).slice(2);
  const mm = String(now.getMonth() + 1).padStart(2, "0");
  const dd = String(now.getDate()).padStart(2, "0");
  const appTransId = `${yy}${mm}${dd}_${crypto.randomUUID().replaceAll("-", "").slice(0, 16)}`;
  const { error: insErr } = await admin.from("venue_bookings").insert({
    plan_id, venue_id, user_id: user.id, amount_minor: amount,
    gateway, gateway_ref: appTransId, state: "initiated",
  });
  if (insErr) return json(400, { error: insErr.message });

  const appTime = Date.now();
  const embedData = JSON.stringify({ redirecturl: redirectUrl });
  const item = "[]";
  // mac = HMAC(app_id|app_trans_id|app_user|amount|app_time|embed_data|item, key1)
  const macRaw = `${appId}|${appTransId}|${user.id}|${amount}|${appTime}|${embedData}|${item}`;
  const mac = await hmacSha256Hex(key1, macRaw);
  const form = new URLSearchParams({
    app_id: appId, app_user: user.id, app_time: String(appTime),
    amount: String(amount), app_trans_id: appTransId,
    embed_data: embedData, item, description: "Coc phong hat Cung Hat",
    bank_code: "", callback_url: `${webhookBase}?gateway=zalopay`, mac,
  });
  const res = await fetch(`${endpoint}/v2/create`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: form.toString(),
  }).catch(() => null);
  const data = res ? await res.json().catch(() => null) : null;
  if (!res?.ok || data?.return_code !== 1 || !data?.order_url) {
    await admin.from("venue_bookings").update({ state: "failed" })
      .eq("gateway_ref", appTransId);
    return json(502, { error: "gateway_create_failed", detail: data?.return_message ?? null });
  }
  return json(200, { pay_url: data.order_url, gateway_ref: appTransId });
});
