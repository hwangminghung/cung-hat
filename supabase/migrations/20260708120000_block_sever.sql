-- [A-I1/A-I2/A-M2] Block phai co hieu luc that:
--   A-I1: block_user khong cat dut match dang active -> nguoi bi block van nhan tin
--         duoc (chat chi kiem tra thanh vien+active, khong kiem tra blocks).
--   A-I2: record_swipe khong co block-check -> cap da block van tao duoc match MOI
--         qua goi RPC truc tiep (deck client von da an ho, day la lop chan server-side).
--   A-M2: who_liked_me khong loc nguoi ma caller da block -> van hien thi likers
--         da bi block trong danh sach "ai da thich ban".
--
-- block_user: copy body tu 0007_safety.sql + THEM update unmatch cap dang active.
-- Tin nhan cu KHONG bi an (giong huy ghep thuong -- chi status doi active -> unmatched).
create or replace function public.block_user(p_blocked uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.blocks(blocker_id, blocked_id) values (auth.uid(), p_blocked)
  on conflict do nothing;
  update public.matches set status='unmatched', unmatched_at=now()
   where user_a = least(auth.uid(), p_blocked)
     and user_b = greatest(auth.uid(), p_blocked)
     and status = 'active';
end; $$;
revoke execute on function public.block_user(uuid) from public, anon;
grant execute on function public.block_user(uuid) to authenticated;

-- record_swipe -- copy VERBATIM tu 20260703100000_doi_swipe_upgrade.sql (ban moi nhat,
-- co quota daily_like/daily_super) + THEM DUY NHAT block-check ngay sau dong
-- enforce_rate_limit('swipe', ...) o dau ham, truoc moi quota/insert/match logic khac.
create or replace function public.record_swipe(p_target uuid, p_direction text)
returns boolean language plpgsql security definer set search_path='' as $$
declare a uuid; b uuid; reciprocal boolean; matched boolean := false;
begin
  perform app_private.enforce_rate_limit('swipe', 200, interval '1 day');
  -- [A-I2] cap da block khong duoc tao swipe/match moi (deck von an ho; day la chan RPC truc tiep).
  if exists (select 1 from public.blocks b
             where (b.blocker_id = auth.uid() and b.blocked_id = p_target)
                or (b.blocker_id = p_target and b.blocked_id = auth.uid())) then
    raise exception 'blocked_pair' using errcode='check_violation';
  end if;
  -- Quota kieu dating-app (server-authoritative, Pro qua app_private.is_pro()).
  -- Quota is deliberately consumed BEFORE the on-conflict-do-nothing insert (fail-closed;
  -- moving it after the insert would open a concurrent-check TOCTOU window).
  if p_direction = 'like' and not app_private.is_pro() then
    begin
      perform app_private.enforce_rate_limit('daily_like', 30, interval '1 day');
    exception when sqlstate '23514' then
      raise exception 'like_limit' using errcode='check_violation';
    end;
  end if;
  if p_direction = 'super' then
    begin
      perform app_private.enforce_rate_limit(
        'daily_super',
        case when app_private.is_pro() then 5 else 1 end,
        interval '1 day');
    exception when sqlstate '23514' then
      raise exception 'super_limit' using errcode='check_violation';
    end;
  end if;
  -- Serialize the two reciprocal swipers on their canonical pair key so a concurrent
  -- opposite swipe is committed-visible before the reciprocity check (prevents lost matches).
  perform pg_advisory_xact_lock(
    hashtextextended(
      least(auth.uid(), p_target)::text || ':' || greatest(auth.uid(), p_target)::text, 0));
  insert into public.swipes(swiper_id, target_type, target_id, direction)
  values (auth.uid(), 'user', p_target::text, p_direction)
  on conflict (swiper_id, target_type, target_id) do nothing;

  if p_direction in ('like','super') then
    select exists(
      select 1 from public.swipes s
      where s.swiper_id = p_target and s.target_type='user'
        and s.target_id = auth.uid()::text and s.direction in ('like','super')
    ) into reciprocal;
    if reciprocal then
      a := least(auth.uid(), p_target); b := greatest(auth.uid(), p_target);
      insert into public.matches(user_a, user_b) values (a, b)
      on conflict (user_a, user_b) do nothing;
      matched := true;
    end if;
  end if;
  return matched;
end; $$;
revoke execute on function public.record_swipe(uuid,text) from public, anon;
grant execute on function public.record_swipe(uuid,text) to authenticated;

-- who_liked_me -- copy VERBATIM tu 20260706130000_profile_prompts.sql (ban moi nhat,
-- co bio + prompts) + THEM DUY NHAT dieu kien loc block 2 chieu vao cuoi WHERE.
create or replace function public.who_liked_me(p_limit int default 20)
returns setof public.discovery_candidate language plpgsql security definer set search_path='' as $$
begin
  if not app_private.has_entitlement('see_likes') then
    raise exception 'entitlement_required' using errcode='check_violation';
  end if;
  return query
    with me as (select location as loc from public.user_locations where user_id=auth.uid())
    select p.id, p.display_name, extract(year from age(p.dob))::int,
           app_private.dist_band(public.ST_Distance(ul.location, me.loc)),
           '{}'::text[], '{}'::text[], p.verified_badge,
           (p.last_active > now() - interval '1 day'),
           p.bio,
           app_private.prompts_json(p.id)
    from public.swipes s
    join public.profiles p on p.id = s.swiper_id
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where s.target_type='user' and s.target_id = auth.uid()::text
      and s.direction in ('like','super') and p.soft_deleted_at is null
      and not exists (select 1 from public.matches m
        where (m.user_a=least(auth.uid(),p.id) and m.user_b=greatest(auth.uid(),p.id)))
      and not exists (select 1 from public.blocks b
             where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
    limit greatest(p_limit,1);
end; $$;
revoke execute on function public.who_liked_me(int) from public, anon;
grant execute on function public.who_liked_me(int) to authenticated;
