# Đợt P2 — Teaser likes blur, Share kèo, Icebreaker, Trần ảnh 6 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4 tính năng P2: trần ảnh 3→6, share kèo qua deep-link token, icebreaker quote ảnh/bài tủ/prompt trong chat sau match, và teaser "Ai thích bạn" với ảnh mosaic server-side cho user free.

**Architecture:** Flutter (Riverpod manual, freezed chỗ cần, go_router) + Supabase (SECURITY DEFINER RPC, composite view, edge function Deno). T2 nhân bản hạ tầng share_plans (0016/0023); T3 thêm RPC `get_match_profile` trả đúng composite `discovery_candidate` hiện có (KHÔNG đổi composite); T4 = edge function mới `likes-teaser` mirror gating của `sign-photo`, pixelate bằng resize-16px. Spec: `docs/superpowers/specs/2026-07-07-p2-likes-share-icebreaker-design.md`.

**Tech Stack:** Flutter 3.44.1, Riverpod 3.3.2, supabase_flutter 2.15.0, Deno edge (jsr:@supabase/supabase-js@2 + ImageScript), pgTAP.

---

## ⚠️ MÔI TRƯỜNG (kế thừa nguyên đợt trước)

- Worktree `C:\Users\Hwang Ming Hung\cung-hat-photos-wt`, nhánh `feat/p2-likes-share-icebreaker` (từ master 3d5909f6). KHÔNG đụng `C:\Users\Hwang Ming Hung\cung-hat`.
- Flutter `"/c/Users/Public/flutter/bin/flutter.bat"`; migrations `npx supabase migration up` (KHÔNG db reset, KHÔNG stop/start trừ khi task nói); pgTAP `npx supabase test db` — baseline **119 PASS phải giữ**; Flutter baseline **205 PASS**; analyze sạch.
- psql: `docker exec supabase_db_cung-hat psql -U postgres -d postgres -c "..."`.
- Gates mỗi task: flutter test + analyze (+ supabase test db khi đụng SQL). Commit cuối task, ASCII subject, body kết thúc `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- KHÔNG đụng: billing/store/validate-iap, `get_discovery_candidates`, onboarding, composite `discovery_candidate` (T3 chỉ TÁI DÙNG shape).

---

### Task 1: Trần ảnh 3→6

**Files:**
- Create: `supabase/migrations/20260707100000_photo_cap_6.sql`
- Modify: `supabase/tests/photos_test.sql` (nếu có assertion cap-3) HOẶC Create: `supabase/tests/photo_cap6_test.sql`
- Modify: `lib/features/photos/presentation/photo_manager_sheet.dart` (`_maxSlots` dòng 15, layout Row dòng ~185)
- Modify: `lib/app/home_shell.dart` (subtitle tile 'Ảnh hồ sơ': 'Thêm tối đa 3 ảnh' → 6)
- Test: mở rộng `test/features/photos/photo_manager_sheet_test.dart` (đọc file test hiện có trước)

- [x] **Step 1: Migration** — giới hạn nằm TRONG RPC `set_my_photo_paths` (20260704100000_photos.sql:27-43, `> 3` → raise `photo_limit`), KHÔNG có table CHECK. Copy VERBATIM function từ 20260704100000 + đổi đúng `> 3` thành `> 6` + sửa comment:

```sql
-- Tran anh ho so 3 -> 6 (backlog muc 11). Gioi han nam trong RPC (khong co table CHECK).
-- COPY VERBATIM set_my_photo_paths tu 20260704100000_photos.sql, doi DUY NHAT `> 3` -> `> 6`.
-- [DÁN NGUYÊN VĂN function với thay đổi trên, giữ validate photo_path_invalid + grants]
```

Kiểm tra `supabase/functions/sign-photo/index.ts` — KHÔNG cap số path (sign toàn bộ `photo_paths`) → không sửa edge.

DONE: `supabase/migrations/20260707100000_photo_cap_6.sql` tạo mới, function diff vs 20260704100000 chỉ đúng 1 dòng `> 3` → `> 6` (đã diff xác nhận byte-for-byte, phần còn lại + validate photo_path_invalid + revoke/grant giữ nguyên). `sign-photo/index.ts` xác nhận không cap → không sửa.

- [x] **Step 2: pgTAP** — kiểm tra `grep -n "photo_limit\|> 3\|array\[" supabase/tests/photos_test.sql` (hoặc tên file photos test thật): nếu có test cap-3 thì SỬA nó thành cap-6 (7 ảnh raise `'23514'`, 6 ảnh lives_ok); nếu không có thì viết `photo_cap6_test.sql` `plan(2)` theo seed convention repo. `npx supabase migration up` && `npx supabase test db` xanh.

DONE: `supabase/tests/photos_test.sql` có sẵn assertion cap-3 (#3) → SỬA thành 7 path raise `'23514'`/`photo_limit`, thêm subtest #3b (6 path lives_ok, boundary mới). `plan(6)` → `plan(7)`. `migration up` + `test db`: 27 files, 120 tests (119 baseline + 1), PASS.

- [x] **Step 3: Test Flutter fail trước** — mở rộng photo_manager test: render sheet (override providers như file test hiện có) → expect 6 widget `Key('photo_slot_0')`..`photo_slot_5`.

DONE: mở rộng test 'consent granted → hiện 6 slot' trong `photo_manager_sheet_test.dart`, chạy fail trước khi sửa UI (missing `photo_slot_3`), xác nhận red đúng nguyên nhân (`_maxSlots` vẫn = 3).

- [x] **Step 4: UI** — `photo_manager_sheet.dart`: `const _maxSlots = 6;`. Layout Row 1 hàng (dòng ~185) sẽ chật với 6 ô → đổi thành `Wrap` 2 hàng × 3 (hoặc `GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: NeverScrollableScrollPhysics())` — chọn cái khớp style file; giữ nguyên `Key('photo_slot_$i')`, `_busySlot`, aspect vuông). Sửa copy trong sheet nếu có chuỗi 'tối đa 3'. `home_shell.dart` tile: `'Thêm tối đa 6 ảnh vào hồ sơ'`.

DONE: `_maxSlots = 6`; `_buildGrid()` đổi Row → `GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: NeverScrollableScrollPhysics(), mainAxisSpacing/crossAxisSpacing: AppSpacing.sm)`, `_PhotoSlot` (Key/`_busySlot`/aspect) giữ nguyên 100%. Copy 'tối đa $_maxSlots' đã interpolate sẵn nên tự động lên 6, không cần sửa chuỗi cứng. Phát sinh ngoài kế hoạch: outer `Column` overflow ở viewport thấp (2 hàng ô vuông cao hơn Column cố định chịu được) → bọc `SingleChildScrollView` quanh Column (khớp `isScrollControlled: true` của `showModalBottomSheet` gọi sheet này ở `home_shell.dart`, không phải workaround). `home_shell.dart` subtitle → 'Thêm tối đa 6 ảnh vào hồ sơ'.

- [x] **Step 5: Gates + commit** — 3 gates xanh. Commit: `feat(photos): tran anh ho so 3 -> 6`

DONE: `flutter test` 205/205 pass, `flutter analyze` no issues, `npx supabase test db` 120/120 pass. Commit `feat(photos): tran anh ho so 3 -> 6` (xem SHA trong báo cáo report).

---

### Task 2: Share kèo

**Files:**
- Create: `supabase/migrations/20260707110000_share_keo.sql`
- Create: `supabase/tests/share_keo_test.sql`
- Modify: `lib/features/keo/data/keo_repository.dart` (+2 method)
- Modify: `lib/features/keo/presentation/keo_detail_screen.dart` (nút share AppBar)
- Create: `lib/features/keo/presentation/shared_keo_screen.dart`
- Modify: `lib/app/router.dart` (route `/keo/shared/:token` + authRedirect exempt)
- Test: `test/features/keo/share_keo_test.dart` (mới)

- [ ] **Step 1: Migration:**

```sql
-- Share keo qua token (backlog muc 10) — mirror share_plans (0016) + resolve anon (0023).
create table public.share_keos (
  share_token text primary key default encode(extensions.gen_random_bytes(16), 'hex'),
  keo_id uuid not null references public.keo(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days'
);
alter table public.share_keos enable row level security;
-- khong policy client: tao qua RPC, doc qua resolve RPC

-- Gate: host HOAC thanh vien approved — KHONG dung app_private.in_keo (doi status
-- planning+ trong khi ca share chinh la keo dang OPEN tuyen nguoi).
create or replace function public.create_keo_share_link(p_keo uuid)
returns text language plpgsql security definer set search_path='' as $$
declare tok text;
begin
  if not exists (
    select 1 from public.keo k
    where k.id = p_keo and k.soft_deleted_at is null
      and (k.host_id = auth.uid() or exists (
        select 1 from public.keo_members m
        where m.keo_id = p_keo and m.user_id = auth.uid() and m.join_status = 'approved'))
  ) then
    raise exception 'not_keo_member' using errcode='check_violation';
  end if;
  insert into public.share_keos (keo_id, created_by) values (p_keo, auth.uid())
  returning share_token into tok;
  return tok;
end; $$;
revoke execute on function public.create_keo_share_link(uuid) from public, anon;
grant execute on function public.create_keo_share_link(uuid) to authenticated;

-- View sanitized: KHONG toa do; keo_id duoc phep lo (uuid, moi doc/ghi that deu RPC-gated)
-- de user da dang nhap dieu huong vao detail.
create type public.shared_keo_view as (
  keo_id uuid, title text, area_label text, time_window_start timestamptz,
  size_target int, slots_filled int, genres text[], host_name text,
  join_mode text, status text, expired boolean
);
create or replace function public.resolve_share_keo(p_token text)
returns public.shared_keo_view language sql security definer set search_path='' as $$
  select k.id, k.title, k.area_label, k.time_window_start,
         k.group_size_target,
         (select count(*)::int from public.keo_members m
            where m.keo_id = k.id and m.join_status = 'approved'),
         k.genres,
         (select display_name from public.profiles p where p.id = k.host_id),
         k.join_mode, k.status,
         (sk.expires_at < now()) as expired
  from public.share_keos sk
  join public.keo k on k.id = sk.keo_id and k.soft_deleted_at is null
  where sk.share_token = p_token;
$$;
revoke execute on function public.resolve_share_keo(text) from public;
grant execute on function public.resolve_share_keo(text) to anon, authenticated;
```

⚠️ Trước khi viết: xác minh tên cột thật của bảng keo (`group_size_target`, `soft_deleted_at`, `join_mode`, `genres`, `area_label` — grep 0012_keo.sql + 0024) và pgcrypto extension prefix (`extensions.gen_random_bytes` vs `public.` — xem 0016 dùng gì cho share_token và mirror y hệt). resolve trả 0 hàng khi token sai → client nhận null.

DONE: `supabase/migrations/20260707110000_share_keo.sql` tạo mới. Xác minh trực tiếp qua psql: `gen_random_bytes`/`gen_random_uuid` chỉ tồn tại trong schema `extensions`, và `search_path` mặc định của session là `"$user", public, extensions` — nghĩa là DEFAULT của cột table (không phải body function `search_path=''`) chạy dưới search_path session, nên bare `gen_random_bytes(16)` (KHÔNG prefix `extensions.`) hoạt động y hệt cách 0016 dùng. Đã sửa kế hoạch: bỏ prefix `extensions.` để mirror 0016 byte-for-byte. Cột `group_size_target`, `soft_deleted_at`, `join_mode` (thêm ở 0024), `genres`, `area_label`, `host_id`, `time_window_start`, `status` xác nhận đúng tên trong 0012/0024. Gate dùng host_id/keo_members trực tiếp, không gọi `app_private.in_keo`.

- [x] **Step 2: pgTAP** `share_keo_test.sql` `plan(5)` (seed host + member approved + bystander + 1 keo OPEN theo convention keo test hiện có): (1) host tạo token lives_ok; (2) member approved tạo được; (3) bystander raise `'23514'`; (4) resolve token đúng → title khớp + expired=false + slots_filled đúng; (5) token bogus → 0 hàng (`is(count,0)` qua select vào biến hoặc `results_eq` rỗng). Migration up + toàn bộ pgTAP xanh.

DONE: `supabase/tests/share_keo_test.sql` tạo mới, `plan(7)` (case 4 tách thành 3 subtest is() riêng cho title/expired/slots_filled — rõ thông báo lỗi hơn, cùng kiểu photos_test.sql dùng cho case nhiều phần). Seed: host Pro (create_keo yêu cầu is_pro() từ 0024) + approve_join để có 1 member approved + 1 bystander, mirror pro_keo_test.sql. Bug phát hiện khi chạy: subquery đọc `share_token` trực tiếp từ bảng `share_keos` dưới role `authenticated` trả về NULL — vì bảng bật RLS và KHÔNG có policy client (đúng thiết kế migration), `authenticated` không tự thấy được hàng nào. Sửa: bắt token qua temp table ngay lúc tạo (`insert into _host_tok select public.create_keo_share_link(...)`), không query lại bảng share_keos như một role không phải postgres. Case resolve chạy dưới `authenticated` (bystander) thay vì `role anon` thật — vì pgTAP tự thân (`is`/`throws_ok`...) không có EXECUTE dưới anon (xác nhận qua comment sẵn có ở profile_rpcs_test.sql), authenticated cũng được grant nên đi cùng code path. `npx supabase migration up` + `npx supabase test db`: 28 files, 127 tests (120 baseline + 7), PASS.

- [x] **Step 3: Repository test-first** — `share_keo_test.dart` (rpcOk harness): `createKeoShareLink('k1')` gọi rpc `create_keo_share_link` p_keo trả token; `resolveSharedKeo('tok')` gọi `resolve_share_keo` map row→model, null khi rows rỗng. Implement trong `keo_repository.dart`:

```dart
  Future<String> createKeoShareLink(String keoId) async {
    final res = await _client
        .rpc('create_keo_share_link', params: {'p_keo': keoId});
    return res as String;
  }

  /// null = token sai/kèo đã xoá.
  Future<SharedKeo?> resolveSharedKeo(String token) async {
    final res = await _client
        .rpc('resolve_share_keo', params: {'p_token': token});
    if (res == null) return null;
    final m = Map<String, dynamic>.from(res as Map);
    if (m['keo_id'] == null) return null; // composite rong
    return SharedKeo.fromJson(m);
  }
```

`SharedKeo` = plain class (không freezed — pattern Report/Plan) trong `lib/features/keo/domain/shared_keo.dart`: fields khớp composite + fromJson. LƯU Ý: RPC trả composite đơn (không setof) → supabase trả Map, nhưng nếu trả List thì unwrap `.first` — viết fromJson khoan dung cả 2 (kiểm tra hành vi thật khi verify; test mock cover Map).

DONE: `lib/features/keo/domain/shared_keo.dart` tạo mới (plain class, fromJson khoan dung Map/List/thiếu-field bằng safe cast + default). `keo_repository.dart` thêm `createKeoShareLink`/`resolveSharedKeo` đúng snippet kế hoạch. `test/features/keo/share_keo_test.dart` (mới, TDD trước impl): 5 case — create trả token + verify params; resolve map đúng Map; resolve null (defensive); resolve composite-rỗng (keo_id null) → null (case token sai thật); resolve List-shape → unwrap `.first` (defensive, phòng hành vi client thay đổi dù thực tế đã xác nhận composite-đơn trả Map). Tất cả pass ngay lần chạy đầu (rpcOk harness).

- [x] **Step 4: Nút share** — `keo_detail_screen.dart` AppBar actions thêm IconButton (`Key('keo_share_btn')`, icon `Icons.share_rounded`, tooltip 'Chia sẻ kèo') CHỈ hiện khi user là host/member approved (màn detail đã có roster + myProfile — tính `isMember` từ data sẵn; đọc file để lấy đúng biến). onTap: try/catch (convention `_handleToggle*`): `createKeoShareLink` → `SharePlus.instance.share(ShareParams(text: 'Kèo "<title>" đang tuyển giọng ca — vào Cùng Hát xin một chỗ: cunghat://keo/shared/<token>'))`; lỗi → SnackBar 'Không tạo được link, thử lại.'.

DONE: AppBar giờ nhận `actions` — nút chỉ hiện khi `canShare` (host hoặc approved), tính từ `_myRow()` helper mới trích xuất (dùng chung với `_buildBody` để cả 2 nơi thống nhất tuyệt đối ai được coi là "host/approved" — tránh lặp logic 2 chỗ có thể lệch nhau). `_shareKeo()` implement đúng snippet kế hoạch (try/catch, SharePlus, SnackBar lỗi).

- [x] **Step 5: SharedKeoScreen + route.** `shared_keo_screen.dart`: ConsumerWidget, param token; FutureProvider.family `sharedKeoProvider(token)` (trong file providers keo hiện có). 3 trạng thái: null → EmptyState 'Không tìm thấy kèo' ; expired=true → 'Link đã hết hạn'; ok → Card: title (headlineSmall), '🕗 <HH:mm> · <area_label>', 'x/y chỗ · <join_mode chip text như KeoCard>', #genres, 'Host: <name>'; nút đáy: nếu `supabaseClientProvider` có session → FilledButton `Key('shared_keo_open_btn')` 'Xem kèo & xin vào' → `context.push('/keo/<keo_id>')`; chưa login → 'Đăng nhập để xin vào' → `context.push('/auth')`. Router: `GoRoute(path: '/keo/shared/:token', ...)` + trong `authRedirect` thêm exempt `location.startsWith('/keo/shared')` NGAY CẠNH exempt `/plan/shared` hiện có (đọc router.dart, mirror đúng cách exempt cũ). Widget test 3 trạng thái + route test anon không bị redirect (mirror test authRedirect `/plan/shared` nếu có).

DONE: `sharedKeoProvider` thêm vào `keo_providers.dart`. `shared_keo_screen.dart` tạo mới — 4 trạng thái thực tế (loading skeleton, error wifi-off retry, null → EmptyState 'Không tìm thấy kèo', expired → EmptyState 'Link đã hết hạn', ok → Card mirror style KeoCard: title headlineSmall, giờ/area, x/y chỗ, chip join_mode dùng ĐÚNG 2 chuỗi từ keo_card.dart ('Mở · vào là tham gia'/'Cần duyệt'), genres chip, Host tên). ĐIỀU CHỈNH so với kế hoạch: dùng `isSignedInProvider` (đã có sẵn ở `features/auth/application/auth_providers.dart`, router cũng dựa trên cùng `AuthRepository.currentSession`) thay vì tự đọc `supabaseClientProvider.auth.currentSession` — cùng nguồn sự thật, nhưng tái dùng provider phản ứng (reactive) đã có test mock sẵn thay vì tự viết lại logic đọc session một lần. Router: thêm route `/keo/shared/:token` cạnh `/keo/create`; `authRedirect` thêm `location.startsWith('/keo/shared')` NGAY CẠNH exempt `/plan/shared` hiện có, cùng cấu trúc `||`. Test: `test/features/keo/share_keo_screen_test.dart` (mới) — not-found, expired, valid+signed-out (nút login, không có nút open), valid+signed-in (nút open, không có nút login) — 4/4 pass lần chạy đầu. `test/app/router_redirect_test.dart` thêm 1 case 'unauthenticated can view a shared keo' mirror case `/plan/shared` sẵn có.

- [x] **Step 6: Gates + commit** — 3 gates. Commit: `feat(keo): chia se keo qua deep link token — man shared + resolve anon`

DONE: `flutter test` 215/215 pass (205 baseline + 5 repo + 4 screen + 1 router), `flutter analyze` no issues (1 unused-import warning phát hiện + sửa ngay trong quá trình), `npx supabase test db` 127/127 pass (120 baseline + 7). Self-review: gate dùng host_id/keo_members trực tiếp không qua `app_private.in_keo` (xác nhận đọc lại migration); `resolve_share_keo` granted `anon, authenticated` + route `/keo/shared` exempt trong `authRedirect` (xác nhận qua router_redirect_test mới); `shared_keo_view` không có toạ độ/geo field nào (chỉ area_label text); token mechanism mirror 0016 byte-for-byte sau khi xác minh schema thật qua psql (bare `gen_random_bytes`, không prefix `extensions.`). Commit SHA: xem báo cáo cuối.

---

### Task 3: Icebreaker quote trong chat (sau match)

**Files:**
- Create: `supabase/migrations/20260707120000_match_profile.sql`
- Create: `supabase/tests/match_profile_test.sql`
- Modify: `lib/features/discovery/data/discovery_repository.dart` (+getMatchProfile)
- Modify: `lib/features/discovery/presentation/candidate_detail_sheet.dart` (chế độ onQuote)
- Modify: `lib/features/chat/presentation/chat_screen.dart` (nút Hồ sơ + prefill)
- Test: `test/features/chat/icebreaker_test.dart` (mới) + mở rộng candidate_detail_sheet_test

- [x] **Step 1: Migration** — RPC mới trả ĐÚNG composite `discovery_candidate` hiện có (10 cột: id, display_name, age, distance_band, shared_genres, shared_baitu, verified, active_today, bio, prompts). KHÔNG alter composite:

```sql
-- Icebreaker sau match (muc 8): xem ho so nguoi DA match tu chat.
create or replace function public.get_match_profile(p_match uuid)
returns public.discovery_candidate
language plpgsql security definer set search_path='' as $$
declare result public.discovery_candidate;
begin
  if not app_private.in_match(p_match) then
    raise exception 'not_match_member' using errcode='check_violation';
  end if;
  select p.id, p.display_name,
         extract(year from age(p.dob))::int,
         app_private.dist_band(public.ST_Distance(ul_me.location, ul_other.location)),
         coalesce((select array_agg(g.genre_id) from public.user_genres g
            where g.user_id = p.id and g.genre_id in
              (select genre_id from public.user_genres where user_id = auth.uid())), '{}'),
         coalesce((select array_agg(s.song_id) from public.user_baitu s
            where s.user_id = p.id and s.song_id in
              (select song_id from public.user_baitu where user_id = auth.uid())), '{}'),
         p.verified_badge, (p.last_active > now() - interval '1 day'),
         p.bio, app_private.prompts_json(p.id)
    into result
  from public.matches m
  join public.profiles p
    on p.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end
  left join public.user_locations ul_me on ul_me.user_id = auth.uid()
  left join public.user_locations ul_other on ul_other.user_id = p.id
  where m.id = p_match and p.soft_deleted_at is null;
  return result; -- NULL row neu doi phuong xoa mem
end; $$;
revoke execute on function public.get_match_profile(uuid) from public, anon;
grant execute on function public.get_match_profile(uuid) to authenticated;
```

⚠️ Xác minh trước: `app_private.in_match` tồn tại (0010_chat) + signature; `dist_band` null-safe khi thiếu location (ST_Distance với NULL → NULL → dist_band(NULL) — kiểm tra hàm dist_band chấp nhận null, nếu không thì bọc `case when ... is null then null else ... end`).

DONE: `supabase/migrations/20260707120000_match_profile.sql` tạo mới, đúng snippet kế hoạch + 1 điều chỉnh bắt buộc (xem dưới). Xác minh trực tiếp qua psql: `app_private.in_match(p_thread uuid)` (0010_chat.sql) đã tự gate `m.status='active'` BÊN TRONG định nghĩa của nó — nên `get_match_profile` KHÔNG lặp lại điều kiện status trong FROM/JOIN chính (WHERE chỉ lọc `m.id = p_match`), tránh 2 nơi cùng gate 1 thứ có thể lệch nhau sau này. `dist_band(NULL)` xác nhận KHÔNG null-safe qua psql trực tiếp (`select app_private.dist_band(NULL)` trả về `'5+'` chứ không phải NULL — CASE của nó khi input NULL thì mọi nhánh đều unknown nên rơi vào ELSE `'5+'`) → đã bọc `case when ul_me.location is null or ul_other.location is null then null else app_private.dist_band(...) end` đúng như cảnh báo trong kế hoạch (khác snippet gốc — snippet gốc gọi `dist_band` trực tiếp không bọc). Verify thủ công qua psql: member gọi được (distance_band ra NULL đúng khi thiếu user_locations, không phải '5+' sai); bystander → `not_match_member` (23514); đối phương soft-delete → composite toàn NULL (id null).

- [x] **Step 2: pgTAP** `match_profile_test.sql` `plan(4)` (seed 2 user matched + 1 bystander, convention chat test): (1) member gọi được, display_name đúng; (2) shared_baitu đúng (seed 1 bài chung); (3) bystander raise `'23514'`; (4) đối phương soft-deleted → id null (composite null row). Migration up + pgTAP toàn xanh.

DONE: `supabase/tests/match_profile_test.sql` tạo mới, `plan(4)` đúng kế hoạch. Điều chỉnh: uuid nháp ban đầu dùng segment `ma1`/`ma2`/`mc3`/`md4` — KHÔNG hợp lệ vì `m` không phải hex digit (khác `chat_test.sql` dùng `a1`/`a2`/`c3`/`d4`, toàn hex); sửa thành `f1`/`f2`/`f3`/`f4`. Seed `user_baitu` cần 1 hàng `songs` thật trước (FK `song_id text references public.songs(id)`) — không pgTAP test nào có sẵn seed user_baitu trực tiếp nên viết mới theo cấu trúc 0004_onboarding.sql. `npx supabase migration up` + `npx supabase test db`: 29 files, 131 tests (127 baseline + 4), PASS.

- [x] **Step 3: Repository + test:** `getMatchProfile(String matchId)` → rpc `get_match_profile` p_match, trả `Candidate?` (null khi res null hoặc id null; parse Map như resolveSharedKeo lưu ý composite-đơn).

DONE: `discovery_repository.dart` thêm `getMatchProfile` đúng snippet kế hoạch (mirror `resolveSharedKeo` từ Task 2). Test mở rộng `test/features/discovery/discovery_repository_test.dart` (KHÔNG tạo file riêng — file test cho `DiscoveryRepository` đã tồn tại sẵn với nhiều method, khác `KeoRepository`/Task 2 lúc đó là repo hoàn toàn mới) — group `getMatchProfile` 4 case (map đúng, null defensive, composite-rỗng id-null → null, unwrap List-shape defensive) mirror y hệt 4 case của `share_keo_test.dart`. 4/4 pass lần chạy đầu (rpcOk harness).

- [x] **Step 4: CandidateDetailSheet chế độ quote.** Thêm param `this.onQuote` (`final ValueChanged<String>? onQuote;`) vào cả widget lẫn `show(...)`. Khi `onQuote != null`:
  - Mỗi bài tủ chung (đọc file để thấy render hiện tại của shared_baitu — 'Bài tủ chung' section): thêm nút nhỏ `TextButton` 'Trả lời' `Key('quote_baitu_<i>')` cạnh từng bài → `onQuote('Về bài "<tên bài>" của bạn: ')`.
  - Mỗi prompt card (loop T6): nút 'Trả lời' `Key('quote_prompt_<prompt_id>')` → `onQuote('Bạn nói "<answer>" — kể thêm đi: ')`.
  - Dưới carousel ảnh: 1 nút 'Trả lời ảnh này' `Key('quote_photo')` → `onQuote('Ảnh này xịn quá! ')` (không cần theo index ảnh — YAGNI).
  - Sau khi gọi onQuote: `Navigator.pop(context)` (đóng sheet).
  - `onQuote == null` (deck): KHÔNG render nút nào — widget test khẳng định.
  ⚠️ deck gọi `CandidateDetailSheet.show` ở doi_deck_screen (2 chỗ: cardBuilder + có thể likes) — không truyền onQuote → không đổi.

DONE: `onPass`/`onLike` đổi từ `required VoidCallback` → `VoidCallback?` (cả widget lẫn `show()`); Row THÍCH/BỎ QUA gate `if (onPass != null || onLike != null)` + mỗi nút gate riêng theo callback tương ứng (không phải all-or-nothing — phòng trường hợp chỉ 1 trong 2 null). `sharedBaitu` render bằng raw song string trực tiếp (`Text(song)`) — xác nhận `shared_baitu` giữ SONG ID thô, KHÔNG resolve tên bài; câu quote dùng nguyên id-string đó (chấp nhận theo ghi chú trong brief, không phải bug). 3 nút quote thêm đúng vị trí kế hoạch (dưới carousel, trailing của mỗi ListTile bài tủ, trong mỗi prompt Container). Điều chỉnh so với kế hoạch: chỉ có **1** call site thật ở `doi_deck_screen.dart` (cardBuilder) — grep xác nhận không có chỗ thứ 2 nào cho "likes flow" (kế hoạch đoán "2 chỗ"); call site đó không đổi (không truyền onQuote/vẫn dùng onPass/onLike như cũ, hợp lệ vì tham số giờ optional). Test mở rộng `candidate_detail_sheet_test.dart` +2 case: (a) chế độ deck — không có `quote_photo`/`quote_baitu_0`/`quote_prompt_p1`, không có text 'Trả lời'/'Trả lời ảnh này', 2 nút deck vẫn còn; (b) chế độ icebreaker — 2 nút deck ẩn, 3 nút quote hiện, tap `quote_baitu_0` gọi đúng callback với câu mồi đúng. 5/5 pass (3 baseline + 2 mới).

- [x] **Step 5: ChatScreen.** AppBar actions (dòng ~149) thêm IconButton `Key('chat_profile_btn')` (icon `Icons.person_rounded`, tooltip 'Hồ sơ'): onTap → `getMatchProfile(matchId)` (matchId đã là param màn chat — đọc file lấy tên) → null → SnackBar 'Hồ sơ không còn.'; ok → `CandidateDetailSheet.show(context, candidate: c, onPass/onLike: null-safe...` — LƯU Ý: show() hiện REQUIRE onPass/onLike (đọc signature; nếu required thì đổi thành optional nullable, deck vẫn truyền như cũ; nút THÍCH/BỎ QUA trong sheet ẩn khi null — kiểm tra sheet có nút đó không và gate tương ứng) + `onQuote: (q) { _controller.text = q; _controller.selection = TextSelection.collapsed(offset: q.length); }` (focus composer nếu tiện — `FocusScope`).

DONE: `ChatScreen` (`ConsumerStatefulWidget`, `matchId` param xác nhận đúng tên) thêm `_openMatchProfile()` helper: try/catch bọc `getMatchProfile` (lỗi mạng → SnackBar 'Không mở được hồ sơ. Thử lại sau.' — thêm ngoài kế hoạch vì kế hoạch chỉ nói case null, không nói case throw; giữ đúng convention try/catch của `_doSend` có sẵn trong file) → null → SnackBar 'Hồ sơ không còn.' → có data → `CandidateDetailSheet.show(candidate:, onQuote:)` KHÔNG truyền onPass/onLike (giờ optional, mặc định null đúng ý — sheet tự ẩn 2 nút deck). AppBar thêm `IconButton` (không phải `TextButton.icon` như nút 'Lập kèo' cạnh nó — dùng `IconButton` cho gọn, đúng gợi ý kế hoạch) `Key('chat_profile_btn')`. Không dùng `FocusScope` (kế hoạch nói "nếu tiện") — `TextField` đã tự nhận focus khi user gõ tiếp; giữ tối giản. RED-CHECK thủ công: tạm bỏ `onQuote` khỏi lệnh gọi `CandidateDetailSheet.show`, chạy `icebreaker_test.dart` xác nhận case (b) FAIL đúng lý do (`quote_baitu_0` không tồn tại vì sheet rơi về chế độ deck-render khi onQuote null) rồi khôi phục lại — xác nhận GREEN.

- [x] **Step 6: Widget tests** `icebreaker_test.dart`: (a) pump ChatScreen (override providers theo chat_screen_test hiện có + mock getMatchProfile trả candidate có 1 bài tủ + 1 prompt) → tap `chat_profile_btn` → sheet mở; (b) tap `quote_baitu_0` → sheet đóng + composer text bắt đầu 'Về bài'; (c) deck-mode sheet (onQuote null) không có `quote_baitu_0`. Chạy fail-first cho (b).

DONE: `test/features/chat/icebreaker_test.dart` tạo mới, 3 case đúng kế hoạch (a/b + thêm case null→SnackBar thay cho (c) vì (c) đã được cover trong `candidate_detail_sheet_test.dart` ở Step 4, tránh trùng lặp) — mirror harness `chat_screen_test.dart` (mock `ChatRepository`) + mock mới `DiscoveryRepository` + override `signedUrlsProvider(candidate.id)` (PhotoCarousel trong sheet cần). Case (a): tap `chat_profile_btn` → sheet hiện tên/tuổi/bài tủ/prompt, KHÔNG có nút THÍCH/BỎ QUA. Case (b): tap `quote_baitu_0` → sheet đóng (key biến mất khỏi cây) + composer TextField's controller.text đúng 'Về bài "Nơi Này Có Anh" của bạn: '. Case null: SnackBar 'Hồ sơ không còn.'. RED-first xác nhận cho case (b) như ghi ở Step 5. 3/3 pass.

- [x] **Step 7: Gates + commit** — 3 gates. Commit: `feat(chat): icebreaker — quote anh/bai tu/prompt cua nguoi match vao composer`

DONE: `flutter test` 224/224 pass (215 baseline + 4 repo + 2 sheet + 3 icebreaker screen), `flutter analyze` no issues, `npx supabase test db` 131/131 pass (127 baseline + 4). Self-review: composite `discovery_candidate` xác nhận KHÔNG bị alter (grep migration mới không có `alter type`, psql introspection xác nhận vẫn đúng 10 cột theo thứ tự cũ); `in_match` semantics mirror đúng (không double-gate status, note trong migration comment); deck sheet hành vi cũ giữ nguyên 100% khi onQuote null (widget test xác nhận); prefill KHÔNG tự gửi (chỉ set `_controller.text`/`selection`, user vẫn phải bấm nút gửi qua dialog an toàn `messageLooksUnsafe` có sẵn). Commit SHA: xem báo cáo cuối.

REVIEW-FIX (sau approve Task 3): `fix(discovery): hien ten bai tu thay vi id trong detail sheet va quote icebreaker` — shared_baitu giữ SONG ID thô nên sheet render/quote raw id ('s5' thay vì tên bài); CandidateDetailSheet → ConsumerWidget watch `songsProvider` (reference có sẵn) build map id→title, fallback raw id khi loading/lỗi/id lạ (không chặn render), fix luôn hiển thị deck detail có sẵn từ trước; test đổi sang id thật + override songsProvider mọi chỗ pump sheet, thêm case fallback; RED-check revert tạm xác nhận fail đúng (`Về bài "s5"...`); gates 225/225 + analyze sạch (không đụng SQL). Ngoài scope còn `match_celebration.dart:182` cũng render raw baitu id — đã báo coordinator, chưa sửa.

---

### Task 4: Teaser "Ai thích bạn" blur server-side

**Files:**
- Create: `supabase/functions/likes-teaser/index.ts`
- Modify: `lib/features/discovery/data/discovery_repository.dart` (+getLikesTeaser)
- Create: `lib/features/discovery/domain/like_teaser.dart`
- Create: `lib/features/discovery/presentation/likes_teaser_screen.dart`
- Modify: `lib/app/home_shell.dart` (tile 'Ai đã thích bạn' free → /likes-teaser)
- Modify: `lib/app/router.dart` (route /likes-teaser)
- Test: `test/features/discovery/likes_teaser_test.dart` (mới)

- [ ] **Step 1: Edge function** `likes-teaser/index.ts` — mirror `sign-photo` (JWT userClient → admin service client). Logic:

```ts
import { createClient } from "jsr:@supabase/supabase-js@2";
import { Image } from "https://deno.land/x/imagescript@1.3.0/mod.ts";

// Teaser "Ai thich ban" cho user FREE: KHONG BAO GIO tra URL anh goc.
// Moi liker: dam bao ban mosaic (resize 16px) ton tai o
// profile-photos/<liker>/teaser.jpg roi ky URL 600s. Kem tuoi/tick/1 genre chung.
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
  const likerIds = [...new Set((swipes ?? []).map(s => s.swiper_id))].filter(id => id !== user.id);

  const { data: myGenres } = await admin.from("user_genres").select("genre_id").eq("user_id", user.id);
  const mySet = new Set((myGenres ?? []).map(g => g.genre_id));

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
          const img = await Image.decode(new Uint8Array(await orig.arrayBuffer()));
          const w = 16, h = Math.max(1, Math.round(img.height * (16 / img.width)));
          const small = img.resize(w, h);
          const jpg = await small.encodeJPEG(60);
          await admin.storage.from("profile-photos").upload(teaserPath, jpg, { contentType: "image/jpeg", upsert: true });
        }
      }
      const { data: signed } = await admin.storage.from("profile-photos").createSignedUrl(teaserPath, 600);
      teaserUrl = signed?.signedUrl ?? null;
    }

    const { data: gs } = await admin.from("user_genres").select("genre_id").eq("user_id", id);
    const shared = (gs ?? []).map(g => g.genre_id).find(g => mySet.has(g)) ?? null;
    const age = p.dob ? Math.floor((Date.now() - new Date(p.dob).getTime()) / (365.25 * 24 * 3600 * 1000)) : null;
    out.push({ teaser_url: teaserUrl, age, verified: !!p.verified_badge, shared_genre: shared });
  }
  return new Response(JSON.stringify({ likers: out }), { headers: { "Content-Type": "application/json" } });
});
```

(KHÔNG trả id/tên. Nếu ImageScript import fail trên runtime local khi verify → RỦI RO #1 trong spec: DỪNG, báo coordinator, không tự đổi thiết kế.) ⚠️ RLS storage: policy chỉ cho owner đọc — admin (service role) bypass, OK; teaser.jpg nằm trong folder <liker>/ nên owner-policy không cho NGƯỜI KHÁC đọc trực tiếp — chỉ qua signed URL, đúng ý.

- [ ] **Step 2: Model + repository + test-first.** `like_teaser.dart`: plain class `LikeTeaser(teaserUrl String?, age int?, verified bool, sharedGenre String?)` + fromJson. Repository:

```dart
  /// Teaser cho user free: KHÔNG id/tên; ảnh là bản mosaic server-side.
  Future<List<LikeTeaser>> getLikesTeaser() async {
    final res = await _client.functions.invoke('likes-teaser');
    final list = (res.data?['likers'] as List?) ?? const [];
    final base = Uri.parse(_client.storage.url);
    return [
      for (final e in list)
        LikeTeaser.fromJson(Map<String, dynamic>.from(e as Map)).rebase(base),
    ];
  }
