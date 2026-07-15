# Audit Fixes 2026-07-16 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix toàn bộ findings từ audit 2026-07-16: C1 (IAP init không được gọi), H1 (RLS không lọc tin hidden), H2 (chat history mất tin mới khi >1000), H3 (likes-teaser không rate-limit + N+1), M1-M5, M7, L1-L4, L6-L7.

**Architecture:** DB trước (migration + pgTAP), rồi edge functions TS + CI, rồi Flutter (data layer → shared widgets → screens → shell). Mỗi task tự chứa, commit riêng. TDD với test có sẵn harness: pgTAP theo pattern `chat_test.sql` (jwt claims giả), Flutter theo mocktail + `rpcOk` + provider overrides.

**Tech Stack:** Flutter/Riverpod 3/mocktail, Supabase (Postgres 17, pgTAP, Deno 2 edge functions), GitHub Actions.

**Ngoài phạm vi (chốt từ report):** M6 (FCM/SMS provider — chờ external creds, code fail-closed đúng), L5 (hướng l10n — cần quyết định sản phẩm).

**Gates cuối:** `flutter analyze` = 0 · `flutter test` xanh toàn bộ · `supabase test db` xanh toàn bộ · CI 3 job xanh.

---

## Task 1: [H1+L2] Migration ẩn tin hidden + membership check mark-read

**Files:**
- Create: `supabase/migrations/20260716100000_hide_hidden_messages.sql`
- Test: `supabase/tests/hidden_messages_test.sql`

- [ ] **Step 1: Viết pgTAP test (fail trước migration)**

```sql
-- supabase/tests/hidden_messages_test.sql
-- Run with: supabase test db
-- Chung minh fix audit H1+L2:
--   * policy select messages loc hidden/soft_deleted_at (ca match lan keo)
--   * get_my_matches unread KHONG dem tin hidden
--   * mark_match_read tu choi non-member (23514), member van lives_ok
-- Harness jwt-claims gia giong chat_test.sql.
begin;
select plan(6);

-- A = 00000000-0000-0000-0000-0000000000a1 (user_a < user_b theo CHECK cua matches)
-- B = 00000000-0000-0000-0000-0000000000a2
-- C = 00000000-0000-0000-0000-0000000000c3 (nguoi ngoai)
-- match id = 00000000-0000-0000-0000-0000000000d4
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000a1'),
  ('00000000-0000-0000-0000-0000000000a2'),
  ('00000000-0000-0000-0000-0000000000c3')
  on conflict (id) do nothing;
insert into public.matches (id, user_a, user_b, status) values
  ('00000000-0000-0000-0000-0000000000d4',
   '00000000-0000-0000-0000-0000000000a1',
   '00000000-0000-0000-0000-0000000000a2',
   'active')
  on conflict (id) do nothing;
-- A gui 2 tin: 1 tin thuong + 1 tin bi moderation an (hidden=true).
insert into public.messages (id, thread_type, thread_id, sender_id, body, hidden) values
  ('00000000-0000-0000-0000-0000000000e1', 'match',
   '00000000-0000-0000-0000-0000000000d4',
   '00000000-0000-0000-0000-0000000000a1', 'tin thuong', false),
  ('00000000-0000-0000-0000-0000000000e2', 'match',
   '00000000-0000-0000-0000-0000000000d4',
   '00000000-0000-0000-0000-0000000000a1', 'tin bi an', true);

-- 1) participant (B) chi thay tin KHONG hidden.
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a2"}';
set local role authenticated;
select is((select count(*)::int from public.messages
           where thread_id='00000000-0000-0000-0000-0000000000d4'),
          1, 'participant khong thay tin hidden');

-- 2) policy keo cung loc hidden (kiem tra qual, khoi seed ca keo).
reset role;
set local role postgres;
select ok((select qual ilike '%hidden%' from pg_policies
           where schemaname='public' and tablename='messages'
             and policyname='messages_select_keo'),
          'messages_select_keo loc hidden');

-- 3) get_my_matches: unread cua B chi dem tin KHONG hidden (=1, khong phai 2).
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a2"}';
set local role authenticated;
select is((select unread from public.get_my_matches()
           where match_id is not null limit 1),
          1, 'unread khong dem tin hidden');

-- 4) mark_match_read: nguoi ngoai (C) bi tu choi 23514.
reset role;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000c3"}';
set local role authenticated;
select throws_ok(
  $$ select public.mark_match_read('00000000-0000-0000-0000-0000000000d4'::uuid) $$,
  '23514', null, 'non-member khong mark read duoc');

-- 5) member (A) mark read lives_ok.
reset role;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000a1"}';
set local role authenticated;
select lives_ok(
  $$ select public.mark_match_read('00000000-0000-0000-0000-0000000000d4'::uuid) $$,
  'member mark read lives_ok');

-- 6) row message_reads da ghi cho A.
reset role;
set local role postgres;
select is((select count(*)::int from public.message_reads
           where thread_id='00000000-0000-0000-0000-0000000000d4'
             and user_id='00000000-0000-0000-0000-0000000000a1'),
          1, 'message_reads row ghi cho A');

reset role;
select * from finish();
rollback;
```

Lưu ý: `get_my_matches` trả `setof match_summary` với cột `match_id`? KHÔNG — composite `match_summary` có cột đầu là `id` (xem 0011_inbox.sql). Trước khi chạy, mở `0011_inbox.sql` xác nhận tên cột đầu của composite; nếu là `id` thì sửa test 3 thành `select is((select unread from public.get_my_matches() limit 1), 1, ...)`.

