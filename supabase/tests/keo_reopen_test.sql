-- Run with: supabase test db
-- [MATCH-AUDIT] Kèo đầy chỗ mà có người rời thì trước đây kẹt 'full' VĨNH VIỄN:
-- không một RPC nào đưa status về 'open', kèo biến mất khỏi board dù còn chỗ.
-- Kèm bug approve_join: đánh dấu 'full' theo filled+1 mà không kiểm tra câu
-- update có match hàng nào — duyệt một request không tồn tại cũng khoá kèo.
begin;
select plan(7);

-- H = host, M = member, X = người ngoài (không có request nào).
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'),
  ('00000000-0000-0000-0000-0000000000e2'),
  ('00000000-0000-0000-0000-0000000000e3')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name) values
  ('00000000-0000-0000-0000-0000000000e1', 'Host'),
  ('00000000-0000-0000-0000-0000000000e2', 'Mem'),
  ('00000000-0000-0000-0000-0000000000e3', 'Ngoai')
  on conflict (id) do nothing;
-- Kèo size 2, host chiếm 1 chỗ; M đã xin vào (requested).
insert into public.keo (id, host_id, title, area_label, area_geo,
                        time_window_start, time_window_end, group_size_target,
                        intent_tag, vibe, join_mode)
values ('00000000-0000-0000-0000-0000000000f1',
        '00000000-0000-0000-0000-0000000000e1', 'Test keo', 'HN',
        public.ST_SetSRID(public.ST_MakePoint(105.8, 21.0), 4326)::public.geography,
        now() + interval '1 hour', now() + interval '4 hours', 2,
        'casual', 'chill', 'approval');
insert into public.keo_members (keo_id, user_id, role, join_status, confirmed) values
  ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000e1', 'host', 'approved', true),
  ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000e2', 'member', 'requested', false);
reset role;

-- 1) approve_join một người KHÔNG có request → phải raise, không khoá kèo.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
select throws_ok(
  $$ select public.approve_join('00000000-0000-0000-0000-0000000000f1',
                                '00000000-0000-0000-0000-0000000000e3') $$,
  '23514', null, 'duyệt request không tồn tại → raise no_such_request');
reset role;

set local role postgres;
select is(
  (select status from public.keo where id='00000000-0000-0000-0000-0000000000f1'),
  'open', 'kèo KHÔNG bị đánh dấu full oan sau lần duyệt hụt');
reset role;

-- 2) Duyệt M thật → đủ 2/2 → full.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
select lives_ok(
  $$ select public.approve_join('00000000-0000-0000-0000-0000000000f1',
                                '00000000-0000-0000-0000-0000000000e2') $$,
  'duyệt request thật thì sống');
reset role;

set local role postgres;
select is(
  (select status from public.keo where id='00000000-0000-0000-0000-0000000000f1'),
  'full', 'đủ chỗ → full (hành vi cũ giữ nguyên)');
reset role;

-- 3) M rời kèo → tụt 1/2 → PHẢI quay về open (trước đây kẹt full vĩnh viễn).
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
select lives_ok(
  $$ select public.leave_keo('00000000-0000-0000-0000-0000000000f1') $$,
  'thành viên rời kèo');
reset role;

set local role postgres;
select is(
  (select status from public.keo where id='00000000-0000-0000-0000-0000000000f1'),
  'open', 'REOPEN: full → open khi tụt dưới target');

-- 4) Kèo đã lên planning thì KHÔNG bị reopen kéo ngược. Dựng trực tiếp:
update public.keo set status='planning' where id='00000000-0000-0000-0000-0000000000f1';
select app_private.maybe_reopen_keo('00000000-0000-0000-0000-0000000000f1');
select is(
  (select status from public.keo where id='00000000-0000-0000-0000-0000000000f1'),
  'planning', 'reopen chỉ đụng kèo đang full, không kéo planning về open');
reset role;

select * from finish();
rollback;
