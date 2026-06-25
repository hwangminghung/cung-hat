import { createClient } from "jsr:@supabase/supabase-js@2";

// Initiates a venue-booking payment (real-world service → MoMo/ZaloPay, NOT IAP).
// Resolves the user from the JWT; inserts the booking with service role; returns a pay URL.
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { plan_id, venue_id, amount_minor, gateway } = await req.json();
  if (!["momo", "zalopay"].includes(gateway)) {
    return new Response(JSON.stringify({ error: "bad_gateway" }), { status: 400 });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const gatewayRef = crypto.randomUUID();
  const { error } = await admin.from("venue_bookings").insert({
    plan_id, venue_id, user_id: user.id, amount_minor, gateway,
    gateway_ref: gatewayRef, state: "initiated",
  });
  if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400 });

  // TODO(prod): call MoMo/ZaloPay create-order with the merchant signature (MOMO_*/ZALOPAY_*),
  // set redirect/ipnUrl -> payments-webhook, and return the gateway's real pay URL.
  const payUrl = `https://sandbox.pay.local/${gateway}/${gatewayRef}`;
  return new Response(JSON.stringify({ pay_url: payUrl, gateway_ref: gatewayRef }), {
    headers: { "Content-Type": "application/json" },
  });
});
