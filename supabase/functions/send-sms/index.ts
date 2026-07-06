// Production Send-SMS auth hook. Swap PROVIDER impl for a VN SMS gateway later.
// Secrets come from Edge env (SMS_API_KEY); never in the client.
Deno.serve(async (req) => {
  const { user, sms } = await req.json().catch(() => ({}));
  const phone = user?.phone ?? sms?.phone;
  const otp = sms?.otp;
  if (!phone || !otp) {
    return new Response(JSON.stringify({ error: "missing phone/otp" }), { status: 400 });
  }
  if (!Deno.env.get("SMS_API_KEY")) {
    return new Response(JSON.stringify({ error: "sms_provider_not_configured" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }
  return new Response(JSON.stringify({ error: "sms_provider_not_implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  });
});
