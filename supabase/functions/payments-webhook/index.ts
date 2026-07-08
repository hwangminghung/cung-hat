import { createClient } from "jsr:@supabase/supabase-js@2";
import { hmacSha256Hex, json } from "../_shared/hmac.ts";

// IPN/callback gateway. verify_jwt=false (config.toml) vi gateway khong co JWT Supabase —
// chu ky HMAC cua gateway CHINH LA lop xac thuc. Fail-closed khi thieu secret.
// State machine: initiated -> paid|failed; RIENG paid-IPN hop le den tren row 'failed'
// (vd truoc do bi danh dau failed do mat mang) van reconcile -> paid (co log).
// Row da 'paid' -> idempotent no-op. Amount lech -> KHONG cap paid.
Deno.serve(async (req) => {
  const gateway = new URL(req.url).searchParams.get("gateway");
  const body = await req.json().catch(() => ({}));
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  async function settle(gatewayRef: string, paid: boolean, ipnAmount: number) {
    // .eq gateway: chong cross-gateway ref collision (defense-in-depth; settle chi
    // duoc goi trong 2 branch momo/zalopay nen closure `gateway` luon non-null o day).
    const { data: booking, error: qErr } = await admin.from("venue_bookings")
      .select("id,amount_minor,state")
      .eq("gateway_ref", gatewayRef).eq("gateway", gateway).maybeSingle();
    if (qErr) {
      console.error("[payments-webhook] booking lookup failed", qErr);
      return "lookup_error";
    }
    if (!booking) return "not_found";
    if (booking.state === "paid") return "already_paid"; // idempotent
    if (paid && ipnAmount !== booking.amount_minor) {
      console.error(`[payments-webhook] amount mismatch ref=${gatewayRef} ipn=${ipnAmount} db=${booking.amount_minor}`);
      if (booking.state === "initiated") {
        const { error: updErr } = await admin.from("venue_bookings")
          .update({ state: "failed" }).eq("id", booking.id).eq("state", "initiated");
        if (updErr) console.error("[payments-webhook] mismatch failed-write failed", updErr);
      }
      return "amount_mismatch";
    }
    if (paid) {
      if (booking.state === "failed") {
        console.warn(`[payments-webhook] reconciling paid IPN on failed booking ref=${gatewayRef}`);
      }
      const commission = Math.round(booking.amount_minor * 0.1); // hoa hong 10%
      // paid wins: chi cap paid tu trang thai chua chot (khong ghi de paid/refunded khi race).
      const { error: updErr } = await admin.from("venue_bookings")
        .update({ state: "paid", commission_minor: commission })
        .eq("id", booking.id).in("state", ["initiated", "failed"]);
      if (updErr) {
        console.error("[payments-webhook] paid update failed", updErr);
        return "update_error";
      }
      return "paid";
    }
    if (booking.state === "initiated") {
      const { error: updErr } = await admin.from("venue_bookings")
        .update({ state: "failed" }).eq("id", booking.id).eq("state", "initiated");
      if (updErr) console.error("[payments-webhook] failed update failed", updErr);
    }
    return "failed";
  }

  if (gateway === "momo") {
    const accessKey = Deno.env.get("MOMO_ACCESS_KEY");
    const secretKey = Deno.env.get("MOMO_SECRET_KEY");
    if (!accessKey || !secretKey) return json(503, { error: "payment_gateway_not_configured" });
    // Chuoi ky IPN v2 theo docs MoMo (thu tu alphabet co dinh).
    const raw =
      `accessKey=${accessKey}&amount=${body.amount}&extraData=${body.extraData ?? ""}` +
      `&message=${body.message}&orderId=${body.orderId}&orderInfo=${body.orderInfo}` +
      `&orderType=${body.orderType}&partnerCode=${body.partnerCode}&payType=${body.payType}` +
      `&requestId=${body.requestId}&responseTime=${body.responseTime}` +
      `&resultCode=${body.resultCode}&transId=${body.transId}`;
    const expected = await hmacSha256Hex(secretKey, raw);
    if (!body.signature || expected !== body.signature) {
      return new Response("bad signature", { status: 401 });
    }
    const outcome = await settle(String(body.orderId), body.resultCode === 0, Number(body.amount));
    if (outcome === "not_found") return new Response("not found", { status: 404 });
    if (outcome === "lookup_error" || outcome === "update_error") {
      return new Response("retry later", { status: 500 }); // MoMo se retry
    }
    return new Response(null, { status: 204 }); // MoMo yeu cau 204
  }

  if (gateway === "zalopay") {
    const key2 = Deno.env.get("ZALOPAY_KEY2");
    if (!key2) return json(503, { error: "payment_gateway_not_configured" });
    const { data, mac } = body;
    if (typeof data !== "string" || !mac) return json(200, { return_code: -1, return_message: "bad request" });
    const expected = await hmacSha256Hex(key2, data);
    if (expected !== mac) return json(200, { return_code: -1, return_message: "mac not equal" });
    let payload: Record<string, unknown>;
    try { payload = JSON.parse(data); } catch { return json(200, { return_code: -1, return_message: "bad data" }); }
    // ZaloPay chi callback khi thanh toan THANH CONG.
    const outcome = await settle(String(payload.app_trans_id), true, Number(payload.amount));
    if (outcome === "not_found") return json(200, { return_code: -1, return_message: "order not found" });
    if (outcome === "lookup_error" || outcome === "update_error") {
      return json(200, { return_code: 0, return_message: "retry" }); // != 1 -> ZaloPay retry
    }
    if (outcome === "amount_mismatch") return json(200, { return_code: -1, return_message: "amount mismatch" });
    return json(200, { return_code: 1, return_message: "success" });
  }

  return json(400, { error: "unknown_gateway" });
});
