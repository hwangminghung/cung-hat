begin;
select plan(13);

select ok(
  exists(select 1 from pg_type where typname = 'keo_match_suggestion'),
  'keo_match_suggestion type exists'
);

select is(
  (select count(*)::int
     from pg_attribute a
     join pg_class c on c.oid = a.attrelid
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'keo_match_suggestion'
      and a.attnum > 0
      and not a.attisdropped
      and a.attname in ('location','area_geo','lat','lng','score','raw_score')),
  0,
  'suggestion type exposes no coords or raw score'
);

select ok(
  exists(select 1 from pg_proc where proname = 'suggest_keo_match'),
  'suggest_keo_match RPC exists'
);

select ok(
  exists(select 1 from pg_proc where proname = 'create_auto_matched_keo'),
  'create_auto_matched_keo RPC exists'
);

set local role postgres;

update public.keo
set soft_deleted_at = now()
where soft_deleted_at is null;

delete from public.blocks
where blocker_id in (
    '00000000-0000-0000-0000-00000000aa01',
    '00000000-0000-0000-0000-00000000aa02',
    '00000000-0000-0000-0000-00000000aa03',
    '00000000-0000-0000-0000-00000000aa04'
  )
   or blocked_id in (
    '00000000-0000-0000-0000-00000000aa01',
    '00000000-0000-0000-0000-00000000aa02',
    '00000000-0000-0000-0000-00000000aa03',
    '00000000-0000-0000-0000-00000000aa04'
  );

insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000aa01'),
  ('00000000-0000-0000-0000-00000000aa02'),
  ('00000000-0000-0000-0000-00000000aa03'),
  ('00000000-0000-0000-0000-00000000aa04'),
  ('00000000-0000-0000-0000-00000000aa05'),
  ('00000000-0000-0000-0000-00000000aa06'),
  ('00000000-0000-0000-0000-00000000aa07')
on conflict (id) do nothing;

insert into public.profiles (id, display_name, dob, age_verified, verified_badge, report_risk) values
  ('00000000-0000-0000-0000-00000000aa01', 'Auto Caller', '1990-01-01', true, true, 0),
  ('00000000-0000-0000-0000-00000000aa02', 'Auto Host', '1990-01-01', true, true, 0),
  ('00000000-0000-0000-0000-00000000aa03', 'No Location Pro', '1990-01-01', true, true, 0),
  ('00000000-0000-0000-0000-00000000aa04', 'Free Caller', '1990-01-01', true, true, 0)
on conflict (id) do update
set age_verified = excluded.age_verified,
    verified_badge = excluded.verified_badge,
    report_risk = excluded.report_risk;

insert into public.entitlements (user_id, feature, source) values
  ('00000000-0000-0000-0000-00000000aa01', 'pro', 'promo'),
  ('00000000-0000-0000-0000-00000000aa02', 'pro', 'promo'),
  ('00000000-0000-0000-0000-00000000aa03', 'pro', 'promo')
on conflict do nothing;

insert into public.user_locations (user_id, location, area_label) values
  ('00000000-0000-0000-0000-00000000aa01', public.ST_SetSRID(public.ST_MakePoint(106.700, 10.776), 4326)::public.geography, 'Q1'),
  ('00000000-0000-0000-0000-00000000aa02', public.ST_SetSRID(public.ST_MakePoint(106.702, 10.778), 4326)::public.geography, 'Q1'),
  ('00000000-0000-0000-0000-00000000aa04', public.ST_SetSRID(public.ST_MakePoint(106.701, 10.777), 4326)::public.geography, 'Q1')
on conflict (user_id) do update
set location = excluded.location,
    area_label = excluded.area_label,
    updated_at = now();

insert into public.user_genres (user_id, genre_id) values
  ('00000000-0000-0000-0000-00000000aa01', 'vpop'),
  ('00000000-0000-0000-0000-00000000aa02', 'vpop')
on conflict do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa02"}';
set local role authenticated;

create temp table _tight_auto_keo (id uuid);
create temp table _roomy_auto_keo (id uuid);

insert into _tight_auto_keo
select public.create_keo(
  'Nearly full V-Pop toi nay',
  10.778,
  106.702,
  'Q1',
  (date_trunc('day', timezone('Asia/Bangkok', now())) + interval '1 day 20 hours') at time zone 'Asia/Bangkok',
  (date_trunc('day', timezone('Asia/Bangkok', now())) + interval '1 day 23 hours') at time zone 'Asia/Bangkok',
  5,
  null,
  null,
  array['vpop'],
  'open'
);

