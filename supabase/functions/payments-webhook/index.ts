import { createClient } from "jsr:@supabase/supabase-js@2";

// Gateway IPN/webhook: verify signature, mark the booking paid + compute commission. Service role.
Deno.serve(async (req) => {
  const body = await req.json();
  const { gateway_ref, status } = body;

  // TODO(prod): verify the gateway HMAC signature (MOMO_*/ZALOPAY_*). Reject on mismatch.
  const signatureValid = Boolean(gateway_ref); // placeholder until merchant creds exist
  if (!signatureValid) return new Response("bad signature", { status: 401 });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: booking } = await admin.from("venue_bookings")
    .select("id,amount_minor").eq("gateway_ref", gateway_ref).maybeSingle();
  if (!booking) return new Response("not found", { status: 404 });

  if (status === "paid") {
    const commission = Math.round(booking.amount_minor * 0.1); // 10% platform commission
    await admin.from("venue_bookings").update({ state: "paid", commission_minor: commission })
      .eq("id", booking.id);
  } else {
    await admin.from("venue_bookings").update({ state: "failed" }).eq("id", booking.id);
  }
  return new Response(JSON.stringify({ ok: true }), { headers: { "Content-Type": "application/json" } });
});