- [ ] **Step 2: Chạy test xác nhận FAIL**

Run: `supabase test db` (cần `supabase db start` trước nếu stack chưa chạy)
Expected: `hidden_messages_test` FAIL ở test 1 (thấy 2 tin) / test 2 (qual chưa có hidden) / test 4 (không throw).

- [ ] **Step 3: Viết migration**

```sql
-- supabase/migrations/20260716100000_hide_hidden_messages.sql
-- [AUDIT H1] admin_action_report hide/remove set hidden/soft_deleted_at nhung
-- policy select KHONG loc -> tin bi moderate van hien nguyen voi participant
-- (T&S vo tac dung; PDPL hide chi duoc cuu mot phan nho unmatch).
-- Fix: loc hidden + soft_deleted_at ngay trong policy (ca 2 thread type),
-- va get_my_matches khong dem/khong lay last_sender tu tin da an.
-- [AUDIT L2] mark_match_read / mark_keo_read khong check membership ->
-- insert duoc row rac message_reads voi uuid bat ky. Fix: check nhu send_message.

drop policy if exists messages_select_participant on public.messages;
create policy messages_select_participant on public.messages for select
  using (thread_type='match'
         and hidden = false
         and soft_deleted_at is null
         and app_private.in_match(thread_id));

drop policy if exists messages_select_keo on public.messages;
create policy messages_select_keo on public.messages for select
  using (thread_type='keo'
         and hidden = false
         and soft_deleted_at is null
         and app_private.in_keo(thread_id));

-- Body copy tu 20260706140000_inbox_turn_pill.sql, them loc hidden/soft_deleted_at
-- vao 2 subquery unread + last_sender_id.
create or replace function public.get_my_matches()
returns setof public.match_summary language sql security definer set search_path='' as $$
  select m.id,
    case when m.user_a = auth.uid() then m.user_b else m.user_a end as other_id,
    (select display_name from public.profiles p
       where p.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end) as other_name,
    (select count(*)::int from public.messages msg
       where msg.thread_type='match' and msg.thread_id = m.id
         and msg.sender_id <> auth.uid()
         and msg.hidden = false and msg.soft_deleted_at is null
         and msg.created_at > coalesce(
           (select last_read_at from public.message_reads r
             where r.thread_type='match' and r.thread_id=m.id and r.user_id=auth.uid()),
           'epoch')) as unread,
    (select msg.sender_id from public.messages msg
       where msg.thread_type='match' and msg.thread_id = m.id
         and msg.hidden = false and msg.soft_deleted_at is null
       order by msg.created_at desc limit 1) as last_sender_id
  from public.matches m
  where m.status='active' and (m.user_a=auth.uid() or m.user_b=auth.uid())
  order by m.created_at desc;
$$;

create or replace function public.mark_match_read(p_thread uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not app_private.in_match(p_thread) then
    raise exception 'not_a_member' using errcode='check_violation';
  end if;
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('match', p_thread, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;

create or replace function public.mark_keo_read(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('keo', p_keo, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;
```

Lưu ý hành vi client đã kiểm: `ChatScreen`/`KeoChatScreen` gọi markRead với `.catchError((_) {})` nên non-member raise không vỡ UI.

- [ ] **Step 4: Apply migration + chạy lại test PASS**

Run: `supabase db reset` (hoặc `supabase migration up`) rồi `supabase test db`
Expected: `hidden_messages_test` 6/6 PASS, các test cũ (chat_test, inbox_turn_test, unmatch_test...) vẫn PASS. Nếu `inbox_turn_pill`/`my_keos` test cũ vỡ vì thay đổi get_my_matches → đọc kỹ, chỉ được thêm điều kiện lọc, không đổi cột.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260716100000_hide_hidden_messages.sql supabase/tests/hidden_messages_test.sql
git commit -m "fix(db): an tin hidden/soft-deleted khoi participant + membership check mark-read (audit H1+L2)"
```

---

## Task 2: [M4] pgTAP guard — mọi bảng public phải bật RLS

**Files:**
- Test: `supabase/tests/rls_coverage_test.sql`

- [ ] **Step 1: Viết test**

```sql
-- supabase/tests/rls_coverage_test.sql
-- [AUDIT M4] baseline_grants dung `alter default privileges` grant-all cho bang
-- tuong lai -> migration nao tao bang ma QUEN enable RLS la authenticated
-- doc/ghi tu do ngay. Guard: moi bang thuong trong public phai relrowsecurity.
begin;
select plan(1);
select is_empty(
  $$ select c.relname::text from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'r'
       and not c.relrowsecurity $$,
  'moi bang public deu bat RLS');
select * from finish();
rollback;
```

- [ ] **Step 2: Chạy PASS ngay (35/35 bảng hiện có RLS — guard cho tương lai)**

Run: `supabase test db`
Expected: PASS. Nếu FAIL → có bảng thiếu RLS thật, dừng lại báo user.

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/rls_coverage_test.sql
git commit -m "test(db): guard moi bang public phai bat RLS (audit M4)"
```

---

## Task 3: [H3] likes-teaser: rate-limit + gộp query N+1

**Files:**
- Modify: `supabase/functions/likes-teaser/index.ts`

(Không có deno test harness trong repo; type-check qua CI `deno check` ở Task 4. Kiểm hành vi bằng đọc lại diff + gates.)

- [ ] **Step 1: Viết lại phần đầu function — thêm rate limit ngay sau auth**

Sau dòng `const admin = createClient(...)` (dòng 15), thêm:

```ts
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
```

