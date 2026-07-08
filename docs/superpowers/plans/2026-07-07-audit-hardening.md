# Audit Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 2 Critical + 9 Important từ audit toàn repo 2026-07-07 (5 gói: chat providers, PDPL/purge, trust-&-safety block/unmatch/roster, edge cũ, store/deep-link/CI).

**Architecture:** DB migrations mới nối sau `20260707220000` (mỗi migration recreate function copy VERBATIM từ bản mới nhất rồi chỉ thêm phần siết); Flutter sửa điểm; edge functions siết theo pattern fail-closed của batch payment. Spec: `docs/superpowers/specs/2026-07-07-audit-hardening-design.md` (findings tham chiếu [A/B/C/D-*]).

**Tech Stack:** Flutter 3.44/Riverpod 3.3 manual providers, Supabase (Postgres+PostGIS, pgTAP, Deno edge), Standard Webhooks HMAC, GitHub Actions.

---

## MÔI TRƯỜNG (đọc trước mọi task)

- Worktree `C:\Users\Hwang Ming Hung\cung-hat-photos-wt`, nhánh `fix/audit-hardening`. KHÔNG đụng root checkout.
- Flutter: `C:\Users\Public\flutter\bin\flutter.bat` (test/analyze). Supabase: `npx supabase migration up` (KHÔNG db reset); pgTAP `npx supabase test db` PHẢI 100%.
- psql: `docker exec supabase_db_cung-hat psql -U postgres -d postgres -c "..."`; SQL tiếng Việt qua STDIN + `-e PGCLIENTENCODING=UTF8` (hoặc dùng ASCII).
- Edge runtime: code reload = `docker restart supabase_edge_runtime_cung-hat`; **đổi `supabase/functions/.env` PHẢI `export SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN=localdummytoken && npx supabase stop && npx supabase start`** (docker restart KHÔNG nạp env).
- pgTAP: `throws_ok` arg 2 = SQLSTATE 5 ký tự ('23514'); mỗi file begin/plan(N)/finish/rollback; seed auth.users→profiles→(entitlements nếu cần pro/see_likes)→jwt claims→role authenticated (mẫu: `supabase/tests/keo_midpoint_test.sql`).
- SECURITY DEFINER: `set search_path=''`, PostGIS qualify `public.*`, revoke public/anon + grant authenticated (trừ khi ghi khác).
- **Recreate function = copy VERBATIM bản MỚI NHẤT** (grep tên hàm trong supabase/migrations, lấy file timestamp lớn nhất) rồi chỉ thêm dòng được chỉ định. KHÔNG viết lại từ trí nhớ.
- Flutter mock: `test/support/supabase_mocks.dart` (`rpcOk`), FunctionsClient mock `thenAnswer((_) async => FunctionResponse(...))`.
- Commit: subject ASCII, body kết thúc `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

---

### Task 1 (G4): autoDispose 4 chat/keo providers

**Files:**
- Modify: `lib/features/chat/application/chat_providers.dart`
- Test: Create `test/features/chat/chat_providers_autodispose_test.dart`

- [ ] **Step 1: Test fail**

```dart
// test/features/chat/chat_providers_autodispose_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/chat/application/chat_providers.dart';
import 'package:cung_hat/features/chat/data/chat_repository.dart';
import 'package:cung_hat/features/chat/domain/message.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  test('messageHistoryProvider autoDispose: rewatch sau khi bo listener -> fetch lai', () async {
    final repo = _MockChatRepository();
    when(() => repo.history('m1')).thenAnswer((_) async => <Message>[]);
    final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final sub1 = container.listen(messageHistoryProvider('m1'), (_, __) {});
    await container.read(messageHistoryProvider('m1').future);
    verify(() => repo.history('m1')).called(1);

    sub1.close();
    // autoDispose huy state sau khi het listener (cho microtask/frame chay xong).
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final sub2 = container.listen(messageHistoryProvider('m1'), (_, __) {});
    await container.read(messageHistoryProvider('m1').future);
    verify(() => repo.history('m1')).called(1); // lan 2 (mocktail dem tu lan verify truoc)
    sub2.close();
  });

  test('keoMessageHistoryProvider autoDispose: rewatch -> fetch lai', () async {
    final repo = _MockChatRepository();
    when(() => repo.keoHistory('k1')).thenAnswer((_) async => <Message>[]);
    final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final sub1 = container.listen(keoMessageHistoryProvider('k1'), (_, __) {});
    await container.read(keoMessageHistoryProvider('k1').future);
    sub1.close();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final sub2 = container.listen(keoMessageHistoryProvider('k1'), (_, __) {});
    await container.read(keoMessageHistoryProvider('k1').future);
    verify(() => repo.keoHistory('k1')).called(2);
    sub2.close();
  });
}
```

Ghi chú cho implementer: nếu autoDispose của Riverpod 3.3.2 cần tick khác (test flake), thay delay bằng `await null; await Future<void>.delayed(Duration.zero);` — thử nghiệm và chốt cách ổn định; KHÔNG đổi assertion.

- [ ] **Step 2: Chạy fail** — `flutter.bat test test/features/chat/chat_providers_autodispose_test.dart` → FAIL (called(1) ở rewatch vì keepAlive trả cache).

- [ ] **Step 3: Implement** — trong `chat_providers.dart` đổi cả 4 provider sang autoDispose (giữ nguyên body):

```dart
final messageHistoryProvider =
    FutureProvider.autoDispose.family<List<Message>, String>(
        (ref, threadId) => ref.watch(chatRepositoryProvider).history(threadId));

final liveMessagesProvider =
    StreamProvider.autoDispose.family<Message, String>((ref, threadId) {
  return ref.watch(chatRepositoryProvider).subscribe(threadId);
});

final keoMessageHistoryProvider =
    FutureProvider.autoDispose.family<List<Message>, String>(
        (ref, keoId) => ref.watch(chatRepositoryProvider).keoHistory(keoId));

final keoLiveMessagesProvider =
    StreamProvider.autoDispose.family<Message, String>((ref, keoId) {
  return ref.watch(chatRepositoryProvider).subscribeKeo(keoId);
});
```

- [ ] **Step 4: Gates** — `flutter.bat test && flutter.bat analyze` → 100% xanh (chat_screen/keo_chat tests hiện có phải vẫn pass — nếu test nào phụ thuộc keepAlive thì sửa TEST cho đúng hành vi mới, báo trong report).

- [ ] **Step 5: Commit** — `git add lib/features/chat/application/chat_providers.dart test/features/chat/chat_providers_autodispose_test.dart && git commit -m "fix(chat): autoDispose 4 provider chat/keo - het mat tin nhan khi mo lai + het leak channel"`

---

### Task 2 (G1): FK purge + guard notify_push + pgTAP purge-cascade

**Files:**
- Create: `supabase/migrations/20260708100000_purge_fk_notify_guard.sql`
- Test: Create `supabase/tests/purge_cascade_test.sql`

- [ ] **Step 1: pgTAP fail trước** — seed 2 user (P bị purge, K control) với dữ liệu ở MỌI bảng account-owned mới, chạy purge, assert cascade:

```sql
-- supabase/tests/purge_cascade_test.sql
-- Run with: supabase test db
-- Proves 20260708100000: purge_expired_accounts khong bi FK moderation_audit.actor chan;
-- cascade sach moi bang; audit row giu lai voi actor=null; control user con nguyen.
begin;
select plan(9);
set local role postgres;

