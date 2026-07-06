import { createClient } from "jsr:@supabase/supabase-js@2";

// Initiates a venue-booking payment (real-world service → MoMo/ZaloPay, NOT IAP).
// Fails closed until signed gateway create-order calls are implemented.
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const { plan_id, venue_id, amount_minor, gateway } = await req.json().catch(() => ({}));
  if (!plan_id || !venue_id || !amount_minor) {
    return new Response(JSON.stringify({ error: "missing_payment_fields" }), { status: 400 });
  }
  if (!["momo", "zalopay"].includes(gateway)) {
    return new Response(JSON.stringify({ error: "bad_gateway" }), { status: 400 });
  }

  const configured = gateway === "momo"
    ? Deno.env.get("MOMO_PARTNER_CODE") && Deno.env.get("MOMO_ACCESS_KEY") && Deno.env.get("MOMO_SECRET_KEY")
    : Deno.env.get("ZALOPAY_APP_ID") && Deno.env.get("ZALOPAY_KEY1") && Deno.env.get("ZALOPAY_KEY2");
  if (!configured) {
    return new Response(JSON.stringify({ error: "payment_gateway_not_configured" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ error: "payment_gateway_not_implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  });
});
