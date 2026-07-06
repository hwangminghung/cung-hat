// Gateway IPN/webhook. Fails closed until signature verification and state updates
// are implemented for the chosen gateway.
Deno.serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  const { gateway, gateway_ref } = body;

  if (!gateway_ref) return new Response("missing gateway_ref", { status: 400 });
  const configured = gateway === "momo"
    ? Deno.env.get("MOMO_PARTNER_CODE") && Deno.env.get("MOMO_ACCESS_KEY") && Deno.env.get("MOMO_SECRET_KEY")
    : gateway === "zalopay"
      ? Deno.env.get("ZALOPAY_APP_ID") && Deno.env.get("ZALOPAY_KEY1") && Deno.env.get("ZALOPAY_KEY2")
      : null;
  if (!configured) {
    return new Response(JSON.stringify({ error: "payment_gateway_not_configured" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }
  return new Response(JSON.stringify({ error: "payment_webhook_not_implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  });
});
