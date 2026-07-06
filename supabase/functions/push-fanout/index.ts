// Invoked (by DB trigger via pg_net, or directly) with {user_ids, title, body, data}.
// Fails closed until FCM HTTP v1 delivery is implemented. Secrets Edge-only.
Deno.serve(async (req) => {
  const fanoutSecret = Deno.env.get("PUSH_FANOUT_SECRET");
  if (!fanoutSecret) {
    return new Response("push fanout not configured", { status: 503 });
  }
  if (req.headers.get("x-fanout-secret") !== fanoutSecret) {
    return new Response("forbidden", { status: 403 });
  }
  const { user_ids, title, body, data } = await req.json().catch(() => ({}));
  if (!Array.isArray(user_ids) || !title || !body || data === undefined) {
    return new Response(JSON.stringify({ error: "missing_push_fields" }), { status: 400 });
  }
  if (!Deno.env.get("GOOGLE_FCM_SA_JSON")) {
    return new Response(JSON.stringify({ error: "fcm_not_configured" }), {
      status: 503,
      headers: { "Content-Type": "application/json" },
    });
  }
  return new Response(JSON.stringify({ error: "fcm_sender_not_implemented" }), {
    status: 501,
    headers: { "Content-Type": "application/json" },
  });
});
