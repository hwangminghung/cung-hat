// Production Send-SMS auth hook. Swap PROVIDER impl for a VN SMS gateway later.
// Secrets come from Edge env (SMS_API_KEY); never in the client.
Deno.serve(async (req) => {
  const { user, sms } = await req.json().catch(() => ({}));
  const phone = user?.phone ?? sms?.phone;
  const otp = sms?.otp;
  if (!phone || !otp) {
    return new Response(JSON.stringify({ error: "missing phone/otp" }), { status: 400 });
  }
  // TODO(prod): call the chosen VN provider here using Deno.env.get("SMS_API_KEY").
  console.log(`[send-sms] would send OTP ${otp} to ${phone}`);
  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
