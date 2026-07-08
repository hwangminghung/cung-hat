import { createClient } from "jsr:@supabase/supabase-js@2";

// Mints short-lived (600s) signed URLs for a TARGET user's photos, if the caller is allowed to see them.
// Client passes its JWT + only a `target_id` (never a path). Returns { urls: string[] }.
// Empty array => target has no photos, is soft-deleted, or is blocked in either direction.
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const body = await req.json().catch(() => ({}));
  const target_id = body?.target_id;
  if (typeof target_id !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(target_id)) {
    // 4xx bodies share the { error } shape (see 429 below); the client throws on
    // any non-2xx before reading the body, so no consumer parses urls from a 400.
    return new Response(JSON.stringify({ error: "invalid_target" }), {
      status: 400, headers: { "Content-Type": "application/json" },
    });
  }
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Gate: target exists, not soft-deleted. (Never trust a path from the client — only target_id.)
  const { data: prof } = await admin.from("profiles")
    .select("photo_paths,soft_deleted_at").eq("id", target_id).maybeSingle();
  const paths: string[] = prof?.photo_paths ?? [];
  if (!paths.length || prof?.soft_deleted_at) {
    return new Response(JSON.stringify({ urls: [] }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  // Block check applies only to OTHERS; a user's own photos are always visible to them.
  if (target_id !== user.id) {
    // [B-1] chong scrape: toi da 300 luot sign nguoi khac / ngay / caller.
    const { data: allowed, error: rlErr } = await admin.rpc("consume_service_rate_limit", {
      p_user: user.id, p_bucket: "sign_photo", p_limit: 300, p_window: "1 day",
    });
    if (rlErr) { console.error("[sign-photo] rate limit rpc failed", rlErr); return new Response("retry later", { status: 500 }); }
    if (allowed !== true) return new Response(JSON.stringify({ error: "rate_limited" }), { status: 429, headers: { "Content-Type": "application/json" } });

    const { count } = await admin.from("blocks").select("*", { count: "exact", head: true })
      .or(`and(blocker_id.eq.${user.id},blocked_id.eq.${target_id}),and(blocker_id.eq.${target_id},blocked_id.eq.${user.id})`);
    if ((count ?? 0) > 0) {
      return new Response(JSON.stringify({ urls: [] }), {
        status: 403, headers: { "Content-Type": "application/json" },
      });
    }
  }

  // Batched sign: createSignedUrls -> array of { error, path, signedUrl }. Keep only successes.
  // TTL is 10 min, not seconds: the client caches this batch for the life of a detail
  // sheet, and a carousel's later pages only fetch their URL when the user swipes to
  // them — a tight expiry made the 2nd+ photo 400 into the monogram fallback. Still
  // short-lived enough that a leaked URL is useless minutes later.
  const SIGNED_URL_TTL_SECONDS = 600;
  const { data: signed } = await admin.storage.from("profile-photos")
    .createSignedUrls(paths, SIGNED_URL_TTL_SECONDS);
  const urls = (signed ?? [])
    .map((s) => s.signedUrl)
    .filter((u): u is string => Boolean(u));

  return new Response(JSON.stringify({ urls }), {
    headers: { "Content-Type": "application/json" },
  });
});