- [ ] **Step 2: Gộp N+1 — thay vòng lặp per-liker queries bằng 4 query batch**

Thay toàn bộ đoạn từ `const out: unknown[] = [];` đến hết vòng `for` bằng:

```ts
  const ids = likerIds.slice(0, 6);
  const out: unknown[] = [];
  if (ids.length > 0) {
    const inList = `(${ids.join(",")})`; // uuid tu DB (swipes.swiper_id), khong phai input client
    // 4 query batch thay ~24 query per-liker (audit H3).
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
      if (matchedIds.has(id)) continue;   // da match -> khong teaser
      if (blockedIds.has(id)) continue;   // block 2 chieu

      let teaserUrl: string | null = null;
      const photo0 = (p.photo_paths ?? [])[0];
      if (photo0) {
        const teaserPath = `${id}/teaser.jpg`;
        // Cache: chi generate khi chua co (doi anh se duoc phu o lan upload sau).
        const { data: existing } = await admin.storage.from("profile-photos")
          .list(id, { search: "teaser.jpg" });
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
              // Anh hong/format la: bo qua mosaic, van tra teaser_url null.
            }
          }
        }
        const { data: signed } = await admin.storage.from("profile-photos")
          .createSignedUrl(teaserPath, 600);
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
```

Chú ý: `matchedIds`/`blockedIds` chứa cả `user.id` — vô hại vì `ids` không bao giờ chứa `user.id` (đã filter ở likerIds).

- [ ] **Step 3: Đọc lại toàn file xác nhận không còn query trong loop ngoài storage ops**

- [ ] **Step 4: Commit**

```bash
git add supabase/functions/likes-teaser/index.ts
git commit -m "fix(edge): rate-limit likes-teaser + gop N+1 thanh 4 query batch (audit H3)"
```

---

## Task 4: [M5+L1+L7] Edge hardening: safeEqual, validate ingest, CI deno check

**Files:**
- Modify: `supabase/functions/_shared/hmac.ts`
- Modify: `supabase/functions/payments-webhook/index.ts:71,86-88`
- Modify: `supabase/functions/send-sms/index.ts:37-41`
- Modify: `supabase/functions/push-fanout/index.ts:8`
- Modify: `supabase/functions/ingest-places-venues/index.ts:7-9`
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Thêm safeEqual vào _shared/hmac.ts**

```ts
/// [AUDIT L1] So sanh chu ky/secret constant-time — `===` short-circuit
/// theo byte khac dau tien, mo ra timing side-channel (kho khai thac qua
/// mang nhung chuan an toan la khong de lo).
export function safeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  if (ea.length !== eb.length) return false;
  let diff = 0;
  for (let i = 0; i < ea.length; i++) diff |= ea[i] ^ eb[i];
  return diff === 0;
}
```

- [ ] **Step 2: Dùng safeEqual ở 4 function**

`payments-webhook/index.ts`:
- import: `import { hmacSha256Hex, json, safeEqual } from "../_shared/hmac.ts";`
- dòng 71: `if (typeof body.signature !== "string" || !safeEqual(expected, body.signature)) {`
- dòng 88: `if (typeof mac !== "string" || !safeEqual(expected, mac)) return json(200, { return_code: -1, return_message: "mac not equal" });`
  (dòng 86 giữ check `typeof data !== "string" || !mac` như cũ)

`send-sms/index.ts`:
- import: `import { json, safeEqual } from "../_shared/hmac.ts";`
- dòng 37-40:
```ts
  const ok = sigHeader.split(" ").some((part) => {
    const [ver, sig] = part.split(",");
    return ver === "v1" && typeof sig === "string" && safeEqual(sig, expected);
  });
```

`push-fanout/index.ts`:
- thêm import: `import { safeEqual } from "../_shared/hmac.ts";`
- dòng 8: `const got = req.headers.get("x-fanout-secret"); if (!got || !safeEqual(got, secret)) return new Response("forbidden", { status: 403 });`

`ingest-places-venues/index.ts`:
- thêm import: `import { safeEqual } from "../_shared/hmac.ts";`
- dòng 7: `const got = req.headers.get("x-ingest-secret"); if (!got || !safeEqual(got, secret)) return new Response("forbidden", { status: 403 });`

- [ ] **Step 3: [L7] Validate input ingest-places-venues**

Ngay sau destructuring body (dòng 8-9):

```ts
  if (typeof lat !== "number" || !Number.isFinite(lat) ||
      typeof lng !== "number" || !Number.isFinite(lng) ||
      typeof radius_m !== "number" || !(radius_m > 0 && radius_m <= 50000)) {
    return new Response(JSON.stringify({ error: "bad_geo_input" }), {
      status: 400, headers: { "Content-Type": "application/json" },
    });
  }
```

- [ ] **Step 4: [M5] Thêm job deno check vào CI**

Thêm vào cuối `.github/workflows/ci.yml`:

```yaml
  edge:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v2
        with: { deno-version: v2.x }
      - run: deno check supabase/functions/*/index.ts supabase/functions/_shared/*.ts
```

- [ ] **Step 5: Nếu máy local có deno → chạy `deno check supabase/functions/*/index.ts supabase/functions/_shared/*.ts`; không có thì để CI xác nhận**

- [ ] **Step 6: Commit**

```bash
git add supabase/functions .github/workflows/ci.yml
git commit -m "fix(edge): safeEqual constant-time + validate ingest geo + CI deno check (audit M5+L1+L7)"
```

---

## Task 5: [H2] Chat history: desc + limit + đảo chiều