insert into _roomy_auto_keo
select public.create_keo(
  'Roomy V-Pop toi nay',
  10.778,
  106.702,
  'Q1',
  (date_trunc('day', timezone('Asia/Bangkok', now())) + interval '1 day 21 hours') at time zone 'Asia/Bangkok',
  (date_trunc('day', timezone('Asia/Bangkok', now())) + interval '2 days') at time zone 'Asia/Bangkok',
  5,
  null,
  null,
  array['vpop'],
  'open'
);

set local role postgres;

insert into public.keo_members(keo_id, user_id, role, join_status, confirmed) values
  ((select id from _tight_auto_keo), '00000000-0000-0000-0000-00000000aa05', 'member', 'approved', false),
  ((select id from _tight_auto_keo), '00000000-0000-0000-0000-00000000aa06', 'member', 'approved', false),
  ((select id from _tight_auto_keo), '00000000-0000-0000-0000-00000000aa07', 'member', 'approved', false);

set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa01"}';
set local role authenticated;

select is(
  (select suggestion_type from public.suggest_keo_match(1) limit 1),
  'existing_keo',
  'nearby shared-genre open keo is suggested first'
);

select ok(
  (select 'shared_genres' = any(reason_labels)
     from public.suggest_keo_match(1)
    limit 1),
  'music-fit reason is returned'
);

select is(
  (select title from public.suggest_keo_match(1) limit 1),
  'Roomy V-Pop toi nay',
  'roomier open keo ranks ahead via capacity score bonus'
);

set local role postgres;
insert into public.blocks (blocker_id, blocked_id) values
  ('00000000-0000-0000-0000-00000000aa01', '00000000-0000-0000-0000-00000000aa02')
on conflict do nothing;

set local role authenticated;

select is(
  (select suggestion_type from public.suggest_keo_match(1) limit 1),
  'new_keo_proposal',
  'blocked host is excluded and proposal fallback is returned'
);

set local role postgres;
select is(
  (select count(*)::int from public.keo where title = 'Kèo gợi ý tối nay'),
  0,
  'proposal fallback does not insert a keo row'
);

-- P1-5 (2026-07-16) DAO GATE: free khong con bi pro_required — gioi han moi
-- la 1 keo active dang host. Seed cho aa04 mot keo dang mo roi thu tao tiep.
insert into public.keo (id, host_id, title, area_geo, time_window_start, time_window_end, group_size_target, status)
values ('00000000-0000-0000-0000-00000000aaf0', '00000000-0000-0000-0000-00000000aa04',
        'Keo dang mo cua aa04', 'SRID=4326;POINT(105.8 21.0)'::public.geography,
        now() + interval '6 hours', now() + interval '8 hours', 4, 'open')
on conflict (id) do nothing;

set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa04"}';
set local role authenticated;

select throws_ok(
  $$ select public.create_auto_matched_keo(
    'Kèo gợi ý tối nay',
    now() + interval '1 day',
    now() + interval '1 day 3 hours',
    4,
    array['vpop'],
    'open'
  ) $$,
  '23514',
  'free_host_limit',
  'free dang host 1 keo active -> auto-match khong tao them duoc (P1-5)'
);

set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa03"}';
set local role authenticated;

select throws_ok(
  $$ select public.create_auto_matched_keo(
    'Kèo gợi ý tối nay',
    now() + interval '1 day',
    now() + interval '1 day 3 hours',
    4,
    array['vpop'],
    'open'
  ) $$,
  '23514',
  'location_required',
  'pro user without location cannot create auto-matched keo'
);

set local role postgres;
set local request.jwt.claims to '{"sub":"00000000-0000-0000-0000-00000000aa01"}';
set local role authenticated;

select throws_ok(
  $$ select public.create_auto_matched_keo(
    'Kèo gợi ý tối nay',
    now() + interval '1 day',
    now() + interval '1 day 3 hours',
    null::int,
    array['vpop'],
    'open'
  ) $$,
  '23514',
  'invalid_group_size',
  'null group size is rejected by auto-matched keo RPC'
);

create temp table _created_auto_keo (id uuid);
insert into _created_auto_keo
select public.create_auto_matched_keo(
  'Kèo gợi ý tối nay',
  now() + interval '2 days',
  now() + interval '2 days 3 hours',
  4,
  array['vpop'],
  'open'
);

set local role postgres;

select is(
  (select m.role || ':' || m.join_status || ':' || m.confirmed::text
     from _created_auto_keo c
     join public.keo_members m
       on m.keo_id = c.id
      and m.user_id = '00000000-0000-0000-0000-00000000aa01'),
  'host:approved:true',
  'pro user with location creates approved confirmed host membership'
);

select * from finish();
rollback;
