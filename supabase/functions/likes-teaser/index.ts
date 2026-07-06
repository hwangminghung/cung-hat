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

  const out: unknown[] = [];
  for (const id of likerIds.slice(0, 6)) {
    const { data: p } = await admin.from("profiles")
      .select("dob, verified_badge, soft_deleted_at, photo_paths").eq("id", id).maybeSingle();
    if (!p || p.soft_deleted_at) continue;
    // loai da-match
    const { count: matched } = await admin.from("matches").select("*", { count: "exact", head: true })
      .or(`and(user_a.eq.${user.id},user_b.eq.${id}),and(user_a.eq.${id},user_b.eq.${user.id})`);
    if ((matched ?? 0) > 0) continue;
    // block 2 chieu
    const { count: blocked } = await admin.from("blocks").select("*", { count: "exact", head: true })
      .or(`and(blocker_id.eq.${user.id},blocked_id.eq.${id}),and(blocker_id.eq.${id},blocked_id.eq.${user.id})`);
    if ((blocked ?? 0) > 0) continue;

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

    const { data: gs } = await admin.from("user_genres").select("genre_id").eq("user_id", id);
    const shared = (gs ?? []).map((g: { genre_id: string }) => g.genre_id).find((g) => mySet.has(g)) ?? null;
    const age = p.dob
      ? Math.floor((Date.now() - new Date(p.dob).getTime()) / (365.25 * 24 * 3600 * 1000))
      : null;
    out.push({ teaser_url: teaserUrl, age, verified: !!p.verified_badge, shared_genre: shared });
  }
  return new Response(JSON.stringify({ likers: out }), { headers: { "Content-Type": "application/json" } });
});
