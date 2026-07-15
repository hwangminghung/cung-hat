import { createClient } from "jsr:@supabase/supabase-js@2";
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";

// Teaser "Ai thich ban" cho user FREE: KHONG BAO GIO tra URL anh goc.
// Moi liker: dam bao ban mosaic (resize 16px -> JPEG) ton tai o
// profile-photos/<liker>/teaser.jpg roi ky URL 600s. Kem tuoi/tick/1 genre chung.
// KHONG tra id/ten — chi du lieu "nha hang" an toan.
Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return new Response("unauthorized", { status: 401 });

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // [AUDIT H3] endpoint dat (decode/resize anh) ma khong co rate limit —
  // dung chung consume_service_rate_limit voi sign-photo. 60 luot/ngay du
  // cho moi lan mo man teaser, chan client hong/ke pha hoai spam.
  const { data: allowed, error: rlErr } = await admin.rpc("consume_service_rate_limit", {
    p_user: user.id, p_bucket: "likes_teaser", p_limit: 60, p_window: "1 day",
  });
  if (rlErr) {
    console.error("[likes-teaser] rate limit rpc failed", rlErr);
    return new Response("retry later", { status: 500 });
  }
  if (allowed !== true) {
    return new Response(JSON.stringify({ error: "rate_limited" }), {
      status: 429, headers: { "Content-Type": "application/json" },
    });
  }

  // Likers cua caller: like/super len minh, chua match voi minh, khong xoa mem, khong block 2 chieu.
  const { data: swipes } = await admin.from("swipes")
    .select("swiper_id, created_at")
    .eq("target_type", "user").eq("target_id", user.id)
    .in("direction", ["like", "super"])
    .order("created_at", { ascending: false }).limit(12);
  const likerIds = [...new Set((swipes ?? []).map((s: { swiper_id: string }) => s.swiper_id))]
    .filter((id) => id !== user.id);

  const { data: myGenres } = await admin.from("user_genres").select("genre_id").eq("user_id", user.id);
  const mySet = new Set((myGenres ?? []).map((g: { genre_id: string }) => g.genre_id));

  const ids = likerIds.slice(0, 6);
  const out: unknown[] = [];
  if (ids.length > 0) {
    const inList = `(${ids.join(",")})`; // uuid tu DB (swipes.swiper_id), khong phai input client
    // [AUDIT H3] 4 query batch thay ~24 query per-liker.
    const [{ data: profs }, { data: matchRows }, { data: blockRows }, { data: genreRows }] =
      await Promise.all([
        admin.from("profiles")
          .select("id, dob, verified_badge, soft_deleted_at, photo_paths")
          .in("id", ids),
        admin.from("matches").select("user_a, user_b")
          .or(`and(user_a.eq.${user.id},user_b.in.${inList}),and(user_b.eq.${user.id},user_a.in.${inList})`),
        admin.from("blocks").select("blocker_id, blocked_id")
          .or(`and(blocker_id.eq.${user.id},blocked_id.in.${inList}),and(blocked_id.eq.${user.id},blocker_id.in.${inList})`),
        admin.from("user_genres").select("user_id, genre_id").in("user_id", ids),
      ]);
    const profById = new Map((profs ?? []).map((p: { id: string }) => [p.id, p]));
    // Set chua ca user.id — vo hai vi `ids` khong bao gio chua user.id (da filter).
    const matchedIds = new Set((matchRows ?? []).flatMap(
      (m: { user_a: string; user_b: string }) => [m.user_a, m.user_b]));
    const blockedIds = new Set((blockRows ?? []).flatMap(
      (b: { blocker_id: string; blocked_id: string }) => [b.blocker_id, b.blocked_id]));
    const genresById = new Map<string, string[]>();
    for (const g of (genreRows ?? []) as { user_id: string; genre_id: string }[]) {
      genresById.set(g.user_id, [...(genresById.get(g.user_id) ?? []), g.genre_id]);
    }

    for (const id of ids) {
      const p = profById.get(id) as {
        dob: string | null; verified_badge: boolean | null;
        soft_deleted_at: string | null; photo_paths: string[] | null;
      } | undefined;
      if (!p || p.soft_deleted_at) continue;
      if (matchedIds.has(id)) continue; // loai da-match
      if (blockedIds.has(id)) continue; // block 2 chieu

      let teaserUrl: string | null = null;
      const photo0 = (p.photo_paths ?? [])[0];
      if (photo0) {
        const teaserPath = `${id}/teaser.jpg`;
        // Cache: chi generate khi chua co (don gian — doi anh se duoc phu o lan
        // upload sau vi client goi lai; chap nhan teaser cu toi da vai ngay).
        const { data: existing } = await admin.storage.from("profile-photos").list(id, { search: "teaser.jpg" });
        if (!existing || existing.length === 0) {
          const { data: orig } = await admin.storage.from("profile-photos").download(photo0);
          if (orig) {
            try {
              const img = await Image.decode(new Uint8Array(await orig.arrayBuffer()));
              const w = 16;
              const h = Math.max(1, Math.round(img.height * (w / img.width)));
              const small = img.resize(w, h);
              const jpg = await small.encodeJPEG(60);
              await admin.storage.from("profile-photos")
                .upload(teaserPath, jpg, { contentType: "image/jpeg", upsert: true });
            } catch (_e) {
              // Anh hong/format la: bo qua mosaic, con lai van tra (teaser_url null).
            }
          }
        }
        const { data: signed } = await admin.storage.from("profile-photos").createSignedUrl(teaserPath, 600);
        teaserUrl = signed?.signedUrl ?? null;
      }

      const shared = (genresById.get(id) ?? []).find((g) => mySet.has(g)) ?? null;
      const age = p.dob
        ? Math.floor((Date.now() - new Date(p.dob).getTime()) / (365.25 * 24 * 3600 * 1000))
        : null;
      out.push({ teaser_url: teaserUrl, age, verified: !!p.verified_badge, shared_genre: shared });
    }
  }
  return new Response(JSON.stringify({ likers: out }), { headers: { "Content-Type": "application/json" } });
});
