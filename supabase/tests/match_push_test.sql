-- Run with: supabase test db
-- [MATCH-AUDIT #3] Match mới phải có đường push (trigger trên public.matches).
-- notify_push tự no-op khi app.fanout_url chưa set (local/test) nên INSERT
-- trong test không bắn HTTP thật — chỉ cần chứng minh trigger có mặt và
-- INSERT sống khi trigger chạy.
begin;
select plan(3);

select ok(
  exists (select 1 from pg_trigger t
          where t.tgname = 'matches_push'
            and t.tgrelid = 'public.matches'::regclass
            and not t.tgisinternal),
  'trigger matches_push tồn tại trên public.matches');

select ok(
  exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
          where n.nspname = 'app_private' and p.proname = 'on_match_push'),
  'app_private.on_match_push tồn tại');

-- INSERT match chạy QUA trigger mà vẫn sống (notify_push no-op khi thiếu GUC).
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000d1'),
  ('00000000-0000-0000-0000-0000000000d2')
  on conflict (id) do nothing;
select lives_ok(
  $$ insert into public.matches (user_a, user_b) values
     ('00000000-0000-0000-0000-0000000000d1',
      '00000000-0000-0000-0000-0000000000d2') $$,
  'insert match sống khi trigger push chạy (fanout chưa cấu hình → no-op)');
reset role;

select * from finish();
rollback;