**Files:**
- Modify: `lib/features/chat/data/chat_repository.dart:34-44,83-93`
- Test: `test/features/chat/chat_repository_test.dart`

- [ ] **Step 1: Sửa test hiện có thành hành vi mới (fail trước)**

Trong `chat_repository_test.dart`:

1. Sửa helper `stubTableSelect` — chuỗi giờ là `...order().limit()`:

```dart
/// Stub chuỗi from(table).select().eq()*.order().limit() trả [rows]; trả
/// (filter, ordered) để verify tham số `order` và `limit`.
({PostgrestFilterBuilder<PostgrestList> fb, PostgrestTransformBuilder<PostgrestList> ob})
    stubTableSelect(
  MockSupabaseClient client,
  String table,
  PostgrestList rows,
) {
  final qb = _MockQueryBuilder();
  final fb = _MockListFilter();
  final ob = _MockListOrdered();
  final lb = _MockListOrdered();
  when(() => client.from(table)).thenAnswer((_) => qb);
  when(() => qb.select(any())).thenAnswer((_) => fb);
  when(() => fb.eq(any(), any())).thenAnswer((_) => fb);
  when(
    () => fb.order(
      any(),
      ascending: any(named: 'ascending'),
      nullsFirst: any(named: 'nullsFirst'),
      referencedTable: any(named: 'referencedTable'),
    ),
  ).thenAnswer((_) => ob);
  when(() => ob.limit(any(), referencedTable: any(named: 'referencedTable')))
      .thenAnswer((_) => lb);
  when(
    () => lb.then<dynamic>(any(), onError: any(named: 'onError')),
  ).thenAnswer((invocation) {
    final onValue = invocation.positionalArguments.first as Function;
    return Future<dynamic>.value(rows).then<dynamic>((v) => onValue(v));
  });
  return (fb: fb, ob: ob);
}
```

2. Thay 2 test `history/keoHistory xin created_at TĂNG dần` bằng:

```dart
  // BUG audit H2: PostgREST max_rows=1000 cat AM THAM; order tang dan lam
  // thread >1000 tin MAT SACH tin moi nhat. Hanh vi dung: lay trang MOI nhat
  // (desc + limit) roi dao lai cho UI cu->moi.
  PostgrestList get _twoDayRowsDesc => [_twoDayRows[1], _twoDayRows[0]]; // moi truoc

  test('history lay trang MOI nhat (desc+limit) roi dao ve cu->moi', () async {
    final client = MockSupabaseClient();
    final stubs = stubTableSelect(client, 'messages', _twoDayRowsDesc);

    final msgs = await ChatRepository(client).history('t1');

    expect(msgs.map((m) => m.id).toList(), ['m-cu', 'm-moi']);
    verify(
      () => stubs.fb.order(
        'created_at',
        ascending: false,
        nullsFirst: any(named: 'nullsFirst'),
        referencedTable: any(named: 'referencedTable'),
      ),
    ).called(1);
    verify(() => stubs.ob.limit(
          ChatRepository.historyPageSize,
          referencedTable: any(named: 'referencedTable'),
        )).called(1);
  });

  test('keoHistory lay trang MOI nhat (desc+limit) roi dao ve cu->moi', () async {
    final client = MockSupabaseClient();
    final stubs = stubTableSelect(client, 'messages', _twoDayRowsDesc);

    final msgs = await ChatRepository(client).keoHistory('k1');

    expect(msgs.map((m) => m.id).toList(), ['m-cu', 'm-moi']);
    verify(
      () => stubs.fb.order(
        'created_at',
        ascending: false,
        nullsFirst: any(named: 'nullsFirst'),
        referencedTable: any(named: 'referencedTable'),
      ),
    ).called(1);
    verify(() => stubs.ob.limit(
          ChatRepository.historyPageSize,
          referencedTable: any(named: 'referencedTable'),
        )).called(1);
  });
```

Lưu ý: `_twoDayRowsDesc` là getter cấp top-level đặt cạnh `_twoDayRows`. Nếu chữ ký `limit` của SDK không có `referencedTable` → bỏ named arg đó trong stub + verify (kiểm tra bằng analyze).

- [ ] **Step 2: Chạy test xác nhận FAIL**

Run: `flutter test test/features/chat/chat_repository_test.dart`
Expected: FAIL (code còn ascending:true, không limit).

- [ ] **Step 3: Sửa chat_repository**

```dart
  /// So tin toi da tai moi lan mo thread. PostgREST `max_rows=1000` cat AM
  /// THAM: neu order tang dan, thread dai hon limit se mat TIN MOI NHAT.
  /// Lay trang moi nhat (desc + limit) roi dao lai cho UI cu->moi.
  static const historyPageSize = 100;

  Future<List<Message>> history(String threadId) async {
    final rows = await _client
        .from('messages')
        .select()
        .eq('thread_type', 'match')
        .eq('thread_id', threadId)
        .order('created_at', ascending: false)
        .limit(historyPageSize);
    return (rows as List)
        .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
        .reversed
        .toList();
  }
```

`keoHistory` sửa y hệt (giữ `eq('thread_type', 'keo')`, `eq('thread_id', keoId)`).

- [ ] **Step 4: Chạy PASS**

