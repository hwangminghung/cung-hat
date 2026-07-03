# Đôi Photos + Carousel + Boost (Pro perk) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ảnh hồ sơ tùy chọn (tối đa 3 ảnh, private bucket + signed URL) hiển thị dạng carousel trên card Đôi và detail sheet; Boost là quyền lợi Pro (1 lần/ngày, 30 phút, +điểm xếp hạng trong deck người khác); kèm 2 polish đã khoanh trong `docs/verify-doi-tinder-2026-07-04.md`.

**Architecture:** KẾ THỪA plan `docs/superpowers/plans/2026-06-20-cung-hat-p1_5-photos.md` (bucket private `profile-photos`, owner-only storage RLS, Edge Function `sign-photo` mint signed URL 60s có gating block/soft-delete) với các DELTA bắt buộc ghi ở từng task: (1) **nhiều ảnh** — `profiles.photo_paths text[]` (max 3) thay vì `photo_path text`; (2) **số migration** — file P1.5 ghi `0023` nhưng 0023 đã bị P7 dùng → dùng timestamped `20260704100000_photos.sql`; (3) carousel client gọi `sign-photo` theo `candidate.id` (server tự tra photo_paths của target) nên KHÔNG đụng composite `discovery_candidate`. Boost: bảng `boosts` + `activate_boost` (Pro-only, 1/ngày qua `enforce_rate_limit`) + một score term mới trong `get_discovery_candidates`. Tất cả gate server-authoritative.

**Tech Stack:** Supabase Storage + Edge Function (service-role), `image_picker`, Riverpod 3 manual providers, mocktail + `test/support/supabase_mocks.dart` (`rpcOk`), pgTAP (`throws_ok` SQLSTATE `'23514'`).