insert into auth.users (id) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa02')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob, tombstone, soft_deleted_at) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01','Purge Me','1990-01-01', true, now() - interval '31 days'),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa02','Keep Me','1990-01-01', false, null)
  on conflict (id) do nothing;

-- Du lieu o cac bang account-owned (moi bang 1 dong cho P):
insert into public.user_locations (user_id, location) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01', ST_SetSRID(ST_MakePoint(105.85,21.02),4326)::geography);
insert into public.entitlements (user_id, feature, source) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01','pro','promo');
insert into public.purchases (user_id, product_id, platform, store_txn_id, receipt_ref, state)
  select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01', id, 'android', 'purge-txn-1', 'stored', 'validated'
  from public.products where platform='android' limit 1;
insert into public.venue_bookings (venue_id, user_id, amount_minor, gateway, gateway_ref, state)
  select id, 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01', booking_deposit_minor, 'momo', 'purge-ref-1', 'initiated'
  from public.venues limit 1;
insert into public.device_tokens (user_id, fcm_token, platform) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01','purge-fcm-1','android');
insert into public.moderation_audit (actor, action, target_type, target_id, reason) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01','dismiss','profile','someone','test');
-- boosts: DOC 20260704110000_boost.sql de lay dung cot (activate/expiry co default?) roi seed 1 dong cho P.
-- profile_prompts: DOC 20260706130000_profile_prompts.sql lay dung cot (user_id, prompt_key/answer...) roi seed 1 dong cho P.

-- 1) Truoc fix, FK actor se chan purge — sau migration nay purge phai chay tron:
select lives_ok($$ select app_private.purge_expired_accounts() $$, 'purge chay khong loi du co moderation_audit.actor');