Run: `flutter test test/features/chat/` — Expected: PASS toàn bộ (kể cả chat_screen_test cũ).

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/data/chat_repository.dart test/features/chat/chat_repository_test.dart
git commit -m "fix(chat): history lay trang moi nhat desc+limit thay vi bi max_rows cat mat tin moi (audit H2)"
```

---

## Task 6: [M2] Gộp widget chat trùng lặp

**Files:**
- Create: `lib/features/chat/presentation/chat_widgets.dart`
- Modify: `lib/features/chat/presentation/chat_screen.dart` (xoá `_MessageBubble`, `_Composer`, gọn `_doSend`)
- Modify: `lib/features/keo/presentation/keo_chat_screen.dart` (như trên)

- [ ] **Step 1: Tạo chat_widgets.dart**

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/message.dart';
import 'chat_timeline.dart';
import 'song_share_widgets.dart';

/// [AUDIT M2] Bubble + composer + dialog an toàn dùng chung cho chat đôi
/// (chat_screen) và chat nhóm kèo (keo_chat_screen) — trước đây copy nguyên
/// văn ~200 dòng ở cả 2 màn và đã bắt đầu phân kỳ.

/// Hỏi xác nhận trước khi gửi tin có dấu hiệu nhạy cảm (tiền bạc/OTP...).
/// Trả true nếu user vẫn muốn gửi.
Future<bool> confirmUnsafeMessage(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Gửi tin này?'),
      content: const Text(
        'Tin nhắn có vẻ liên quan tới tiền bạc hoặc thông tin nhạy cảm. Hãy kiểm tra kỹ trước khi gửi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Gửi'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.senderName,
  });

  final Message message;
  final bool mine;

  /// Tên người gửi hiện trên bubble của NGƯỜI KHÁC trong chat nhóm —
  /// null với bubble của mình, chat 1-1, hoặc khi roster chưa tải.
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(maxWidth: 292),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (senderName != null && senderName!.isNotEmpty) ...[
              Text(
                senderName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.tertiaryPop,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
            ],
            if (isSongShare(message.body))
              SongShareContent(body: message.body, mine: mine)
            else
              Text(
                message.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              bubbleTime(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                color: mine
                    ? AppColors.onPrimary.withValues(alpha: 0.72)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onShareSong,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onShareSong;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: const BoxDecoration(color: AppColors.background),
        child: Row(
          children: [
            IconButton.outlined(
              key: const Key('share_song_btn'),
              tooltip: 'Gửi bài tủ',
              onPressed: sending ? null : onShareSong,
              icon: const Icon(Icons.music_note_outlined),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Nhắn gì đó...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              key: const Key('send_btn'),
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Refactor 2 màn chat dùng widget chung**

`chat_screen.dart`: thêm `import 'chat_widgets.dart';` — xoá class `_MessageBubble`, `_Composer`; thay `_MessageBubble(message:..., mine:...)` → `MessageBubble(message:..., mine:...)`; `_Composer(...)` → `ChatComposer(...)`; trong `_doSend` thay block showDialog bằng:

```dart
    if (messageLooksUnsafe(text)) {
      if (!await confirmUnsafeMessage(context)) return;
      if (!mounted) return;
    }
```

`keo_chat_screen.dart`: tương tự — import `../../chat/presentation/chat_widgets.dart`; xoá 2 class local; `_MessageBubble(message:..., mine:..., senderName:...)` → `MessageBubble(...)`; xoá import không dùng còn sót (analyze sẽ chỉ).

- [ ] **Step 3: Chạy test + analyze**

Run: `flutter analyze && flutter test test/features/chat/ test/features/keo/`
Expected: 0 issue, PASS (test cũ tìm theo Key/text, không theo tên class private).

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/presentation/chat_widgets.dart lib/features/chat/presentation/chat_screen.dart lib/features/keo/presentation/keo_chat_screen.dart
git commit -m "refactor(chat): gop MessageBubble/ChatComposer/dialog an toan dung chung 2 man chat (audit M2)"
```

---

## Task 7: [M3] Error state cho lịch sử chat

**Files:**
- Modify: `lib/features/chat/presentation/chat_screen.dart` (body Expanded)
- Modify: `lib/features/keo/presentation/keo_chat_screen.dart` (body Expanded)
- Test: `test/features/chat/chat_history_error_test.dart`

- [ ] **Step 1: Viết widget test (fail trước)**

```dart
// test/features/chat/chat_history_error_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/chat_screen.dart';
import '../../support/supabase_mocks.dart';

class _MockChatRepo extends Mock implements ChatRepository {}

void main() {
  testWidgets('lỗi tải history → EmptyState + Thử lại refetch', (tester) async {
    final repo = _MockChatRepo();
    when(() => repo.markRead(any())).thenAnswer((_) async {});
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          chatRepositoryProvider.overrideWithValue(repo),
          // StateError (Error) bo qua auto-retry backoff cua Riverpod.
          messageHistoryProvider('t1').overrideWith((ref) {
            calls++;
            if (calls == 1) throw StateError('net');
            return Future.value(const <Message>[]);
          }),
          liveMessagesProvider('t1')
              .overrideWith((ref) => const Stream<Message>.empty()),
        ],
        child: const MaterialApp(
          home: ChatScreen(matchId: 't1', otherName: 'Trang'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được tin nhắn'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không tải được tin nhắn'), findsNothing);
    expect(find.textContaining('Chưa có tin nhắn'), findsOneWidget);
  });
}
```

Lưu ý: `supabaseClientProvider` cần import từ `package:cung_hat/core/providers/supabase_providers.dart`. `_myUid` đọc `client.auth` — mock chưa stub sẽ throw, `_myUid` đã catch → null, OK.

- [ ] **Step 2: Chạy FAIL** — `flutter test test/features/chat/chat_history_error_test.dart` (đang hiển thị 'Chưa có tin nhắn' thay vì error).

- [ ] **Step 3: Sửa 2 màn chat**

