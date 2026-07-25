-- Chot hanh vi migration 20260726100000_debt_batch:
-- is_admin_self / get_my_blocks / cancel_keo_plan / propose tu huy ban cu /
-- plan_conf_member_read.
begin;
select plan(22);

-- ── Seed 2 user ─────────────────────────────────────────────────────────────
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000e1'),
  ('00000000-0000-0000-0000-0000000000e2')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000e1', 'Debt Host', '1990-01-01'),
  ('00000000-0000-0000-0000-0000000000e2', 'Debt Member', '1992-02-02')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000e1', 'pro', 'promo')
  on conflict do nothing;

-- ── is_admin_self ───────────────────────────────────────────────────────────
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select ok(not public.is_admin_self(), 'user thuong: is_admin_self = false');

set local role postgres;
insert into public.admins (user_id) values ('00000000-0000-0000-0000-0000000000e1')
  on conflict do nothing;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select ok(public.is_admin_self(), 'sau khi vao bang admins: is_admin_self = true');
set local role postgres;
delete from public.admins where user_id = '00000000-0000-0000-0000-0000000000e1';

-- ── get_my_blocks + unblock qua RLS ─────────────────────────────────────────
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select lives_ok(
  $$ select public.block_user('00000000-0000-0000-0000-0000000000e2') $$,
  'e1 chan e2'
);
select results_eq(
  $$ select blocked_id, display_name from public.get_my_blocks() $$,
  $$ values ('00000000-0000-0000-0000-0000000000e2'::uuid, 'Debt Member'::text) $$,
  'get_my_blocks tra dung nguoi + ten (join profiles qua definer)'
);
-- Unblock = delete thang qua policy blocks_self (FOR ALL).
delete from public.blocks where blocked_id = '00000000-0000-0000-0000-0000000000e2';
select is_empty(
  $$ select * from public.get_my_blocks() $$,
  'sau khi xoa row blocks: danh sach da chan rong'
);
-- Don pair-lock unmatch cua block_user de e2 con join duoc keo cua e1 o duoi.
set local role postgres;
delete from public.matches
 where user_a = least('00000000-0000-0000-0000-0000000000e1'::uuid,
                      '00000000-0000-0000-0000-0000000000e2'::uuid)
   and user_b = greatest('00000000-0000-0000-0000-0000000000e1'::uuid,
                         '00000000-0000-0000-0000-0000000000e2'::uuid);

-- ── Propose tu huy ban cu + cancel flow ─────────────────────────────────────
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _debt_keo (id uuid);
insert into _debt_keo
select public.create_keo(
  'Debt KEO', 21.03, 105.795, 'HN',
  now() + interval '1 day', now() + interval '1 day 2 hours',
  4, null, null, array[]::text[], 'approval'
);

create temp table _debt_plan (id uuid);
insert into _debt_plan
select public.propose_keo_plan(
  (select id from _debt_keo),
  (select id from public.venues order by name limit 1),
  now() + interval '1 day 1 hour'
);

create temp table _debt_plan2 (id uuid);
insert into _debt_plan2
select public.propose_keo_plan(
  (select id from _debt_keo),
  (select id from public.venues order by name limit 1),
  now() + interval '1 day 90 minutes'
);
select is(
  (select status from public.plans where id = (select id from _debt_plan)),
  'cancelled',
  'propose ban moi -> ban de xuat cu tu chuyen cancelled (het mo coi)'
);
select is(
  (select status from public.plans where id = (select id from _debt_plan2)),
  'proposed',
  'ban moi van proposed'
);

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select throws_ok(
  $$ select public.cancel_keo_plan((select id from _debt_plan2)) $$,
  '23514', null, 'nguoi ngoai khong huy duoc plan'
);

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select lives_ok(
  $$ select public.cancel_keo_plan((select id from _debt_plan2)) $$,
  'host huy plan proposed'
);
select is(
  (select status from public.plans where id = (select id from _debt_plan2)),
  'cancelled',
  'plan sau khi huy = cancelled'
);
select throws_ok(
  $$ select public.cancel_keo_plan((select id from _debt_plan2)) $$,
  '23514', null, 'plan da cancelled khong huy lai duoc'
);

-- ── plan_conf_member_read + cancel plan confirmed -> keo ve planning ────────
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select lives_ok(
  $$ select public.request_join_keo((select id from _debt_keo)) $$,
  'e2 xin vao keo'
);
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select lives_ok(
  $$ select public.approve_join(
       (select id from _debt_keo), '00000000-0000-0000-0000-0000000000e2') $$,
  'host duyet e2'
);
select lives_ok(
  $$ select public.confirm_keo((select id from _debt_keo)) $$,
  'host confirm membership'
);
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select lives_ok(
  $$ select public.confirm_keo((select id from _debt_keo)) $$,
  'e2 confirm membership -> keo sang planning'
);

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
create temp table _debt_plan3 (id uuid);
insert into _debt_plan3
select public.propose_keo_plan(
  (select id from _debt_keo),
  (select id from public.venues order by name limit 1),
  now() + interval '1 day 1 hour'
);
select ok(
  (select id from _debt_plan3) is not null,
  'host propose duoc plan moi sau khi keo planning'
);
select lives_ok(
  $$ select public.confirm_keo_plan((select id from _debt_plan3)) $$,
  'host xac nhan plan'
);

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e2"}';
set local role authenticated;
select results_eq(
  $$ select user_id from public.plan_confirmations
      where plan_id = (select id from _debt_plan3)
        and user_id = '00000000-0000-0000-0000-0000000000e1' $$,
  $$ values ('00000000-0000-0000-0000-0000000000e1'::uuid) $$,
  'thanh vien doc duoc confirmation nguoi khac (plan_conf_member_read)'
);
select lives_ok(
  $$ select public.confirm_keo_plan((select id from _debt_plan3)) $$,
  'e2 xac nhan not -> du 2/2'
);

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000e1"}';
set local role authenticated;
select is(
  (select status from public.keo where id = (select id from _debt_keo)),
  'confirmed',
  'du nguoi xac nhan -> keo confirmed'
);
select lives_ok(
  $$ select public.cancel_keo_plan((select id from _debt_plan3)) $$,
  'host huy duoc plan da confirmed'
);
select is(
  (select status from public.keo where id = (select id from _debt_keo)),
  'planning',
  'huy plan confirmed -> keo quay ve planning de chot lai'
);

select * from finish();
rollback;
