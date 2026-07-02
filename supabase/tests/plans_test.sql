begin;
select plan(4);
select ok(exists(select 1 from pg_proc where proname='confirm_keo_plan'), 'confirm_keo_plan exists');

set local role postgres;
insert into auth.users (id) values ('00000000-0000-0000-0000-0000000000d1')
  on conflict (id) do nothing;
insert into public.profiles (id, display_name, dob) values
  ('00000000-0000-0000-0000-0000000000d1', 'Plan Host', '1990-01-01')
  on conflict (id) do nothing;
insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-0000000000d1', 'pro', 'promo')
  on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-0000000000d1"}';
set local role authenticated;
create temp table _plan_keo (id uuid);
insert into _plan_keo
select public.create_keo(
  'Planable KEO', 10.776889, 106.700981, 'HCM',
  now() + interval '1 day',
  now() + interval '1 day 2 hours',
  4,
  null,
  null,
  array[]::text[],
  'approval'
);

set local role postgres;
select ok(
  app_private.in_keo((select id from _plan_keo)),
  'host is in a newly-created open keo for planning'
);

select ok(
  has_table_privilege('authenticated', 'public.plans', 'SELECT'),
  'authenticated can select plans through the Data API'
);

set local role authenticated;
select lives_ok(
  $$ select public.propose_keo_plan(
    (select id from _plan_keo),
    (select id from public.venues where name = 'Kingdom Karaoke'),
    now() + interval '1 day 1 hour'
  ) $$,
  'host can propose plan for a newly-created open keo'
);

select * from finish();
rollback;