`chat_screen.dart`, thêm import `'../../../shared/widgets/empty_state.dart'`, trong `Expanded(...)`:

```dart
          Expanded(
            child: historyAsync.hasError && messages.isEmpty
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Không tải được tin nhắn',
                    subtitle: 'Kiểm tra kết nối rồi thử lại.',
                    actionLabel: 'Thử lại',
                    onAction: () =>
                        ref.invalidate(messageHistoryProvider(widget.matchId)),
                  )
                : messages.isEmpty
                    ? Center( /* giữ nguyên block 'Chưa có tin nhắn...' */ )
                    : ListView.builder( /* giữ nguyên */ ),
          ),
```

`keo_chat_screen.dart` tương tự với `keoMessageHistoryProvider(widget.keoId)` và giữ copy hiện có.

- [ ] **Step 4: Chạy PASS** — `flutter test test/features/chat/ test/features/keo/`

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/presentation/chat_screen.dart lib/features/keo/presentation/keo_chat_screen.dart test/features/chat/chat_history_error_test.dart
git commit -m "fix(chat): error state + Thu lai cho lich su thay vi gia dang empty (audit M3)"
```

---

## Task 8: [C1] IAP: gọi init() lúc startup + feedback khi buy fail

**Files:**
- Modify: `lib/features/billing/application/iap_controller.dart`
- Modify: `lib/app/app.dart` (initState)
- Modify: `lib/features/billing/presentation/store_screen.dart:158-160`
- Test: `test/features/billing/iap_controller_test.dart`

- [ ] **Step 1: Viết unit test (fail trước)**

```dart
// test/features/billing/iap_controller_test.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/billing/application/billing_providers.dart';
import 'package:cung_hat/features/billing/application/iap_controller.dart';
import 'package:cung_hat/features/billing/data/billing_repository.dart';

class _MockIap extends Mock implements InAppPurchase {}

class _MockBillingRepo extends Mock implements BillingRepository {}

PurchaseDetails _purchased(String productId) => PurchaseDetails(
      purchaseID: 'txn-1',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'receipt-data',
        source: 'google_play',
      ),
      transactionDate: '0',
      status: PurchaseStatus.purchased,
    );

void main() {
  late _MockIap iap;
  late _MockBillingRepo repo;
  late StreamController<List<PurchaseDetails>> purchases;
  late ProviderContainer container;
  late IapController controller;

  setUp(() {
    iap = _MockIap();
    repo = _MockBillingRepo();
    purchases = StreamController<List<PurchaseDetails>>();
    when(() => iap.isAvailable()).thenAnswer((_) async => true);
    when(() => iap.purchaseStream).thenAnswer((_) => purchases.stream);
    when(() => repo.myEntitlements()).thenAnswer((_) async => []);
    when(
      () => repo.deliverPurchase(
        platform: any(named: 'platform'),
        storeProductId: any(named: 'storeProductId'),
        storeTxnId: any(named: 'storeTxnId'),
        receipt: any(named: 'receipt'),
      ),
    ).thenAnswer((_) async {});
    final p = Provider((ref) => IapController(ref, iap: iap));
    container = ProviderContainer(
      overrides: [billingRepositoryProvider.overrideWithValue(repo)],
    );
    controller = container.read(p);
  });

  tearDown(() {
    purchases.close();
    container.dispose();
  });

  test('init nghe purchaseStream: purchase đến → deliverPurchase', () async {
    await controller.init();
    purchases.add([_purchased('pro')]);
    await pumpEventQueue();
    verify(
      () => repo.deliverPurchase(
        platform: any(named: 'platform'),
        storeProductId: 'pro',
        storeTxnId: 'txn-1',
        receipt: 'receipt-data',
      ),
    ).called(1);
  });

  test('init idempotent: gọi 2 lần không double-listen/không throw', () async {
    await controller.init();
    await controller.init(); // stream single-sub: listen lần 2 sẽ throw nếu thiếu guard
    purchases.add([_purchased('pro')]);
    await pumpEventQueue();
    verify(
      () => repo.deliverPurchase(
        platform: any(named: 'platform'),
        storeProductId: any(named: 'storeProductId'),
        storeTxnId: any(named: 'storeTxnId'),
        receipt: any(named: 'receipt'),
      ),
    ).called(1);
  });

  test('buy trả false khi catalog fail (UI có tín hiệu báo lỗi)', () async {
    when(() => repo.storeProductIds(any())).thenThrow(StateError('net'));
    expect(await controller.buy('pro'), isFalse);
  });
}
```

- [ ] **Step 2: Chạy FAIL** — `flutter test test/features/billing/iap_controller_test.dart` (constructor chưa nhận iap, buy trả void).

- [ ] **Step 3: Sửa iap_controller.dart**

```dart
class IapController {
  IapController(this.ref, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final Ref ref;
  final InAppPurchase _iap;
  Map<String, String>? _catalog;
  bool _initialized = false;

  /// Call from app startup (NOT from the constructor) — touches platform
  /// channels. [AUDIT C1] Không gọi init thì purchaseStream không có listener:
  /// user trả tiền nhưng validate-iap không bao giờ chạy, entitlement không cấp.
  /// Idempotent: purchaseStream là single-subscription, listen 2 lần sẽ throw.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (!await _iap.isAvailable()) return;
      _iap.purchaseStream.listen(_onPurchases);
    } catch (e) {
      debugPrint('IAP init skipped: $e');
    }
  }
