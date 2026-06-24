create or replace function public.request_join_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int; st text;
begin
  perform app_private.enforce_rate_limit('join_keo', 50, interval '1 day');
  select status, group_size_target into st, target from public.keo where id = p_keo;
  if st <> 'open' then raise exception 'keo_not_open' using errcode='check_violation'; end if;
  if exists (select 1 from public.keo where id=p_keo and host_id=auth.uid()) then
    raise exception 'is_host' using errcode='check_violation';
  end if;
  if exists (select 1 from public.blocks b
             where (b.blocker_id=auth.uid() and b.blocked_id=(select host_id from public.keo where id=p_keo))
                or (b.blocked_id=auth.uid() and b.blocker_id=(select host_id from public.keo where id=p_keo)))
  then raise exception 'blocked' using errcode='check_violation'; end if;
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  if filled >= target then raise exception 'keo_full' using errcode='check_violation'; end if;
  if exists (select 1 from public.keo_members where keo_id=p_keo and user_id=auth.uid() and join_status='declined') then
    raise exception 'already_declined' using errcode='check_violation';
  end if;
  insert into public.keo_members(keo_id, user_id, role, join_status)
  values (p_keo, auth.uid(), 'member', 'requested')
  on conflict (keo_id, user_id) do update set join_status='requested';
end; $$;

create or replace function app_private.assert_host(p_keo uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
  if not exists (select 1 from public.keo where id=p_keo and host_id=auth.uid()) then
    raise exception 'not_host' using errcode='check_violation';
  end if;
end; $$;

create or replace function public.approve_join(p_keo uuid, p_user uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int;
begin
  perform app_private.assert_host(p_keo);
  perform pg_advisory_xact_lock(hashtextextended(p_keo::text, 0));
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  select group_size_target into target from public.keo where id=p_keo;
  if filled >= target then raise exception 'keo_full' using errcode='check_violation'; end if;
  update public.keo_members set join_status='approved' where keo_id=p_keo and user_id=p_user;
  if filled + 1 >= target then update public.keo set status='full' where id=p_keo; end if;
end; $$;

create or replace function public.decline_join(p_keo uuid, p_user uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform app_private.assert_host(p_keo);
  update public.keo_members set join_status='declined', confirmed=false where keo_id=p_keo and user_id=p_user;
  perform app_private.maybe_open_keo(p_keo);
end; $$;

create or replace function public.leave_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.keo_members set join_status='left', confirmed=false where keo_id=p_keo and user_id=auth.uid();
  perform app_private.maybe_open_keo(p_keo);
end; $$;

create or replace function app_private.maybe_open_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare approved_n int; confirmed_n int;
begin
  select count(*) filter (where join_status='approved'),
         count(*) filter (where join_status='approved' and confirmed)
    into approved_n, confirmed_n from public.keo_members where keo_id=p_keo;
  if approved_n >= 2 and approved_n = confirmed_n then
    update public.keo set status='planning' where id=p_keo and status in ('open','full');
  end if;
end; $$;

-- A member confirms; when ALL approved members confirmed and >=2, open the group (status='planning').
create or replace function public.confirm_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.keo_members set confirmed=true where keo_id=p_keo and user_id=auth.uid() and join_status='approved';
  perform app_private.maybe_open_keo(p_keo);
end; $$;

revoke execute on function public.request_join_keo(uuid) from public, anon;
revoke execute on function public.approve_join(uuid,uuid) from public, anon;
revoke execute on function public.decline_join(uuid,uuid) from public, anon;
revoke execute on function public.leave_keo(uuid) from public, anon;
revoke execute on function public.confirm_keo(uuid) from public, anon;
grant execute on function public.request_join_keo(uuid) to authenticated;
grant execute on function public.approve_join(uuid,uuid) to authenticated;
grant execute on function public.decline_join(uuid,uuid) to authenticated;
grant execute on function public.leave_keo(uuid) to authenticated;
grant execute on function public.confirm_keo(uuid) to authenticated;