**Quy ước môi trường (bắt buộc đọc):** flutter trên PATH; build APK cần `$env:JAVA_TOOL_OPTIONS="-Djdk.net.unixdomain.tmpdir=C:\nonexistent\" + ("a"*120)`; psql qua `docker exec supabase_db_cung-hat psql -U postgres -d postgres`; **SQL tiếng Việt nạp qua `docker cp` + `psql -f`, cấm pipe PowerShell**; `supabase migration up` (không `db reset`); KHÔNG đụng `supabase/tests/chat_media_test.sql.pending`; commit kèm trailer `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

---

## File Structure

```
supabase/migrations/20260704100000_photos.sql        # MỚI — photo_paths + bucket + RLS + set_my_photo_paths
supabase/migrations/20260704110000_boost.sql         # MỚI — boosts + activate_boost + score term
supabase/functions/sign-photo/index.ts               # MỚI — theo P1.5 T2 + delta multi-path
supabase/tests/photos_test.sql                       # MỚI
supabase/tests/boost_test.sql                        # MỚI
lib/features/photos/data/photo_repository.dart       # MỚI — upload/remove/signedUrls
lib/features/photos/application/photo_providers.dart # MỚI
lib/features/photos/presentation/photo_manager_sheet.dart # MỚI — quản lý 3 ô ảnh (Hồ sơ)
lib/features/photos/presentation/photo_carousel.dart # MỚI — PageView + dots + monogram fallback
lib/features/discovery/presentation/candidate_card.dart   # SỬA — nền = PhotoCarousel khi có ảnh
lib/features/discovery/presentation/candidate_detail_sheet.dart # SỬA — carousel trên đầu sheet
lib/features/discovery/presentation/doi_deck_screen.dart  # SỬA — nút boost header + polish khôi phục card
lib/features/discovery/presentation/match_celebration.dart # SỬA — polish note-rain precompute
lib/features/billing/... (KHÔNG sửa — isProProvider dùng lại)
lib/app/home_shell.dart                               # SỬA — entry "Ảnh hồ sơ" trong tab Hồ sơ
```

---

### Task 1: Migration photos (multi-ảnh) + pgTAP

**Files:** Create `supabase/migrations/20260704100000_photos.sql`, `supabase/tests/photos_test.sql`

- [ ] **Step 1:** Mở plan P1.5 (`docs/superpowers/plans/2026-06-20-cung-hat-p1_5-photos.md`) Task 1, copy migration NHƯNG áp các delta sau (còn lại giữ nguyên bucket + 4 policy storage RLS y hệt):
  - Thay `alter table ... add column photo_path text;` bằng:
    ```sql
    alter table public.profiles add column if not exists photo_paths text[] not null default '{}';
    ```
  - Thay function setter bằng:
    ```sql
    create or replace function public.set_my_photo_paths(p_paths text[])
    returns void language plpgsql security definer set search_path='' as $$
    begin
      if coalesce(array_length(p_paths, 1), 0) > 3 then
        raise exception 'photo_limit' using errcode='check_violation';
      end if;
      -- Mọi path phải nằm trong folder của chính caller (khớp storage RLS).
      if exists (
        select 1 from unnest(p_paths) p
        where p not like auth.uid()::text || '/%'
      ) then
        raise exception 'photo_path_invalid' using errcode='check_violation';
      end if;
      update public.profiles set photo_paths = p_paths where id = auth.uid();
    end; $$;
    revoke execute on function public.set_my_photo_paths(text[]) from public, anon;
    grant execute on function public.set_my_photo_paths(text[]) to authenticated;
    ```
- [ ] **Step 2:** pgTAP `photos_test.sql` — plan(5), rollback: bucket private tồn tại; setter lưu 2 paths hợp lệ; >3 paths raise 23514; path không thuộc uid raise 23514; user khác không SELECT được object của mình (storage RLS — dùng pattern set claims như các test cũ; nếu khó assert trực tiếp trên storage.objects thì assert policy tồn tại qua pg_policies, ghi chú rõ).
- [ ] **Step 3:** `supabase migration up` → `supabase test db` (85 + 5 = 90, PASS).
- [ ] **Step 4:** Commit `feat(photos-db): photo_paths (max 3) + private bucket + RLS`.

### Task 2: Edge Function sign-photo (multi-path)

**Files:** Create `supabase/functions/sign-photo/index.ts`

- [ ] **Step 1:** Theo P1.5 Task 2 nguyên bản (JWT caller → service-role client, gating: caller!=target thì check target không soft-deleted + không có block 2 chiều) với delta: đọc `photo_paths` (array) của target, mint signed URL 60s cho TỪNG path, trả `{ urls: string[] }` (rỗng nếu không có ảnh). Không nhận path từ client — chỉ `target_id`.
- [ ] **Step 2:** Không deploy được local runtime? `supabase functions serve sign-photo --env-file supabase/functions/.env` smoke bằng curl với JWT test user (GoTrue REST phone 84900000001/123456 lấy access_token). Nếu serve không chạy được trong môi trường máy này, ghi DONE_WITH_CONCERNS nêu rõ — client code Task 3 vẫn mock được.
- [ ] **Step 3:** Commit `feat(photos): edge function sign-photo tra danh sach signed url`.

### Task 3: PhotoRepository + providers + tests

**Files:** Create `lib/features/photos/data/photo_repository.dart`, `lib/features/photos/application/photo_providers.dart`, `test/features/photos/photo_repository_test.dart`

- [ ] **Step 1 (test fail trước):** repo test mock theo pattern `supabase_mocks.dart`:
  - `uploadPhoto(bytes, {required int slot})` → upload lên `profile-photos` path `'{uid}/{slot}_{millis}.jpg'` (mock `client.storage.from(...).uploadBinary`), rồi gọi `set_my_photo_paths` với list mới.
  - `removePhoto(path)` → storage remove + setter với list đã bỏ path.
  - `signedUrlsOf(userId)` → `client.functions.invoke('sign-photo', body: {'target_id': userId})` trả `List<String>`.
  (Kiểm tra API mock storage/functions trong mocktail — nếu mock storage builder chain quá phức tạp, tách phần chain vào interface nhỏ `PhotoStorage` inject được, test qua interface; ghi rõ trong report.)
- [ ] **Step 2:** Implement + providers: `photoRepositoryProvider`, `myPhotoPathsProvider` (từ `myProfileProvider` — cần thêm `photoPaths` vào model `Profile` + build_runner? **Profile là freezed** → thêm field `@JsonKey(name: 'photo_paths') @Default([]) List<String> photoPaths` và CHẠY build_runner CHỈ cho lần này: `dart run build_runner build --delete-conflicting-outputs`, commit cả file sinh); `signedUrlsProvider = FutureProvider.family<List<String>, String>` cache theo userId.
- [ ] **Step 3:** `get_my_profile`/`upsert_my_profile` RPC có trả `photo_paths` không? Kiểm tra migration 0002/0004 — nếu composite/`to_jsonb` trả cả row thì tự có; nếu liệt kê cột thì thêm `photo_paths` vào SELECT qua migration photos (Task 1 — quay lại bổ sung nếu phát hiện thiếu, ghi rõ trong report).
- [ ] **Step 4:** Full test + analyze + commit `feat(photos): repository + providers`.

### Task 4: UI quản lý ảnh (Hồ sơ) — consent-gated

**Files:** Create `lib/features/photos/presentation/photo_manager_sheet.dart`; Modify `lib/app/home_shell.dart` (thêm `_ProfileTile` "Ảnh hồ sơ" mở sheet); Test widget cơ bản.

- [ ] **Step 1:** Sheet 3 ô vuông (ảnh hoặc dấu +): tap + → `image_picker` gallery → upload qua repo (spinner per-slot) → refresh; tap ảnh → xoá (confirm dialog). **Consent gate:** đọc consent `photos` (pattern `myConsents()` của settings — xem `settings_screen.dart`); chưa granted → thay grid bằng thông báo + nút "Bật trong Cài đặt" (`context.push('/settings')`).
- [ ] **Step 2:** Widget test: consent chưa granted hiện CTA cài đặt; granted hiện 3 slot (mock providers).
- [ ] **Step 3:** Full test + analyze + commit `feat(photos): quan ly anh ho so (consent-gated)`.

### Task 5: PhotoCarousel + gắn vào card & detail sheet

**Files:** Create `lib/features/photos/presentation/photo_carousel.dart` + test; Modify `candidate_card.dart`, `candidate_detail_sheet.dart`

- [ ] **Step 1 (test fail trước):** `PhotoCarousel({required String userId, required String monogram, BorderRadius? radius})` — watch `signedUrlsProvider(userId)`: loading → giữ nền gradient monogram (KHÔNG spinner); rỗng/lỗi → gradient monogram như hiện tại; có N ảnh → `PageView` N trang `Image.network` (`fit: cover`, `errorBuilder` → gradient) + hàng dots (dot active đậm). Test: 0 ảnh → monogram; 2 ảnh (mock provider) → PageView 2 trang + 2 dots.
- [ ] **Step 2:** `candidate_card.dart`: phần `Expanded > Stack` — thay `DecoratedBox(gradient)` + `Center(monogram)` bằng `PhotoCarousel(userId: candidate.id, monogram: ...)` (giữ nguyên badge Online, nút báo cáo, các blob trang trí đè lên carousel bỏ đi nếu che ảnh — chỉ giữ khi không có ảnh, tức chuyển blob vào fallback của carousel). LƯU Ý: card nằm trong CardSwiper — PageView ngang sẽ tranh gesture với swipe ngang → đặt `physics: NeverScrollableScrollPhysics()` cho PageView trên CARD (chuyển ảnh bằng TAP nửa trái/phải như Tinder — GestureDetector onTapUp chia đôi bề ngang; nhớ card đã có onTap mở detail → trên card KHÔNG tap chuyển ảnh, chỉ hiển thị ảnh đầu + dots; carousel vuốt được đầy đủ đặt ở DETAIL SHEET). Chốt: card = ảnh đầu tiên tĩnh + dots; sheet = PageView vuốt được.
- [ ] **Step 3:** `candidate_detail_sheet.dart`: trên cùng sheet thêm `SizedBox(height: 280, child: PhotoCarousel(...))` bo góc; giữ layout còn lại.
- [ ] **Step 4:** Full test + analyze + commit `feat(doi): anh ho so tren card + carousel trong detail sheet`.

### Task 6: Migration boost + pgTAP

**Files:** Create `supabase/migrations/20260704110000_boost.sql`, `supabase/tests/boost_test.sql`

- [ ] **Step 1:** Migration:
  ```sql
  create table public.boosts (
    user_id uuid primary key references auth.users(id) on delete cascade,
    expires_at timestamptz not null
  );
  alter table public.boosts enable row level security;
  create policy boosts_read_self on public.boosts for select using (auth.uid() = user_id);
  -- ghi chỉ qua RPC (không policy write)

  create or replace function public.activate_boost()
  returns timestamptz language plpgsql security definer set search_path='' as $$
  declare new_expiry timestamptz;
  begin
    if not app_private.is_pro() then
      raise exception 'pro_required' using errcode='check_violation';
    end if;
    if exists (select 1 from public.boosts b where b.user_id = auth.uid() and b.expires_at > now()) then
      raise exception 'boost_active' using errcode='check_violation';
    end if;
    begin
      perform app_private.enforce_rate_limit('daily_boost', 1, interval '1 day');
    exception when sqlstate '23514' then
      raise exception 'boost_limit' using errcode='check_violation';
    end;
    new_expiry := now() + interval '30 minutes';
    insert into public.boosts (user_id, expires_at) values (auth.uid(), new_expiry)
    on conflict (user_id) do update set expires_at = excluded.expires_at;
    return new_expiry;
  end; $$;
  revoke execute on function public.activate_boost() from public, anon;
  grant execute on function public.activate_boost() to authenticated;
  ```
  Sau đó copy NGUYÊN VĂN `get_discovery_candidates` từ trạng thái MỚI NHẤT (file `20260703100000_doi_swipe_upgrade.sql` — bản đã có term super-liker) và chèn đúng MỘT term điểm nữa cạnh các `+ case` khác:
  ```sql
  + case when exists (
      select 1 from public.boosts b
      where b.user_id = c.id and b.expires_at > now()
    ) then 3.0 else 0 end
  ```
  (alias `c` = alias thực tế trong file nguồn.)
- [ ] **Step 2:** pgTAP plan(5): free activate → 23514 pro_required; Pro activate → trả timestamptz ~now+30'; boost đang active activate lần nữa → 23514 boost_active; seed `daily_boost` count=1 + xoá row boosts → activate → 23514 boost_limit; candidate đang boost được xếp trên candidate không boost (2 seed candidates cùng khoảng cách, một người boost — gọi get_discovery_candidates bằng caller thứ 3, assert thứ tự).
- [ ] **Step 3:** `supabase migration up` + `supabase test db` (90 + 5 = 95 PASS) + commit `feat(boost-db): boost 30 phut quyen loi Pro 1/ngay + uu tien xep hang`.

### Task 7: Boost UI

**Files:** Modify `lib/features/discovery/data/discovery_repository.dart` (+`activateBoost()` → `Future<DateTime>`), `lib/features/discovery/application/discovery_providers.dart` (`activeBoostProvider` StateProvider<DateTime?>), `doi_deck_screen.dart`; Test repo + widget.

- [ ] **Step 1 (test fail):** repo test `activateBoost` mock rpc trả ISO string → DateTime.
- [ ] **Step 2:** Header deck (Row tiêu đề) thêm `IconButton.filledTonal` icon `Icons.bolt_rounded` key `deck_boost_btn` TRƯỚC nút refresh: đang boost (activeBoostProvider còn hạn) → icon màu primary + tooltip 'Đang boost đến HH:mm'; free tap → `ProUpsellSheet.show(title: 'Boost hồ sơ của bạn', subtitle: 'Pro được 1 lần Boost 30 phút mỗi ngày — lên đầu deck quanh đây.')`; Pro tap → gọi repo, thành công → set provider + SnackBar 'Đang boost 30 phút — hồ sơ của bạn được ưu tiên quanh đây.'; lỗi map qua `discoverySwipeError`-style: thêm case `boostActive`/`boostLimit` vào `discovery_errors.dart` (message VI rõ ràng) — mapper mở rộng, KHÔNG tạo file lỗi mới.
- [ ] **Step 3:** Widget test: free tap → ProUpsellSheet; Pro tap (mock activateBoost hang rồi resolve) → SnackBar + không double-call khi double-tap (guard `_boostInFlight` giống `_rewindInFlight`).
- [ ] **Step 4:** Full test + analyze + commit `feat(doi): nut boost tren header deck`.

### Task 8: 2 polish từ verify log

**Files:** Modify `doi_deck_screen.dart`, `match_celebration.dart`; tests tương ứng.

- [ ] **Step 1 (khôi phục card khi server từ chối):** trong catch của `_handleSwipe`, với `likeLimit` và `superLimit` (server CHẮC CHẮN không ghi): sau khi hiện sheet/snack, gọi `_controller.undo()` nếu `mounted` để card quay lại deck (kèm comment: chỉ với 2 mã này vì biết chắc swipe không được ghi; unknown có thể đã ghi — không undo). Widget test: like bị like_limit → card vẫn còn trong deck (finder CandidateCard của candidate đó sau pumpAndSettle) — mutation-check bỏ undo → test đỏ.
- [ ] **Step 2 (note rain precompute):** trong `match_celebration.dart`, chuyển 18 `TextPainter` thành `static final List<(Offset01, double size, double alpha, TextPainter)>` layout MỘT lần (TextPainter.layout trong initializer); `paint` chỉ tính y theo progress và `tp.paint`. Giữ seed cố định. Test hiện có phải vẫn xanh; không cần test mới (thuần perf, hành vi giữ nguyên).
- [ ] **Step 3:** Full test + analyze + commit `perf(doi): khoi phuc card khi swipe bi tu choi + note rain tinh mot lan`.

### Task 9: Verify trên emulator (checkpoint bắt buộc)

- [ ] **Step 1:** Build + cài (workaround JAVA_TOOL_OPTIONS + `env/dev.emulator.json`); Supabase local chạy; emulator `cunghat_test` (boot bằng `C:\Users\Public\AndroidSDK\emulator\emulator.exe -avd cunghat_test -no-snapshot -no-audio -no-boot-anim -gpu swiftshader_indirect` nếu chưa chạy; screencap qua Bash tool).
- [ ] **Step 2 (ảnh test không cần image_picker):** script hoá upload cho seed host a2: lấy JWT test user qua GoTrue REST? KHÔNG — a2 là seed không login được; thay vào đó upload bằng service_role qua storage REST (key trong `supabase status`) 2 ảnh JPG bất kỳ (tự tạo bằng PowerShell System.Drawing 600x800 màu khác nhau) vào `a0000000-.../1.jpg, 2.jpg` + `update profiles set photo_paths='{...}' where id='a2...'` qua psql. User test ở SG (sửa user_locations như verify trước nếu GPS ghi đè).
- [ ] **Step 3:** Chụp: card Đôi hiện ẢNH thật + dots thay monogram; tap card → sheet carousel vuốt được sang ảnh 2; tab Hồ sơ → Ảnh hồ sơ (consent photos chưa granted → CTA cài đặt; grant qua Settings toggle rồi quay lại → 3 slot); nút boost: free → upsell; cấp pro (INSERT entitlements source='promo') → restart → boost → SnackBar + `select * from boosts` có row; polish: seed quota like → tap tim → paywall VÀ card quay lại deck (khác verify trước!).
- [ ] **Step 4:** Cleanup (thu pro promo, xoá rate_limits seed, giữ ảnh a2), full `flutter test` + `supabase test db`, viết `docs/verify-doi-photos-boost-<date>.md`, commit.

---

## Self-Review

- **Coverage:** photos multi + carousel (T1–T5), boost Pro perk đúng lựa chọn user (T6–T7), 2 polish (T8), verify (T9). Consent `photos` được tôn trọng (T4) — đúng PDPL đã build ở P0.3/P5.
- **Placeholder scan:** T2/T3 có nhánh "nếu môi trường không cho phép" với chỉ dẫn báo cáo rõ — chấp nhận được vì phụ thuộc máy; code chính đầy đủ hoặc trỏ delta chính xác vào P1.5 (file tồn tại trong repo).
- **Type consistency:** `set_my_photo_paths(text[])` (T1) = repo setter (T3); `signedUrlsProvider` family String (T3) = PhotoCarousel (T5); `activate_boost()` returns timestamptz (T6) = `activateBoost() Future<DateTime>` (T7); error codes `photo_limit/photo_path_invalid/boost_active/boost_limit/pro_required` nhất quán DB↔mapper.