```

`buy` đổi chữ ký + return:

```dart
  /// Kick-off mua hàng. Trả false khi không mở được flow store (catalog lỗi,
  /// product không tồn tại, store throw) để UI báo user thay vì im lặng.
  Future<bool> buy(String feature) async {
    final productId = await _productIdFor(feature);
    if (productId == null) return false;
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return false;
      final product = response.productDetails.first;
      final param = PurchaseParam(productDetails: product);
      if (_consumables.contains(feature)) {
        await _iap.buyConsumable(purchaseParam: param);
      } else {
        await _iap.buyNonConsumable(purchaseParam: param);
      }
      return true;
    } catch (e) {
      debugPrint('IAP buy failed for $feature: $e');
      return false;
    }
  }
```

(`_onPurchases` giữ nguyên.)

- [ ] **Step 4: Wire init trong app.dart initState**

```dart
  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    // [AUDIT C1] purchaseStream phải có listener TRƯỚC khi user mua và ngay
    // khi app mở lại (store replay transaction treo) — init() tự nuốt lỗi
    // platform channel nên an toàn cả trên dev/test.
    unawaited(ref.read(iapControllerProvider).init());
  }
```

- [ ] **Step 5: store_screen báo lỗi khi buy fail**

```dart
                            onBuy: () async {
                              final ok = await ref
                                  .read(iapControllerProvider)
                                  .buy(product.type);
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Không mở được cửa hàng. Thử lại sau.',
                                    ),
                                  ),
                                );
                              }
                            },
```

- [ ] **Step 6: Chạy PASS** — `flutter analyze && flutter test test/features/billing/`

- [ ] **Step 7: Commit**

```bash
git add lib/features/billing/application/iap_controller.dart lib/app/app.dart lib/features/billing/presentation/store_screen.dart test/features/billing/iap_controller_test.dart
git commit -m "fix(iap): goi init() luc startup de purchaseStream co listener + buy bao loi (audit C1)"
```

---

## Task 9: [M1] Settings: xoá tài khoản có try/catch + chặn double-tap

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Test: `test/features/settings/settings_delete_error_test.dart`

- [ ] **Step 1: Viết widget test (fail trước)**

```dart
// test/features/settings/settings_delete_error_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/settings/application/settings_providers.dart';
import 'package:cung_hat/features/settings/data/settings_repository.dart';
import 'package:cung_hat/features/settings/presentation/settings_screen.dart';

class _MockSettingsRepo extends Mock implements SettingsRepository {}

