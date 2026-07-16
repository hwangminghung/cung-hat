-- P1-4: 2 push chu dong (UX research backlog).
--   1) "Keo toi nay": nhac moi member approved cua keo bat dau trong 8h toi
--      (cron 17:00 VN hang ngay) — keo cancelled/da xoa mem khong tinh.
--   2) "N nguoi hat moi hop gu": user active 14 ngay co >= p_min profile MOI
--      (7 ngay) quanh 50km chung >=1 the loai (cron 12:00 VN thu Hai).
-- Deu di qua app_private.notify_push (0022) nen local/test (GUC unset) la
-- no-op HTTP — an toan chay trong pgTAP.

-- Phan tinh recipients tach rieng thanh ham THUAN QUERY de pgTAP test duoc
-- ma khong dung den pg_net.
create or replace function app_private.keo_tonight_recipients()
returns table(keo_id uuid, user_ids uuid[])
language sql security definer set search_path='' as $$
  select k.id, array_agg(km.user_id)
  from public.keo k
  join public.keo_members km
    on km.keo_id = k.id and km.join_status = 'approved'
  where k.soft_deleted_at is null
    and k.status in ('open','full','planning','confirmed')
    and k.time_window_start >= now()
    and k.time_window_start < now() + interval '8 hours'
  group by k.id;
$$;

create or replace function app_private.notify_keo_tonight()
returns integer language plpgsql security definer set search_path='' as $$
declare r record; n integer := 0;
begin
  for r in select * from app_private.keo_tonight_recipients() loop
    perform app_private.notify_push(
      r.user_ids, 'keo_tonight', jsonb_build_object('keo_id', r.keo_id));
    n := n + 1;
  end loop;
  return n;
end; $$;

-- Dem nguoi hat MOI hop gu quanh tung user active — thuan query, pgTAP-test
-- duoc. Gioi han active 14 ngay + co vi tri de query khong quet ca bang.
create or replace function app_private.new_singers_counts(
  p_days integer default 7, p_min integer default 3)
returns table(user_id uuid, cnt integer)
language sql security definer set search_path='' as $$
  select me.id as user_id, count(*)::int as cnt
  from public.profiles me
  join public.user_locations myloc on myloc.user_id = me.id
  join public.profiles p
    on p.id <> me.id
   and p.created_at > now() - make_interval(days => p_days)
   and p.soft_deleted_at is null
  join public.user_locations ploc
    on ploc.user_id = p.id
   and public.ST_DWithin(myloc.location, ploc.location, 50000)
  where me.soft_deleted_at is null
    and me.last_active > now() - interval '14 days'
    and exists (
      select 1
      from public.user_genres g1
      join public.user_genres g2
        on g2.genre_id = g1.genre_id and g2.user_id = p.id
      where g1.user_id = me.id)
  group by me.id
  having count(*) >= p_min;
$$;

create or replace function app_private.notify_new_singers()
returns integer language plpgsql security definer set search_path='' as $$
declare r record; n integer := 0;
begin
  for r in select * from app_private.new_singers_counts() loop
    perform app_private.notify_push(
      array[r.user_id], 'new_singers', jsonb_build_object('count', r.cnt));
    n := n + 1;
  end loop;
  return n;
end; $$;

-- cron.schedule upsert theo jobname (idempotent tren db reset — gotcha P7).
-- 10:00 UTC = 17:00 VN; 05:00 UTC thu Hai = 12:00 VN.
select cron.schedule('keo-tonight-daily', '0 10 * * *',
  $$select app_private.notify_keo_tonight()$$);
select cron.schedule('new-singers-weekly', '0 5 * * 1',
  $$select app_private.notify_new_singers()$$);