-- 2) P bien khoi auth.users; 3) K con nguyen:
select is((select count(*)::int from auth.users where id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'P da bi hard-delete');
select is((select count(*)::int from auth.users where id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa02'), 1, 'K con nguyen');

-- 4-8) cascade sach tung bang:
select is((select count(*)::int from public.entitlements where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'entitlements sach');
select is((select count(*)::int from public.purchases where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'purchases sach');
select is((select count(*)::int from public.venue_bookings where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'venue_bookings sach');
select is((select count(*)::int from public.device_tokens where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'device_tokens sach');
-- 9) audit row GIU LAI, actor=null:
select is((select count(*)::int from public.moderation_audit where target_id='someone' and actor is null), 1, 'audit row giu, actor null');

select * from finish();
rollback;
```

Implementer: (a) hoàn thiện 2 dòng seed boosts + profile_prompts theo đúng schema thật (đọc 2 migration nêu trên — thêm 2 assertion sạch tương ứng nếu 2 bảng đó FK cascade tới auth.users/profiles, cập nhật plan(N)); (b) nếu venue_bookings.user_id là `on delete cascade` thì assertion đúng như trên, nếu là set-null thì đổi assertion thành `user_id is null` — ĐỌC 0020 xác nhận, ghi rõ trong report.

- [ ] **Step 2: Chạy fail** — `npx supabase test db` → purge_cascade FAIL ở assertion 1 (FK violation) — CHỨNG MINH bug A-C1 tồn tại thật trước khi fix.

- [ ] **Step 3: Migration**

```sql
-- supabase/migrations/20260708100000_purge_fk_notify_guard.sql
-- [A-C1] moderation_audit.actor NO-ACTION chan purge PDPL hang loat khi actor da bi xoa.
-- Giu audit row, mat danh tinh actor (set null) — chap nhan cho audit noi bo.
alter table public.moderation_audit alter column actor drop not null;
alter table public.moderation_audit
  drop constraint moderation_audit_actor_fkey;
alter table public.moderation_audit
  add constraint moderation_audit_actor_fkey
  foreign key (actor) references auth.users(id) on delete set null;

-- [A-M1] pg_net loi KHONG duoc abort insert message/join/plan (AFTER trigger).
-- Copy VERBATIM tu 0022_push_triggers.sql, chi boc http_post trong exception guard.
create or replace function app_private.notify_push(p_user_ids uuid[], p_event text, p_data jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare url text := current_setting('app.fanout_url', true);
        secret text := current_setting('app.fanout_secret', true);
begin
  if url is null or url = '' or p_user_ids is null or array_length(p_user_ids,1) is null then
    return;
  end if;
  begin
    perform net.http_post(
      url := url,
      headers := jsonb_build_object('Content-Type','application/json','x-fanout-secret', coalesce(secret,'')),
      body := jsonb_build_object('user_ids', to_jsonb(p_user_ids), 'title', p_event, 'body', p_event, 'data', p_data)
    );
  exception when others then
    null;  -- fire-and-forget: push loi khong duoc lam hong giao dich goc
  end;
end; $$;
```

(Xác nhận tên constraint thật bằng `\d public.moderation_audit` trước khi drop — nếu khác `moderation_audit_actor_fkey` thì dùng tên thật.)

- [ ] **Step 4: Apply + pass** — `npx supabase migration up && npx supabase test db` → 100% PASS.
- [ ] **Step 5: Commit** — `git add supabase/migrations/20260708100000_purge_fk_notify_guard.sql supabase/tests/purge_cascade_test.sql && git commit -m "fix(pdpl): purge het bi FK moderation_audit chan + guard notify_push"`

---

### Task 3 (G1): request_account_deletion bổ sung + export_my_data mở rộng

**Files:**
- Create: `supabase/migrations/20260708110000_pdpl_refresh.sql`
- Test: Create `supabase/tests/pdpl_refresh_test.sql`

- [ ] **Step 1: pgTAP fail** — test hành vi (đóng gap G2 audit: pdpl_test cũ chỉ check tồn tại):

```sql
-- supabase/tests/pdpl_refresh_test.sql
-- Proves 20260708110000: deletion xoa device_tokens/prompts + clear photo_paths;
-- export chua cac khoa moi (prompts/messages_sent/purchases/...).
begin;
select plan(7);
set local role postgres;
insert into auth.users (id) values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01') on conflict do nothing;
insert into public.profiles (id, display_name, dob, photo_paths) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01','Del Test','1990-01-01', array['x/1.jpg'])
  on conflict (id) do nothing;
insert into public.device_tokens (user_id, fcm_token, platform) values
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01','del-fcm','android');
-- seed 1 profile_prompts cho user nay (DOC schema 20260706130000 de dien dung cot).

set local request.jwt.claims to '{"sub":"bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01","role":"authenticated"}';
set local role authenticated;

-- 1-3) export co cac khoa moi:
select ok(public.export_my_data() ? 'prompts', 'export co prompts');
select ok(public.export_my_data() ? 'messages_sent', 'export co messages_sent');
select ok(public.export_my_data() ? 'purchases', 'export co purchases');

-- 4) deletion chay:
select lives_ok($$ select public.request_account_deletion() $$, 'deletion chay tron');

set local role postgres;
-- 5-7) device_tokens/prompts sach + photo_paths rong:
select is((select count(*)::int from public.device_tokens where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01'), 0, 'device_tokens da xoa');
select is((select count(*)::int from public.profile_prompts where user_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01'), 0, 'prompts da xoa');
select is((select photo_paths from public.profiles where id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbb01'), '{}'::text[], 'photo_paths da clear');

select * from finish();
rollback;
```

- [ ] **Step 2: Chạy fail** — export chưa có khoá mới → FAIL 1-3; deletion chưa xoá → FAIL 5-7.

- [ ] **Step 3: Migration** — recreate cả 2 hàm (copy body hiện tại từ `0019_pdpl.sql` rồi mở rộng):

```sql
-- supabase/migrations/20260708110000_pdpl_refresh.sql
-- [D] export_my_data lac hau sau P6/P7/post-v1 — bo sung du lieu nguoi dung so huu.
-- Dung to_jsonb(row) - '<id cols>' de khong phu thuoc chi tiet cot.
create or replace function public.export_my_data()
returns jsonb language sql security definer set search_path='' as $$
  select jsonb_build_object(
    'profile', (select to_jsonb(p) - 'report_risk' from public.profiles p where p.id = auth.uid()),
    'genres',  (select coalesce(jsonb_agg(genre_id), '[]'::jsonb) from public.user_genres where user_id = auth.uid()),
    'artists', (select coalesce(jsonb_agg(artist_id),'[]'::jsonb) from public.user_artists where user_id = auth.uid()),
    'baitu',   (select coalesce(jsonb_agg(song_id),  '[]'::jsonb) from public.user_baitu where user_id = auth.uid()),
    'consents',(select coalesce(jsonb_agg(to_jsonb(c)),'[]'::jsonb) from public.consents c where c.user_id = auth.uid()),
    'prompts', (select coalesce(jsonb_agg(to_jsonb(pp) - 'user_id'),'[]'::jsonb) from public.profile_prompts pp where pp.user_id = auth.uid()),
    'messages_sent', (select coalesce(jsonb_agg(to_jsonb(m) - 'sender_id'),'[]'::jsonb) from public.messages m where m.sender_id = auth.uid()),
    'swipes_made', (select coalesce(jsonb_agg(to_jsonb(s) - 'swiper_id'),'[]'::jsonb) from public.swipes s where s.swiper_id = auth.uid()),
    'matches', (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'status', m.status, 'created_at', m.created_at)),'[]'::jsonb)
                from public.matches m where m.user_a = auth.uid() or m.user_b = auth.uid()),
    'keo_hosted', (select coalesce(jsonb_agg(jsonb_build_object('id',k.id,'title',k.title,'status',k.status,'time_window_start',k.time_window_start)),'[]'::jsonb)
                   from public.keo k where k.host_id = auth.uid()),
    'keo_joined', (select coalesce(jsonb_agg(jsonb_build_object('keo_id',km.keo_id,'join_status',km.join_status,'confirmed',km.confirmed)),'[]'::jsonb)
                   from public.keo_members km where km.user_id = auth.uid()),
    'purchases', (select coalesce(jsonb_agg(to_jsonb(pu) - 'user_id'),'[]'::jsonb) from public.purchases pu where pu.user_id = auth.uid()),
    'entitlements', (select coalesce(jsonb_agg(to_jsonb(e) - 'user_id'),'[]'::jsonb) from public.entitlements e where e.user_id = auth.uid()),
    'venue_bookings', (select coalesce(jsonb_agg(to_jsonb(vb) - 'user_id'),'[]'::jsonb) from public.venue_bookings vb where vb.user_id = auth.uid()),
    'boosts', (select coalesce(jsonb_agg(to_jsonb(bo) - 'user_id'),'[]'::jsonb) from public.boosts bo where bo.user_id = auth.uid()),
    'checkins', (select coalesce(jsonb_agg(to_jsonb(ci) - 'user_id'),'[]'::jsonb) from public.checkins ci where ci.user_id = auth.uid()),
    'device_tokens', (select coalesce(jsonb_agg(to_jsonb(dt) - 'user_id'),'[]'::jsonb) from public.device_tokens dt where dt.user_id = auth.uid()),
    'blocks_made', (select coalesce(jsonb_agg(blocked_id),'[]'::jsonb) from public.blocks where blocker_id = auth.uid()),
    'share_links', (select coalesce(jsonb_agg(to_jsonb(sp) - 'created_by'),'[]'::jsonb) from public.share_plans sp where sp.created_by = auth.uid())
  );
$$;

-- [D] deletion bo sung: device_tokens (het push sau khi xoa), prompts, an anh ngay.
create or replace function public.request_account_deletion()
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.profiles
    set soft_deleted_at = now(), tombstone = true,
        display_name = 'Người dùng đã rời', full_name = null, bio = null,
        photo_paths = '{}'
    where id = auth.uid();
  delete from public.device_tokens where user_id = auth.uid();
  delete from public.profile_prompts where user_id = auth.uid();
  update public.keo set status='cancelled', soft_deleted_at=now() where host_id = auth.uid() and status <> 'done';
  update public.keo_members set join_status='left' where user_id = auth.uid();
  update public.matches set status='unmatched', unmatched_at=now() where user_a=auth.uid() or user_b=auth.uid();
  update public.messages set hidden = true where sender_id = auth.uid();
  update public.plans set status = 'cancelled'
    where status <> 'done'
      and keo_id in (select id from public.keo where host_id = auth.uid());
end; $$;
```

LƯU Ý migration có tiếng Việt có dấu ('Người dùng đã rời') → apply qua `npx supabase migration up` là an toàn (CLI đọc file UTF-8); TUYỆT ĐỐI không nạp tay qua PowerShell pipe. Kiểm tra cột khác tên: `share_plans.created_by` (đọc 0016 — nếu là `creator_id`/khác thì sửa); boosts/checkins cột user_id xác nhận từ migration gốc; keo cột `time_window_start` (đúng theo 0012). Nếu bảng `share_keos` tồn tại (20260707110000) thì thêm khoá `share_keo_links` tương tự — đọc migration đó để lấy cột creator.

- [ ] **Step 4: Apply + pass**: `npx supabase migration up && npx supabase test db` → 100%. Chạy thêm smoke tay: `docker exec ... psql -c "begin; set local request.jwt.claims to '{\"sub\":\"<uid Minh>\",\"role\":\"authenticated\"}'; set local role authenticated; select jsonb_object_keys(public.export_my_data()); rollback;"` → liệt kê đủ khoá.
- [ ] **Step 5: Commit** — `git commit -m "fix(pdpl): deletion thu hoi device_tokens/prompts/photos + export du bang moi"`

---

### Task 4 (G2): block cắt match + guard record_swipe + lọc who_liked_me

**Files:**
- Create: `supabase/migrations/20260708120000_block_sever.sql`
- Test: Create `supabase/tests/block_sever_test.sql`

- [ ] **Step 1: pgTAP fail**

```sql
-- supabase/tests/block_sever_test.sql
-- Proves 20260708120000: block unmatch cap dang active; record_swipe chan cap da block;
-- who_liked_me loc block 2 chieu.
begin;
select plan(6);
set local role postgres;
insert into auth.users (id) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc02'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03')
  on conflict do nothing;
insert into public.profiles (id, display_name, dob) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01','Blk A','1990-01-01'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc02','Blk B','1991-01-01'),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03','Blk C','1992-01-01')
  on conflict do nothing;
-- A & B match san:
insert into public.matches (user_a, user_b) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01','cccccccc-cccc-4ccc-8ccc-cccccccccc02');
-- C like A (cho who_liked_me):
insert into public.swipes (swiper_id, target_type, target_id, direction) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03','user','cccccccc-cccc-4ccc-8ccc-cccccccccc01','like');
-- A co see_likes + vi tri (who_liked_me can):
insert into public.entitlements (user_id, feature, source) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01','see_likes','promo');
insert into public.user_locations (user_id, location) values
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc01', ST_SetSRID(ST_MakePoint(105.85,21.02),4326)::geography),
  ('cccccccc-cccc-4ccc-8ccc-cccccccccc03', ST_SetSRID(ST_MakePoint(105.86,21.03),4326)::geography);

set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc01","role":"authenticated"}';
set local role authenticated;

-- 1) truoc block: who_liked_me co C:
select is((select count(*)::int from public.who_liked_me(20)), 1, 'truoc block: C hien trong who_liked_me');

-- 2) A block B -> match A-B unmatched:
select public.block_user('cccccccc-cccc-4ccc-8ccc-cccccccccc02');
select is(
  (select status from public.matches
    where user_a='cccccccc-cccc-4ccc-8ccc-cccccccccc01' and user_b='cccccccc-cccc-4ccc-8ccc-cccccccccc02'),
  'unmatched', 'block cat match dang active');

-- 3) A swipe B sau block -> blocked_pair:
select throws_ok(
  $$ select public.record_swipe('cccccccc-cccc-4ccc-8ccc-cccccccccc02', 'like') $$,
  '23514', 'blocked_pair', 'record_swipe chan cap da block');

-- 4) chieu nguoc: B swipe A cung bi chan:
set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc02","role":"authenticated"}';
select throws_ok(
  $$ select public.record_swipe('cccccccc-cccc-4ccc-8ccc-cccccccccc01', 'like') $$,
  '23514', 'blocked_pair', 'chieu nguoc cung bi chan');