void main() {
  testWidgets('xoá tài khoản lỗi mạng → SnackBar, không unhandled exception',
      (tester) async {
    final repo = _MockSettingsRepo();
    when(() => repo.myConsents()).thenAnswer((_) async => {});
    when(() => repo.deleteAccount()).thenThrow(StateError('net'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Xóa tài khoản'));
    await tester.tap(find.text('Xóa tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa')); // nút confirm trong dialog
    await tester.pumpAndSettle();

    expect(find.text('Không xoá được tài khoản, thử lại.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Chạy FAIL** — hiện tại throw không bắt → test fail vì exception.

- [ ] **Step 3: Sửa settings_screen.dart**

Chuyển `SettingsScreen` thành `ConsumerStatefulWidget` (state `_SettingsScreenState`), thêm `bool _deleting = false;`. Các method bỏ tham số `(context, ref)` — dùng `context`/`ref` của State. `_SettingsTile.onTap` đổi thành `VoidCallback?` (ListTile nhận null = disabled).

```dart
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Hành động này không thể hoàn tác. Tài khoản và dữ liệu của bạn sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _deleting) return;
    setState(() => _deleting = true);
    try {
      await ref.read(settingsRepositoryProvider).deleteAccount();
      await ref.read(supabaseClientProvider).auth.signOut();
      if (mounted) context.go('/auth');
    } catch (_) {
      // [AUDIT M1] offline/RPC lỗi: trước đây exception thoát không bắt —
      // user không biết đã xoá hay chưa.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không xoá được tài khoản, thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
```

Tile: `onTap: _deleting ? null : _deleteAccount`.

- [ ] **Step 4: Chạy PASS** — `flutter test test/features/settings/` (cả settings_toggle_error_test cũ).

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart test/features/settings/settings_delete_error_test.dart
git commit -m "fix(settings): xoa tai khoan co error handling + chan double-tap (audit M1)"
```

---

## Task 10: [M7+L4] HomeShell: lazy IndexedStack giữ state tab

**Files:**
- Modify: `lib/app/home_shell.dart:47-78`
- Test: `test/app/home_shell_test.dart` (thêm 1 test)

- [ ] **Step 1: Thêm test (fail trước)**

```dart
  testWidgets('tab đã thăm giữ state khi chuyển đi (IndexedStack)',
      (tester) async {
    final fakeLoc = _FakeLocationService();
    when(() => fakeLoc.captureAndPush()).thenAnswer((_) async => false);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidatesProvider(null)
              .overrideWith((ref) => Future.value(<Candidate>[])),
          locationServiceProvider.overrideWithValue(fakeLoc),
          openKeosProvider.overrideWith((ref) => Future.value(<Keo>[])),
          inboxProvider.overrideWith((ref) => Future.value(<MatchSummary>[])),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đôi'));
    await tester.pumpAndSettle();

    // Trước fix: switch remount → InboxScreen bị dispose khi rời tab.
    expect(find.byType(InboxScreen, skipOffstage: false), findsOneWidget);
  });
```

(Import thêm `package:cung_hat/features/chat/presentation/inbox_screen.dart`.)

- [ ] **Step 2: Chạy FAIL** — `flutter test test/app/home_shell_test.dart`

- [ ] **Step 3: Sửa home_shell.dart**

```dart
class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  /// [AUDIT M7] Tab đã thăm được giữ sống trong IndexedStack (giữ scroll/deck
  /// state); tab CHƯA thăm là SizedBox để giữ lazy-init như switch cũ
  /// (không fetch inbox/kèo trước khi user vào tab — home_shell_test khẳng
  /// định inboxCalls == 0 trước lần thăm đầu).
  final Set<int> _visited = {0};

  // ... _labels/_icons/_iconsSel giữ nguyên ...

  void _select(int i) {
    // inboxProvider là FutureProvider one-shot: invalidate mỗi lần CHỌN tab 2
    // (kể cả re-tap) — coi như pull-to-refresh. (comment cũ giữ nguyên ý)
    if (i == 2) ref.invalidate(inboxProvider);
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget Function()>[
      () => const DoiDeckScreen(),
      () => const KeoBoardScreen(),
      () => InboxScreen(onFindKeo: () => _select(1)),
      () => const _ProfileTab(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _visited.contains(i) ? tabs[i]() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_iconsSel[i]),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}
```

(L4: nhánh `_ => Center(Text(...))` chết biến mất cùng switch.)

- [ ] **Step 4: Chạy PASS toàn bộ test app** — `flutter test test/app/` (4 test cũ + 1 mới; test `inboxCalls == 0` trước khi thăm Chat vẫn phải xanh nhờ lazy `_visited`).

- [ ] **Step 5: Commit**

```bash
git add lib/app/home_shell.dart test/app/home_shell_test.dart
git commit -m "fix(shell): lazy IndexedStack giu state tab da tham, xoa nhanh switch chet (audit M7+L4)"
```

---

## Task 11: [L3+L6] Cleanups: fail-fast config + dọn ảnh mồ côi

**Files:**
- Modify: `lib/main.dart:15-16`
- Modify: `lib/features/photos/data/photo_repository.dart:52-63`
- Test: `test/features/photos/photo_repository_test.dart` (thêm 1 test)

- [ ] **Step 1: Thêm test dọn ảnh mồ côi (fail trước)**

Thêm vào `photo_repository_test.dart` (tái dùng `_MockGoTrue`, `_FakeUser`, `_MockPhotoStorage` sẵn có trong file):

```dart
  test('uploadPhoto dọn file mồ côi khi RPC lưu path fail', () async {
    final client = MockSupabaseClient();
    final auth = _MockGoTrue();
    final storage = _MockPhotoStorage();
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_FakeUser('u1'));
    when(() => storage.upload(any(), any())).thenAnswer((_) async {});
    when(() => storage.remove(any())).thenAnswer((_) async {});
    when(() => client.rpc('set_my_photo_paths', params: any(named: 'params')))
        .thenThrow(StateError('net'));

    final repo = PhotoRepository(client, storage: storage);
    await expectLater(
      repo.uploadPhoto(Uint8List(1), slot: 0),
      throwsStateError,
    );
    final removed =
        verify(() => storage.remove(captureAny())).captured.single as List;
    expect(removed, hasLength(1));
    expect(removed.single as String, startsWith('u1/0_'));
  });
```

- [ ] **Step 2: Chạy FAIL** — `flutter test test/features/photos/photo_repository_test.dart`

- [ ] **Step 3: Sửa uploadPhoto**

```dart
  Future<List<String>> uploadPhoto(
    Uint8List bytes, {
    required int slot,
    List<String> current = const [],
  }) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${slot}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _storage.upload(path, bytes);
    final next = [...current, path];
    try {
      await _client.rpc('set_my_photo_paths', params: {'p_paths': next});
    } catch (_) {
      // [AUDIT L6] RPC fail sau khi upload OK → file mồ côi trong bucket
      // (không path nào trỏ tới). Dọn best-effort rồi ném lại cho UI báo lỗi.
      try {
        await _storage.remove([path]);
      } catch (_) {}
      rethrow;
    }
    return next;
  }
```

- [ ] **Step 4: [L3] Fail-fast config trong main.dart**

```dart
  final cfg = AppConfig.fromEnv();
  // [AUDIT L3] Thiếu dart-define thì Supabase.initialize nổ FormatException
  // khó hiểu — assert sớm với message chỉ thẳng cách chạy đúng (debug-only).
  assert(
    cfg.isConfigured,
    'Thiếu SUPABASE_URL/SUPABASE_ANON_KEY — chạy với '
    '--dart-define-from-file=env/dev.json (hoặc dev.emulator.json).',
  );
```

- [ ] **Step 5: Chạy PASS** — `flutter analyze && flutter test test/features/photos/ test/core/`

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/features/photos/data/photo_repository.dart test/features/photos/photo_repository_test.dart
git commit -m "fix: fail-fast config thieu dart-define + don anh mo coi khi RPC fail (audit L3+L6)"
```

---

## Task 12: Gates toàn cục + kết thúc nhánh

- [ ] **Step 1:** `flutter analyze` → 0 issues
- [ ] **Step 2:** `flutter test` → toàn bộ xanh (362 cũ + ~10 mới)
- [ ] **Step 3:** `supabase test db` → toàn bộ pgTAP xanh (212 cũ + 7 mới)
- [ ] **Step 4:** Đọc lại `git diff master --stat` khớp đúng phạm vi 11 task
- [ ] **Step 5:** Dùng skill superpowers:finishing-a-development-branch (merge master / PR / giữ nhánh — theo lựa chọn user; pattern repo này: merge master + tag + xoá nhánh, CI xanh 3 job)
