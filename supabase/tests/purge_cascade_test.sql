-- Run with: supabase test db
-- Proves 20260708100000: purge_expired_accounts khong bi FK moderation_audit chan;
-- cascade sach moi bang; audit row giu lai voi actor=null; control user con nguyen.
-- Kem guard pg_constraint: khong FK NO-ACTION/RESTRICT nao (ke ca bang tuong lai)
-- tro vao purge closure (auth.users/profiles/keo/plans) — chong re-wedge kieu A-C1.
begin;
select plan(13);
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
-- boosts (20260704110000_boost.sql): user_id pk references auth.users(id) on delete cascade.
insert into public.boosts (user_id, expires_at) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01', now() + interval '30 minutes');
-- profile_prompts (20260706130000_profile_prompts.sql): user_id references profiles(id)
-- on delete cascade (profiles.id itself cascades from auth.users, 0001_foundation.sql).
insert into public.profile_prompts (user_id, prompt_id, answer, position) values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01','p1','Purge test answer',0);

-- 1) Truoc fix, FK actor se chan purge — sau migration nay purge phai chay tron:
select lives_ok($$ select app_private.purge_expired_accounts() $$, 'purge chay khong loi du co moderation_audit.actor');

-- 2) P bien khoi auth.users; 3) K con nguyen:
select is((select count(*)::int from auth.users where id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'P da bi hard-delete');
select is((select count(*)::int from auth.users where id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa02'), 1, 'K con nguyen');

-- 4-11) cascade sach tung bang (tat ca FK user_id/actor deu on delete cascade -> 0 dong con lai):
select is((select count(*)::int from public.profiles where id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'profiles P da xoa (PDPL)');
select is((select count(*)::int from public.user_locations where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'user_locations sach');
select is((select count(*)::int from public.entitlements where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'entitlements sach');
select is((select count(*)::int from public.purchases where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'purchases sach');
select is((select count(*)::int from public.venue_bookings where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'venue_bookings sach (FK on delete cascade, xac nhan 0020_monetization.sql)');
select is((select count(*)::int from public.device_tokens where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'device_tokens sach');
select is((select count(*)::int from public.boosts where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'boosts sach');
select is((select count(*)::int from public.profile_prompts where user_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaa01'), 0, 'profile_prompts sach');
-- 12) audit row GIU LAI, actor=null:
select is((select count(*)::int from public.moderation_audit where target_id='someone' and actor is null), 1, 'audit row giu, actor null');

-- 13) Guard tuong lai: bat ky bang MOI nao them FK NO-ACTION/RESTRICT vao purge closure
-- se lam wedge purge_expired_accounts y het A-C1 — seed-based test o tren khong bat duoc
-- bang chua ai nho seed, nen chan ngay o pg_constraint (xac nhan 0 dong tren toan schema
-- truoc khi them assertion nay; confdeltype: a = NO ACTION, r = RESTRICT).
select is(
  (select count(*)::int from pg_constraint
   where contype='f'
     and confrelid in ('auth.users'::regclass, 'public.profiles'::regclass, 'public.keo'::regclass, 'public.plans'::regclass)
     and confdeltype in ('a','r')),
  0,
  'khong co FK NO-ACTION/RESTRICT vao purge closure (se lam wedge purge_expired_accounts)');

select * from finish();
rollback;