-- 5) A block C -> who_liked_me khong con C:
set local request.jwt.claims to '{"sub":"cccccccc-cccc-4ccc-8ccc-cccccccccc01","role":"authenticated"}';
select public.block_user('cccccccc-cccc-4ccc-8ccc-cccccccccc03');
select is((select count(*)::int from public.who_liked_me(20)), 0, 'who_liked_me loc nguoi da block');

-- 6) block van idempotent (goi lai khong loi):
select lives_ok($$ select public.block_user('cccccccc-cccc-4ccc-8ccc-cccccccccc03') $$, 'block idempotent');

select * from finish();
rollback;
```

(Nếu `block_user` có rate-limit sẵn thì các lời gọi trong test vẫn dưới ngưỡng; nếu who_liked_me đòi thêm điều kiện — vd verified_badge — đọc bản mới nhất và seed thêm cho đủ, KHÔNG sửa assertion.)

- [ ] **Step 2: Chạy fail** — assertion 2/3/4/5 FAIL trên code hiện tại.

- [ ] **Step 3: Migration** — 3 recreate trong 1 file `20260708120000_block_sever.sql`:
1. `block_user`: copy body hiện tại (0007) + sau insert blocks thêm:
```sql
  update public.matches set status='unmatched', unmatched_at=now()
   where user_a = least(auth.uid(), p_blocked)
     and user_b = greatest(auth.uid(), p_blocked)
     and status = 'active';
```
2. `record_swipe`: copy VERBATIM toàn bộ body từ `20260703100000_doi_swipe_upgrade.sql` (bản mới nhất) + chèn NGAY SAU dòng `perform app_private.enforce_rate_limit('swipe', ...)`:
```sql
  if exists (select 1 from public.blocks b
             where (b.blocker_id = auth.uid() and b.blocked_id = p_target)
                or (b.blocker_id = p_target and b.blocked_id = auth.uid())) then
    raise exception 'blocked_pair' using errcode='check_violation';
  end if;
```
3. `who_liked_me`: copy VERBATIM từ `20260706130000_profile_prompts.sql` (bản mới nhất — GREP xác nhận không có bản mới hơn) + thêm vào WHERE:
```sql
      and not exists (select 1 from public.blocks b
             where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
```
Kèm revoke/grant lặp lại cho cả 3 hàm như bản gốc.

- [ ] **Step 4: Apply + pass** — `npx supabase migration up && npx supabase test db` → 100%.
- [ ] **Step 5: Commit** — `git commit -m "fix(safety): block cat match + chan swipe cap da block + loc who_liked_me"`

---

### Task 5 (G2): RPC unmatch + UI Huỷ ghép

**Files:**
- Create: `supabase/migrations/20260708130000_unmatch.sql`
- Test: Create `supabase/tests/unmatch_test.sql`
- Modify: `lib/features/chat/data/chat_repository.dart` (+unmatch)
- Modify: `lib/features/chat/presentation/chat_screen.dart` (menu)
- Modify: `test/features/chat/chat_repository_test.dart` hoặc file test repo chat hiện có (+1 test)

- [ ] **Step 1: pgTAP fail**

```sql
-- supabase/tests/unmatch_test.sql
begin;
select plan(4);
set local role postgres;
insert into auth.users (id) values
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd01'),('dddddddd-dddd-4ddd-8ddd-dddddddddd02'),('dddddddd-dddd-4ddd-8ddd-dddddddddd03')
  on conflict do nothing;
insert into public.profiles (id, display_name, dob) values
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd01','Um A','1990-01-01'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd02','Um B','1991-01-01'),
  ('dddddddd-dddd-4ddd-8ddd-dddddddddd03','Um C','1992-01-01')
  on conflict do nothing;
insert into public.matches (user_a, user_b)
  values ('dddddddd-dddd-4ddd-8ddd-dddddddddd01','dddddddd-dddd-4ddd-8ddd-dddddddddd02');
create temp table _um as
  select id from public.matches
  where user_a='dddddddd-dddd-4ddd-8ddd-dddddddddd01'
    and user_b='dddddddd-dddd-4ddd-8ddd-dddddddddd02';

select ok(exists(select 1 from pg_proc where proname='unmatch'), 'unmatch ton tai');

set local request.jwt.claims to '{"sub":"dddddddd-dddd-4ddd-8ddd-dddddddddd01","role":"authenticated"}';
set local role authenticated;
select public.unmatch((select id from _um));
select is((select status from public.matches where id=(select id from _um)), 'unmatched', 'thanh vien unmatch duoc');
select lives_ok($$ select public.unmatch((select id from _um)) $$, 'goi lai idempotent');

set local request.jwt.claims to '{"sub":"dddddddd-dddd-4ddd-8ddd-dddddddddd03","role":"authenticated"}';
select throws_ok($$ select public.unmatch((select id from _um)) $$, '23514', 'not_in_match', 'nguoi ngoai bi chan');