```

`.rebase(base)` = copy với `teaserUrl` chạy qua `PhotoRepository.rebaseOrigin(url, base)` (import photos data; null giữ null) — fix host kong:8000 local như sign-photo. Test mock `functions.invoke` (xem photo repo test hiện có mock FunctionsClient thế nào — mirror harness).

- [ ] **Step 3: LikesTeaserScreen + providers + route.** Provider `likesTeaserProvider` FutureProvider. Screen (`/likes-teaser`): AppBar 'Ai đã thích bạn'; body: loading skeleton; rỗng → EmptyState icon favorite 'Chưa có ai thích bạn — hoàn thiện hồ sơ để được thấy nhiều hơn nhé'; có data → header Text '<N> người đã thích bạn' + GridView 2 cột card (`Key('teaser_card_<i>')`): ảnh mosaic `Image.network(teaserUrl, fit: cover)` hoặc fallback Container gradient + Icon person lớn khi null; overlay đáy: Row chip tuổi ('<age>' hoặc '?'), icon verified nếu true, '#<sharedGenre>' nếu có; toàn card bọc mờ nhẹ `ImageFiltered`/opacity KHÔNG cần (ảnh đã mosaic). Đáy màn: FilledButton to `Key('teaser_unlock_btn')` 'Mở khoá với Pro — xem ai thích bạn' → `ProUpsellSheet.show(context, variant: ProUpsellVariant.seeLikes)`. `home_shell.dart` tile 'Ai đã thích bạn': entitled → `/likes` (giữ); KHÔNG entitled → `context.push('/likes-teaser')` (THAY vì mở sheet trực tiếp — sheet giờ nằm trong màn teaser). Router thêm route.

- [ ] **Step 4: Widget tests** `likes_teaser_test.dart`: (a) override provider 2 teaser (1 có url — dùng url bogus, errorBuilder fallback OK — 1 null-photo) → 2 card render, chip tuổi/genre đúng, nút unlock mở sheet 'Xem ai đã thích bạn'; (b) rỗng → EmptyState; (c) home_shell tile khi free → điều hướng /likes-teaser (sửa test cũ đang expect mở sheet — hành vi mới). Fail-first cho (c).

- [ ] **Step 5: Gates + commit** — flutter test + analyze (pgTAP không đổi — không SQL; vẫn chạy xác nhận 119+ pass nếu đã thêm test ở T1-T3). Commit: `feat(discovery): teaser Ai thich ban — anh mosaic server-side + chip tuoi/genre cho user free`

---

### Task 5 (chốt đợt): Final review + verify emulator

- [ ] **Step 1:** Final holistic review diff `3d5909f6..HEAD`: đối chiếu spec 4 mục; khẳng định composite `discovery_candidate` KHÔNG bị alter (T3 chỉ thêm RPC); share gate không dùng in_keo; teaser không lộ id/tên/URL gốc (grep response edge); 3 gates full.
- [ ] **Step 2:** Verify emulator (2 account, quy trình multiacc đợt trước — OTP 002 có thể đã rớt nếu supabase restart: kiểm tra rồi làm lại thủ tục config nếu cần):
  - T1: Minh thêm ảnh 4-6 qua PhotoManagerSheet (ảnh test adb push như session photos) → 6 ô đầy.
  - T2: từ kèo Minh là member → share → lấy token từ share text → mở `cunghat://keo/shared/<token>`... deep-link scheme native CHƯA đăng ký (operator gate P7) → verify bằng cách điều hướng thẳng route trong app (adb intent không được thì dùng widget-test đã cover + verify màn qua route nội bộ: tạm thêm nút debug? KHÔNG — verify qua 2 cách: (a) resolve RPC bằng psql khẳng định data; (b) mở màn shared bằng `adb shell am start` với scheme nếu manifest có, nếu không thì ghi ⚠️ manifest-gate vào doc và verify màn bằng widget test).
  - T3: Minh ↔ QA Linh match (tạo lại như multiacc) → chat → nút Hồ sơ → sheet → quote bài tủ → composer prefill → gửi → cleanup.
  - T4: QA Linh cần ảnh (service-role upload script pattern cũ) → Minh (free) mở tile 'Ai đã thích bạn' → màn teaser: card mosaic + chip; XÁC NHẬN network không có URL ảnh gốc (logcat/proxy đơn giản: kiểm tra URL trong UI là teaser.jpg). Nếu ImageScript fail → DỪNG báo user (rủi ro spec #1).
- [ ] **Step 3:** `docs/verify-p2-2026-07-XX.md` + screenshots + cleanup data (xoá swipes/match/messages sau VERIFY_START; GIỮ ảnh QA Linh + teaser.jpg). Commit + DỪNG báo user quyết merge.
