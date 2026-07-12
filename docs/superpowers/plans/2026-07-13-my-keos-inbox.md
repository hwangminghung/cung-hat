# "Kèo của bạn" trong inbox (get_my_keos) Implementation Plan

> **For agentic workers:** Executed inline (executing-plans) — 1 feature nhỏ, context sẵn trong phiên. Gates: analyze 0 + full Flutter test + `npx supabase test db` 100%.

**Goal:** Vá lỗ hổng UX nặng nhất sau merge ui-retro: kèo đã join/đã rời trạng thái `open` biến mất khỏi mọi UI với cả host lẫn member. Thêm RPC `get_my_keos` + section "Kèo của bạn" đầu tab Chat (mockup 15).

**Architecture:** RPC `RETURNS TABLE` alias đúng JsonKey của model `Keo` hiện có (KHÔNG đổi model → không build_runner, tránh coupling composite `keo_card` vốn bị drop/recreate nhiều lần). UI render 2 section độc lập trong 1 ListView; section kèo đọc `myKeosProvider.value ?? []` — provider lỗi/loading → section ẩn, test cũ không stub vẫn pass (AsyncError nuốt bởi Riverpod).

**Tech Stack:** Flutter 3.44/Riverpod 3.3 manual providers; Supabase local; worktree `cung-hat-ui-retro-wt` (detached tại ca2c65c5 → tạo nhánh `feat/my-keos-inbox` từ master).

---

### Task 1: Migration + pgTAP

**Files:** Create `supabase/migrations/20260713150000_get_my_keos.sql`, `supabase/tests/my_keos_test.sql`.

- `get_my_keos()` returns table (id uuid, title text, area_label text, time_window_start timestamptz, time_window_end timestamptz, size_target int, slots_filled int, genres text[], host_name text, status text, join_mode text, is_mine boolean):
  - WHERE caller là host HOẶC có row keo_members join_status in ('approved','requested') (left/declined loại);
  - status in ('open','full','planning','confirmed') (done/cancelled loại);
  - `soft_deleted_at is null`; `time_window_end > now() - interval '7 days'` (grace — 'done' còn write-dead, kèo vừa hát xong vẫn vào được chat/plan, kèo cổ tự ẩn);
  - `is_mine := (k.host_id = auth.uid())` → UI chip "Chủ kèo";
  - order by time_window_start asc; security definer set search_path=''; revoke public/anon, grant authenticated. KHÔNG cần PostGIS/distance.
- pgTAP plan(6): host thấy kèo planning của mình + is_mine=t; member approved thấy + is_mine=f; requester thấy; outsider 0 rows; member 'left' 0 rows; kèo cancelled không hiện. Seed pattern copy keo_header_test.sql (create_keo cần pro host; đổi UUID sang ...d1-d4 tránh đụng).
- Áp migration vào DB local đang chạy (docker exec psql -f) + smoke JWT Minh.

### Task 2: Repository + provider + inbox UI

**Files:** Modify `lib/features/keo/data/keo_repository.dart` (thêm `myKeos()` như listOpenKeos), `lib/features/keo/application/keo_providers.dart` (`myKeosProvider = FutureProvider<List<Keo>>`), `lib/features/chat/presentation/inbox_screen.dart`.

- Inbox refactor: bỏ index-math ListView.builder → ListView(children) build từ 2 list. Thứ tự (mockup 15): `_InboxHeader` → section "Kèo của bạn" (nếu keos khác rỗng) → section "Tin nhắn đôi" (nếu matches khác rỗng).
- `_KeoInboxTile` (Key `my_keo_tile`): ô 64×64 viền ink nền `AppColors.tealTint`-tương-đương (dùng AppColors.teal nhạt sẵn có) icon `confirmation_number_outlined`; title kèo (titleLarge, ellipsis); subtitle `statusLabel · areaLabel` (open=Đang mở, full=Đủ người, planning=Đang lên kế hoạch, confirmed=Đã chốt); phải: Text chip `x/y` (slots_filled/size_target, viền ink) + StampChip lime "Chủ kèo" khi isMine. onTap → `context.push('/keo/$id?title=...')` rồi invalidate cả myKeosProvider + inboxProvider khi mounted. WaveDivider giữa các hàng như section đôi.
- Empty tổng: chỉ khi matches RỖNG **và** keos RỖNG mới EmptyState cũ. Error/loading của myKeosProvider KHÔNG chặn inbox (đọc `.value`).
- KHÔNG đụng Key('turn_pill') và logic turnLabel.

### Task 3: Widget tests + gates + verify emulator

**Files:** Modify `test/features/chat/inbox_screen_test.dart` (xem pattern override sẵn có), test mới: (a) có keo → thấy `_SectionLabel` "Kèo của bạn" + title kèo + chip x/y + tap đi route /keo/:id (dùng GoRouter test harness sẵn có của file nếu có, không thì chỉ assert tile render); (b) keos rỗng matches có → KHÔNG có label "Kèo của bạn"; (c) matches rỗng keos có → vẫn render section kèo, không EmptyState. 3 case turn-pill cũ + case "Tin nhắn đôi" pass nguyên.
- Gates: analyze 0, full Flutter test, `npx supabase test db` 100%.
- Emulator: build APK (nhớ JAVA_TOOL_OPTIONS workaround) cài máy B (QA Linh = HOST) → tab Chat thấy "Kèo của bạn" với "Kèo demo tối nay" + chip Chủ kèo → tap vào detail được. Máy A (Minh, member) cũng thấy. Screenshot + cập nhật verify doc + merge quyết định của user.

## Self-review
- Coverage: RPC lọc đúng membership/status/time ✓; UI 2 vai host/member ✓; degrade an toàn khi provider lỗi ✓; không đổi model/Key ✓.
- Type: cột RPC alias khớp JsonKey `Keo` (size_target, slots_filled, host_name, join_mode, is_mine, area_label, time_window_*) ✓ — không có distance_band, model nullable ✓.
- Bẫy: build_runner không chạy; test không hardcode TZ; UUID pgTAP không đụng file khác; tránh stretch-Row-trong-ListView.