select * from finish();
rollback;
```
(CTE `insert ... returning` trong `insert into _um select` không hợp lệ ở Postgres — implementer thay bằng 2 bước: `insert into public.matches ... returning id` gán qua `\gset`? Trong pgTAP dùng: `insert into public.matches (user_a,user_b) values (...) ; insert into _um select id from public.matches where user_a='...01' and user_b='...02';` — dùng cách 2 bước này.)

- [ ] **Step 2: Migration**

```sql
-- supabase/migrations/20260708130000_unmatch.sql
-- [A-I1] Nguoi dung can duong cat ket noi khong can block/xoa tai khoan.
create or replace function public.unmatch(p_match uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not exists (select 1 from public.matches m
                 where m.id = p_match and (m.user_a = auth.uid() or m.user_b = auth.uid())) then
    raise exception 'not_in_match' using errcode='check_violation';
  end if;
  update public.matches set status='unmatched', unmatched_at=now()
   where id = p_match and status = 'active';  -- idempotent: da unmatched -> no-op
end; $$;
revoke execute on function public.unmatch(uuid) from public, anon;
grant execute on function public.unmatch(uuid) to authenticated;
```

- [ ] **Step 3: pgTAP pass** — `npx supabase migration up && npx supabase test db` → 100%.

- [ ] **Step 4: Flutter** — `ChatRepository` thêm:
```dart
Future<void> unmatch(String matchId) async {
  await _client.rpc('unmatch', params: {'p_match': matchId});
}
```
Repo test (pattern rpcOk, thêm vào file test chat repo hiện có — grep `ChatRepository(` trong test/): stub `client.rpc('unmatch', params: ...)` → `rpcOk(null)`, gọi, verify không throw.

`chat_screen.dart` AppBar actions: sau nút `chat_profile_btn` thêm:
```dart
PopupMenuButton<String>(
  key: const Key('chat_menu_btn'),
  onSelected: (v) async {
    if (v != 'unmatch') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ ghép?'),
        content: const Text('Hai bạn sẽ không nhắn tin được với nhau nữa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
          FilledButton(
            key: const Key('unmatch_confirm_btn'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ ghép'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(chatRepositoryProvider).unmatch(widget.matchId);
      if (mounted) {
        // ve inbox + lam moi danh sach match
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không huỷ ghép được, thử lại sau')));
      }
    }
  },
  itemBuilder: (_) => const [
    PopupMenuItem(value: 'unmatch', key: Key('unmatch_btn'), child: Text('Huỷ ghép')),
  ],
),
```
Điều chỉnh theo thực tế file: tên field matchId trong ChatScreen (đọc file — có thể là `widget.threadId`), mounted vs context.mounted (ChatScreen là StatefulWidget → dùng `mounted`), và sau `context.pop()` thêm invalidate provider inbox (grep provider mà InboxScreen watch — vd `myMatchesProvider` — `ref.invalidate(...)`).

- [ ] **Step 5: Gates + commit** — `flutter.bat test && flutter.bat analyze && npx supabase test db` xanh → `git commit -m "feat(safety): RPC unmatch + menu Huy ghep trong chat"`

---

### Task 6 (G2): gate get_keo_roster + midpoint doi >=2 vi tri

**Files:**
- Create: `supabase/migrations/20260708140000_roster_gate_midpoint2.sql`
- Test: Create `supabase/tests/roster_gate_test.sql`; Modify `supabase/tests/keo_midpoint_test.sql`

- [ ] **Step 1: pgTAP fail** — `roster_gate_test.sql`: seed keo (create_keo bởi host có pro — copy mẫu seed keo_midpoint_test), thêm 1 member `requested`, 1 member `approved`; asserts: (1) host thấy 3 hàng (host + approved + requested); (2) member approved gọi → 2 hàng (không thấy requested); (3) outsider gọi → 2 hàng (chỉ approved+host, không requested). plan(3). Với `keo_midpoint_test.sql`: chèn case mới SAU khi host có vị trí nhưng TRƯỚC khi member thứ 2 có vị trí: `select is((select count(*) from public.get_keo_midpoint(...)),0,'1 vi tri -> 0 dong')` — sắp xếp lại seed: host location trước, assert 0, rồi thêm 2 locations còn lại, giữ các assertion cũ; plan 5→6.

- [ ] **Step 2: Migration**

```sql
-- supabase/migrations/20260708140000_roster_gate_midpoint2.sql
-- [A-I3] requested rows chi host thay; nguoi khac chi thay approved (giu preview san pham).
create or replace function public.get_keo_roster(p_keo uuid)
returns setof public.keo_member_row language sql security definer set search_path='' as $$
  select m.user_id, p.display_name, p.age_verified, m.role, m.join_status
  from public.keo_members m
  join public.profiles p on p.id = m.user_id
  where m.keo_id = p_keo
    and (m.join_status = 'approved'
         or (m.join_status = 'requested'
             and exists (select 1 from public.keo k where k.id = p_keo and k.host_id = auth.uid())))
  order by case m.role when 'host' then 0 else 1 end, m.joined_at;
$$;

-- [A-M3] midpoint doi >= 2 thanh vien co vi tri (1 nguoi = lo vi tri ~110m cua chinh ho).
create or replace function public.get_keo_midpoint(p_keo uuid)
returns table (lat double precision, lng double precision)
language plpgsql security definer set search_path='' as $$
declare mid public.geometry;
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  select case when count(ul.user_id) >= 2
              then public.ST_GeometricMedian(public.ST_Collect(ul.location::public.geometry)) end
    into mid
  from public.keo_members m
  join public.user_locations ul on ul.user_id = m.user_id
  where m.keo_id = p_keo and m.join_status = 'approved' and m.confirmed;
  if mid is null then return; end if;
  return query select
    round(public.ST_Y(mid)::numeric, 3)::double precision,
    round(public.ST_X(mid)::numeric, 3)::double precision;
end; $$;
revoke execute on function public.get_keo_midpoint(uuid) from public, anon;
grant execute on function public.get_keo_midpoint(uuid) to authenticated;
```
(get_keo_roster: giữ revoke/grant như 0012 — thêm lại 2 dòng đó cho chữ ký này.)

- [ ] **Step 3: Apply + pass**; KIỂM TRA UI phụ thuộc: grep `get_keo_roster` phía Flutter — KeoDetailScreen nút duyệt dựa vào join_status 'requested' (host mới thấy → OK); chạy `flutter.bat test`.
- [ ] **Step 4: Commit** — `git commit -m "fix(safety): roster an requested voi nguoi ngoai host + midpoint doi >=2 vi tri"`

---

### Task 7 (G3): sign-photo — rate-limit + validate

**Files:**
- Create: `supabase/migrations/20260708150000_service_rate_limit.sql`
- Test: Create `supabase/tests/service_rate_limit_test.sql`
- Modify: `supabase/functions/sign-photo/index.ts`

- [ ] **Step 1: Migration + pgTAP** (fail-first bằng has-function):

```sql
-- supabase/migrations/20260708150000_service_rate_limit.sql
-- [B-1] Rate-limit goi tu edge (service role) cho user bat ky — chong scrape sign-photo.
-- KHONG cap cho authenticated (ho co the tu dot bucket cua minh/nguoi khac).
create or replace function public.consume_service_rate_limit(
  p_user uuid, p_bucket text, p_limit int, p_window interval)
returns boolean language plpgsql security definer set search_path='' as $$
declare w timestamptz := to_timestamp(
  floor(extract(epoch from now()) / extract(epoch from p_window)) * extract(epoch from p_window));
declare c int;
begin
  insert into public.rate_limits (user_id, bucket, window_start, count)
  values (p_user, p_bucket, w, 1)
  on conflict (user_id, bucket, window_start) do update set count = public.rate_limits.count + 1
  returning count into c;
  return c <= p_limit;
end; $$;
revoke execute on function public.consume_service_rate_limit(uuid,text,int,interval) from public, anon, authenticated;
grant execute on function public.consume_service_rate_limit(uuid,text,int,interval) to service_role;
```

```sql
-- supabase/tests/service_rate_limit_test.sql
begin;
select plan(4);
set local role postgres;
insert into auth.users (id) values ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01') on conflict do nothing;
select ok(exists(select 1 from pg_proc where proname='consume_service_rate_limit'), 'ham ton tai');
select is(public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day'), true, 'lan 1 ok');
select public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day');
select is(public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day'), false, 'vuot limit -> false');
set local role authenticated;
select throws_ok($$ select public.consume_service_rate_limit('eeeeeeee-eeee-4eee-8eee-eeeeeeeeee01','t',2,'1 day') $$,
  '42501', null, 'authenticated khong duoc goi');
select * from finish();
rollback;
```
(rate_limits.user_id có FK tới auth.users? — đọc 0007; nếu có thì seed user như trên là đủ.)

- [ ] **Step 2: sign-photo/index.ts** — 3 chỗ:
1. `const body = await req.json().catch(() => ({})); const target_id = body?.target_id;`
2. Sau đó: `if (typeof target_id !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(target_id)) return new Response(JSON.stringify({ urls: [] }), { status: 400, headers: { "Content-Type": "application/json" } });`
3. Trong nhánh `target_id !== user.id`, TRƯỚC block-check:
```ts
    // [B-1] chong scrape: toi da 300 luot sign nguoi khac / ngay / caller.
    const { data: allowed, error: rlErr } = await admin.rpc("consume_service_rate_limit", {
      p_user: user.id, p_bucket: "sign_photo", p_limit: 300, p_window: "1 day",
    });
    if (rlErr) { console.error("[sign-photo] rate limit rpc failed", rlErr); return new Response("retry later", { status: 500 }); }
    if (allowed !== true) return new Response(JSON.stringify({ error: "rate_limited" }), { status: 429, headers: { "Content-Type": "application/json" } });
```
- [ ] **Step 3: Gates + smoke** — `npx supabase migration up && npx supabase test db` 100%; `docker restart supabase_edge_runtime_cung-hat && sleep 3`; smoke: no-JWT → 401; real-JWT (OTP 900000001) + target_id chính mình → urls (không đốt bucket); + body rác → 400. `flutter.bat test` vẫn xanh (client không đổi).
- [ ] **Step 4: Commit** — `git commit -m "fix(photos): sign-photo chong scrape - rate limit 300/ngay + validate uuid + json catch"`

---

### Task 8 (G3): send-sms Standard Webhooks + fanout/ingest 503

**Files:**
- Modify: `supabase/functions/send-sms/index.ts` (viết lại)
- Modify: `supabase/functions/push-fanout/index.ts` (gate + log)
- Modify: `supabase/functions/ingest-places-venues/index.ts` (gate)
- Modify: `supabase/config.toml` (+[functions.send-sms])
- Modify: `supabase/functions/.env.example` (+SEND_SMS_HOOK_SECRET)
- Modify: `scripts/verify_payments_local.sh` (+3 checks)

- [ ] **Step 1: send-sms viết lại**

```ts
// supabase/functions/send-sms/index.ts
// GoTrue Send-SMS hook. XAC THUC = Standard Webhooks signature (GoTrue ky moi request)
// — verify_jwt=false trong config.toml vi GoTrue KHONG gui JWT; thieu chu ky/secret -> chan.
// KHONG BAO GIO log OTP/phone. Provider VN chua chon -> fail-closed 501 sau khi verify.
import { json } from "../_shared/hmac.ts";

function b64ToBytes(b64: string): Uint8Array {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}
async function hmacSha256B64(key: Uint8Array, msg: string): Promise<string> {
  const k = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(msg));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

Deno.serve(async (req) => {
  const secretEnv = Deno.env.get("SEND_SMS_HOOK_SECRET");
  if (!secretEnv) return json(503, { error: "sms_hook_not_configured" });

  const id = req.headers.get("webhook-id");
  const ts = req.headers.get("webhook-timestamp");
  const sigHeader = req.headers.get("webhook-signature");
  if (!id || !ts || !sigHeader) return new Response("missing signature headers", { status: 401 });
  const tsNum = Number(ts);
  if (!Number.isFinite(tsNum) || Math.abs(Date.now() / 1000 - tsNum) > 300) {
    return new Response("stale timestamp", { status: 401 }); // chong replay 5 phut
  }

  const raw = await req.text();
  const secretB64 = secretEnv.startsWith("v1,whsec_") ? secretEnv.slice(9)
    : secretEnv.startsWith("whsec_") ? secretEnv.slice(6) : secretEnv;
  let expected: string;
  try {
    expected = await hmacSha256B64(b64ToBytes(secretB64), `${id}.${ts}.${raw}`);
  } catch {
    return json(503, { error: "sms_hook_secret_invalid" });
  }
  const ok = sigHeader.split(" ").some((part) => {
    const [ver, sig] = part.split(",");
    return ver === "v1" && sig === expected;
  });
  if (!ok) return new Response("bad signature", { status: 401 });

  let parsed: { user?: { phone?: string }; sms?: { phone?: string; otp?: string } };
  try { parsed = JSON.parse(raw); } catch { return json(400, { error: "bad payload" }); }
  const phone = parsed.user?.phone ?? parsed.sms?.phone;
  const otp = parsed.sms?.otp;
  if (!phone || !otp) return json(400, { error: "missing phone/otp" });

  if (!Deno.env.get("SMS_API_KEY")) return json(503, { error: "sms_provider_not_configured" });
  // TODO(prod): goi provider SMS VN voi SMS_API_KEY. Toi khi chon provider: fail-closed.
  return json(501, { error: "sms_provider_not_implemented" });
});
```

- [ ] **Step 2: push-fanout + ingest gates** — đọc 2 file hiện tại; trong mỗi file, thay đoạn secret-gate đầu function:
```ts
  const secret = Deno.env.get("PUSH_FANOUT_SECRET"); // hoac PLACES_INGEST_SECRET
  if (!secret) return new Response(JSON.stringify({ error: "fanout_not_configured" }), { status: 503, headers: { "Content-Type": "application/json" } });
  if (req.headers.get("x-fanout-secret") !== secret) return new Response("forbidden", { status: 403 });
```
(ingest: header `x-ingest-secret`, error `ingest_not_configured`.) push-fanout: sửa dòng log bỏ `title`/`data` — chỉ log số lượng: `console.log(`[push-fanout] fanout to ${user_ids.length} devices`);` (đối chiếu biến thật trong file).

- [ ] **Step 3: config + env.example** — config.toml thêm:
```toml
[functions.send-sms]
verify_jwt = false
```
`.env.example` thêm dưới khối chung: `SEND_SMS_HOOK_SECRET=` với comment `# Standard Webhooks secret cua GoTrue send-sms hook (v1,whsec_...)`.

- [ ] **Step 4: Verify local (crypto thật, secret dummy)** — thêm secret dummy + restart stack ĐÚNG CÁCH:
```bash
grep -q "^SEND_SMS_HOOK_SECRET=" supabase/functions/.env || printf 'SEND_SMS_HOOK_SECRET=whsec_%s\n' "$(printf 'dummysmssecret0123456789abcdef' | base64)" >> supabase/functions/.env
export SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN=localdummytoken && npx supabase stop && npx supabase start
```
Rồi thêm vào `scripts/verify_payments_local.sh` 3 check (trước cleanup):
```bash
# send-sms: khong chu ky -> 401
check "send-sms unsigned -> 401" 401 "$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/send-sms" -H "Content-Type: application/json" -d '{}')"
# send-sms: tu ky dung thuat toan Standard Webhooks -> qua gate chu ky, toi 503/501 provider
SMS_SECRET_B64=$(grep '^SEND_SMS_HOOK_SECRET=' supabase/functions/.env | cut -d= -f2- | sed 's/^whsec_//')
WID="msg_$(date +%s)"; WTS=$(date +%s); WBODY='{"user":{"phone":"+84900000009"},"sms":{"otp":"000000"}}'
WSIG=$(printf '%s' "${WID}.${WTS}.${WBODY}" | openssl dgst -sha256 -hmac "$(printf '%s' "$SMS_SECRET_B64" | base64 -d)" -binary | base64)
CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/send-sms" -H "Content-Type: application/json" -H "webhook-id: $WID" -H "webhook-timestamp: $WTS" -H "webhook-signature: v1,$WSIG" -d "$WBODY")
check "send-sms signed -> 501 (provider gate, chu ky OK)" 501 "$CODE"
# push-fanout: PUSH_FANOUT_SECRET KHONG co trong .env local -> gate moi phai tra 503 (fail-closed)
check "push-fanout thieu env -> 503" 503 "$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/push-fanout" -H "Content-Type: application/json" -H "Authorization: Bearer $ANON" -d '{}')"
# (ANON = anon key da doc san trong script; push-fanout van verify_jwt=true nen can header nay de qua gateway.
#  Neu sau nay PUSH_FANOUT_SECRET duoc them vao .env local thi doi check nay thanh 403-sai-secret.)
```
LƯU Ý: openssl `-hmac` nhận key dạng chuỗi — key ở đây là BYTES sau base64-decode; dùng process substitution `-mac HMAC -macopt key:...`? Cách chắc chắn trên Git Bash: `openssl dgst -sha256 -mac HMAC -macopt hexkey:$(printf '%s' "$SMS_SECRET_B64" | base64 -d | xxd -p -c 256)` rồi `-binary | base64`. Implementer chọn biến thể chạy được, miễn thuật toán = HMAC-SHA256(bytes(secret), id.ts.body) → base64; PHẢI thấy 401 khi sửa 1 byte body (thêm 1 check tamper nếu tiện).
Chạy harness → PASS toàn bộ (cập nhật số PASS kỳ vọng trong header script nếu có).

- [ ] **Step 5: Commit** — `git commit -m "fix(auth): send-sms verify Standard Webhooks + bo log OTP; fanout/ingest 503 fail-closed"`

---

### Task 9 (G5): Store theo catalog

**Files:**
- Create: `supabase/migrations/20260708160000_store_products_v2.sql`
- Modify: `supabase/tests/store_products_rpc_test.sql`
- Modify: `lib/features/billing/data/billing_repository.dart`
- Modify: `lib/features/billing/application/billing_providers.dart` (+storeProductsProvider)
- Modify: `lib/features/billing/presentation/store_screen.dart` (tiles từ catalog, bỏ tile Pro trọn đời)
- Modify: `test/features/billing/billing_repository_test.dart`, `test/features/billing/store_screen_test.dart`

- [ ] **Step 1: Migration** (đổi return type → PHẢI drop trước):

```sql
-- supabase/migrations/20260708160000_store_products_v2.sql
-- [C-I3/D] catalog tra them sku + price_minor de UI het hardcode gia.
drop function if exists public.get_store_products(text);
create function public.get_store_products(p_platform text)
returns table (sku text, type text, store_product_id text, price_minor int)
language sql stable set search_path='' as $$
  select p.sku, p.type, p.store_product_id, p.price_minor
  from public.products p
  where p.platform = p_platform and p.is_active;
$$;
revoke execute on function public.get_store_products(text) from public, anon;
grant execute on function public.get_store_products(text) to authenticated;
```
pgTAP: cập nhật `store_products_rpc_test.sql` — thêm assertion `select ok((select bool_and(price_minor > 0) from public.get_store_products('android')), 'gia > 0');` (plan 3→4; giữ role authenticated wrap như hiện tại).

- [ ] **Step 2: Flutter test fail** — billing_repository_test thêm:
```dart
test('storeProducts tra list day du truong', () async {
  final client = MockSupabaseClient();
  when(() => client.rpc('get_store_products', params: any(named: 'params')))
      .thenAnswer((_) => rpcOk([
            {'sku': 'pro_android', 'type': 'pro', 'store_product_id': 'pro', 'price_minor': 199000},
          ]));
  final list = await BillingRepository(client).storeProducts('android');
  expect(list.single.priceMinor, 199000);
  expect(list.single.type, 'pro');
});
```

- [ ] **Step 3: Implement Flutter**
`billing_repository.dart`:
```dart
/// Mot dong catalog tu bang products.
class StoreProduct {
  const StoreProduct({required this.sku, required this.type,
      required this.storeProductId, required this.priceMinor});
  final String sku; final String type; final String storeProductId; final int priceMinor;
}

Future<List<StoreProduct>> storeProducts(String platform) async {
  final rows = await _client
      .rpc('get_store_products', params: {'p_platform': platform}) as List<dynamic>;
  return [
    for (final r in rows.cast<Map<String, dynamic>>())
      StoreProduct(
        sku: r['sku'] as String, type: r['type'] as String,
        storeProductId: r['store_product_id'] as String,
        priceMinor: (r['price_minor'] as num).toInt(),
      )
  ];
}

Future<Map<String, String>> storeProductIds(String platform) async {
  final list = await storeProducts(platform);
  return {for (final p in list) p.type: p.storeProductId};
}
```
`billing_providers.dart` thêm:
```dart
final storeProductsProvider = FutureProvider<List<StoreProduct>>((ref) async {
  final platform =
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  return ref.watch(billingRepositoryProvider).storeProducts(platform);
});
```
(import foundation cho defaultTargetPlatform.)
`store_screen.dart`: bỏ const `_upgrades` giá cứng; giữ map copy/icon theo type:
```dart
const _copy = <String, ({String title, String description, IconData icon, bool highlight})>{
  'pro': (title: 'Nâng cấp Pro', description: 'Tạo kèo, tham gia không giới hạn và mở mọi tính năng trả phí.', icon: Icons.workspace_premium_rounded, highlight: true),
  'boost': (title: 'Đẩy kèo lên top', description: 'Đưa kèo của bạn lên đầu bảng trong 24 giờ.', icon: Icons.local_fire_department_rounded, highlight: false),
  'see_likes': (title: 'Xem ai đã thích bạn', description: 'Mở khóa danh sách người đã thả tim bạn.', icon: Icons.favorite_rounded, highlight: false),
  'premium_filters': (title: 'Bộ lọc nâng cao', description: 'Lọc theo gu nhạc, độ tuổi, khu vực và trạng thái hoạt động.', icon: Icons.tune_rounded, highlight: false),
};
const _order = ['pro', 'boost', 'see_likes', 'premium_filters'];
String formatPriceK(int minor) => '${(minor / 1000).round()}k';
```
body: `ref.watch(storeProductsProvider).when(...)` — data: sort theo `_order` (indexOf, type lạ xuống cuối + dùng type làm title fallback), build tile như UI cũ (giữ key/nút mua gọi `buy(product.type)`); loading: `Center(CircularProgressIndicator())`; error: Text 'Không tải được cửa hàng' + nút Thử lại → `ref.invalidate(storeProductsProvider)`. (Đọc phần render tile hiện có và tái dùng widget/tile layout — chỉ đổi nguồn dữ liệu; "Pro trọn đời 699k" biến mất tự nhiên vì catalog chỉ có 1 dòng pro.)
`store_screen_test.dart`: cập nhật — override `storeProductsProvider` bằng 4 sản phẩm mock giá thật (199000/49000/99000/79000), assert thấy '199k' và KHÔNG thấy '99k'-Pro-cũ + không còn 'Pro trọn đời'; giữ các assertion cũ còn ý nghĩa.

- [ ] **Step 4: Gates** — `flutter.bat test && flutter.bat analyze && npx supabase test db` 100%.
- [ ] **Step 5: Commit** — `git commit -m "fix(billing): store lay gia tu catalog products + bo tile Pro tron doi trung SKU"`

---

### Task 10 (G5): Deep-link kèo chiều nhận

**Files:**
- Create: `lib/app/deep_link.dart`
- Modify: `lib/app/app.dart` (_handleUri dùng helper)
- Test: Create `test/app/deep_link_test.dart`

- [ ] **Step 1: Test fail**

```dart
// test/app/deep_link_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cung_hat/app/deep_link.dart';

void main() {
  test('plan link -> /plan/shared/<token>', () {
    expect(deepLinkLocation(Uri.parse('cunghat://plan/abc123')), '/plan/shared/abc123');
  });
  test('keo link -> /keo/shared/<token>', () {
    expect(deepLinkLocation(Uri.parse('cunghat://keo/shared/tok456')), '/keo/shared/tok456');
  });
  test('scheme la -> null', () {
    expect(deepLinkLocation(Uri.parse('https://plan/abc')), isNull);
  });
  test('keo thieu token -> null', () {
    expect(deepLinkLocation(Uri.parse('cunghat://keo/shared')), isNull);
  });
}
```

- [ ] **Step 2: Implement**

```dart
// lib/app/deep_link.dart
/// Dich cunghat:// URI sang route noi bo. Null = khong nhan dien duoc (bo qua).
String? deepLinkLocation(Uri uri) {
  if (uri.scheme != 'cunghat') return null;
  final segs = uri.pathSegments;
  if (uri.host == 'plan' && segs.isNotEmpty) return '/plan/shared/${segs.first}';
  if (uri.host == 'keo' && segs.length >= 2 && segs.first == 'shared') {
    return '/keo/shared/${segs[1]}';
  }
  return null;
}
```
`app.dart` `_handleUri`:
```dart
  void _handleUri(Uri uri) {
    try {
      final location = deepLinkLocation(uri);
      if (location != null) ref.read(goRouterProvider).go(location);
    } catch (_) {}
  }
```
(+import `deep_link.dart`; xoá comment route cũ.) KIỂM TRA route `/keo/shared/:token` có trong router + share URI generator ở keo_detail_screen dùng đúng shape `cunghat://keo/shared/<token>` — nếu generator khác shape thì sửa HELPER cho khớp generator (generator là chuẩn), báo trong report.

- [ ] **Step 3: Gates + commit** — full test + analyze xanh → `git commit -m "fix(keo): deep-link keo/shared nhan duoc - tach helper deepLinkLocation + test"`

---

### Task 11 (G5): CI thêm job pgTAP

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Thêm job** (giữ nguyên job flutter):

```yaml
  db:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with: { version: latest }
      - run: supabase db start
      - run: supabase test db
```

- [ ] **Step 2: Verify khả thi** — không chạy được local trên Windows; kiểm tra: YAML parse (`npx yaml-lint .github/workflows/ci.yml` hoặc python -c yaml.safe_load nếu có), tên action đúng `supabase/setup-cli@v1`, và ghi rõ trong report + verify doc: job sẽ được chứng thực ở lần push đầu (verify-on-push). LƯU Ý config.toml project này tắt analytics + có twilio env `SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN` — `supabase db start` KHÔNG khởi động auth nên không cần env đó; nếu CI đỏ vì config, ghi nhận và đề xuất fix ở PR sau (đừng đoán mò sửa).
- [ ] **Step 3: Commit** — `git commit -m "ci: them job supabase test db - pgTAP guard invariant chay tren CI"`

---

### Task 12: Final gates + verify doc + final review

- [ ] **Step 1: Full gates** — `flutter.bat test` (kỳ vọng ≥260) + `flutter.bat analyze` sạch + `npx supabase test db` (kỳ vọng Files=39±1, 100% PASS) + `bash scripts/verify_payments_local.sh` (PASS toàn bộ, gồm 2-3 check send-sms mới).
- [ ] **Step 2: Emulator spot-check** (cunghat_test3, build `--dart-define-from-file=env/dev.emulator.json`, gotcha JAVA_TOOL_OPTIONS): (a) chat mở lại thread thấy đủ tin (C-C1); (b) menu Huỷ ghép hoạt động → về inbox; (c) store hiện giá catalog (199k...) và không còn tile Pro trọn đời. Screenshot vào `docs/verify-screenshots-audit-hardening/`.
- [ ] **Step 3: Verify doc** — `docs/verify-audit-hardening-2026-07-08.md`: bảng findings→task→bằng chứng (pgTAP/harness/emulator); mục deferred mới (storage-bytes GC, lifetime SKU, CI verify-on-push, các Minor audit chưa fix).
- [ ] **Step 4: Commit + DỪNG** — commit doc; final holistic review (requesting-code-review, range 5065ae0d..HEAD) rồi báo user quyết merge. KHÔNG tự merge.
