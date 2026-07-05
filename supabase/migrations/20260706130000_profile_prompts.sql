-- The hoi-dap karaoke (Tinder-parity muc 4/6): moi ho so chon toi da 3 cau hoi
-- (catalog co dinh o client — lib/features/profile/domain/karaoke_prompts.dart)
-- va tra loi ngan. Cau hoi la id on dinh, khong luu van ban cau hoi o server.

create table public.profile_prompts (
  user_id uuid not null references public.profiles(id) on delete cascade,
  prompt_id text not null,
  answer text not null check (char_length(answer) between 1 and 120),
  position int not null default 0,
  primary key (user_id, prompt_id)
);
alter table public.profile_prompts enable row level security;
create policy profile_prompts_read_self on public.profile_prompts
  for select using (auth.uid() = user_id);
-- writes chi qua RPC; nguoi khac doc qua discovery_candidate (sanitized)
grant select on public.profile_prompts to authenticated;

-- Setter: replace-all (xoa het cua caller roi insert lai theo thu tu mang JSON).
-- p_prompts: [{"prompt_id": "p1", "answer": "..."}, ...] toi da 3 phan tu (khop
-- CHECK phia UI); CHECK char_length(answer) da co o cap bang.
create or replace function public.set_my_prompts(p_prompts jsonb)
returns void language plpgsql security definer set search_path='' as $$
begin
  if jsonb_array_length(coalesce(p_prompts, '[]'::jsonb)) > 3 then
    raise exception 'too_many_prompts' using errcode='check_violation';
  end if;
  delete from public.profile_prompts where user_id = auth.uid();
  insert into public.profile_prompts (user_id, prompt_id, answer, position)
  select auth.uid(), e->>'prompt_id', e->>'answer', ord - 1
  from jsonb_array_elements(coalesce(p_prompts, '[]'::jsonb)) with ordinality as t(e, ord);
end; $$;
revoke execute on function public.set_my_prompts(jsonb) from public, anon;
grant execute on function public.set_my_prompts(jsonb) to authenticated;

-- helper dung chung cho cac projection duoi (my_profile / discovery_candidate).
create or replace function app_private.prompts_json(p_user uuid)
returns jsonb language sql security definer set search_path='' as $$
  select coalesce(
    (select jsonb_agg(jsonb_build_object('prompt_id', prompt_id, 'answer', answer)
                      order by position)
     from public.profile_prompts where user_id = p_user),
    '[]'::jsonb);
$$;

-- my_profile: them attribute prompts (guarded, khop pattern 20260704100000_photos.sql).
do $$
begin
  alter type public.my_profile add attribute prompts jsonb cascade;
exception
  when duplicate_column then null;
end $$;

-- get_my_profile / upsert_my_profile -- copy VERBATIM tu 20260704100000_photos.sql
-- (ban co photo_paths) + THEM DUY NHAT app_private.prompts_json(...) la cot cuoi.
-- 18+ gate (raise under_18/check_violation) giu nguyen byte-for-byte -- load-bearing
-- ve phap ly, khong duoc sua.
create or replace function public.get_my_profile()
returns public.my_profile
language sql security definer set search_path = ''
as $$
  select p.id, p.display_name, p.full_name, p.dob, p.age_verified, p.bio, p.language, p.photo_paths,
         app_private.prompts_json(p.id)
  from public.profiles p
  where p.id = auth.uid();
$$;

create or replace function public.upsert_my_profile(
  p_display_name text, p_full_name text, p_dob date, p_bio text, p_language text
) returns public.my_profile
language plpgsql security definer set search_path='' as $$
declare result public.my_profile;
begin
  if p_dob is null or p_dob > (current_date - interval '18 years') then
    raise exception 'under_18' using errcode = 'check_violation';
  end if;
  insert into public.profiles (id, display_name, full_name, dob, age_verified, bio, language)
  values (auth.uid(), p_display_name, p_full_name, p_dob, true, p_bio, coalesce(p_language,'vi'))
  on conflict (id) do update
    set display_name=excluded.display_name, full_name=excluded.full_name,
        dob=excluded.dob, age_verified=true, bio=excluded.bio, language=excluded.language;
  select p.id,p.display_name,p.full_name,p.dob,p.age_verified,p.bio,p.language,p.photo_paths,
         app_private.prompts_json(auth.uid())
    into result from public.profiles p where p.id=auth.uid();
  return result;
end; $$;

-- Re-assert grants (create or replace preserves them, but the P0/onboarding migrations
-- always re-issued them defensively; keep the pattern).
revoke execute on function public.get_my_profile() from public, anon;
revoke execute on function public.upsert_my_profile(text,text,date,text,text) from public, anon;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.upsert_my_profile(text,text,date,text,text) to authenticated;

-- discovery_candidate: them attribute prompts (guarded).
do $$
begin
  alter type public.discovery_candidate add attribute prompts jsonb cascade;
exception
  when duplicate_column then null;
end $$;

-- get_discovery_candidates -- copy VERBATIM tu 20260706110000_candidate_bio.sql
-- (ban moi nhat, co clamp + bio) + THEM DUY NHAT app_private.prompts_json(c.id) la
-- cot cuoi cua SELECT cuoi (sau c.bio).
create or replace function public.get_discovery_candidates(p_limit int default 20, p_radius_km int default 50)
returns setof public.discovery_candidate
language sql security definer set search_path='' as $$
  with me as (
    select l.location as loc,
      (select array_agg(genre_id) from public.user_genres where user_id = auth.uid()) as genres,
      (select array_agg(song_id) from public.user_baitu where user_id = auth.uid()) as songs
    from public.user_locations l where l.user_id = auth.uid()
  ),
  cand as (
    select p.id, p.display_name, p.dob, p.verified_badge as verified, p.last_active,
           coalesce(p.report_risk, 0) as report_risk,
           p.bio,
           public.ST_Distance(ul.location, me.loc) as dist_m,
           (select array_agg(g.genre_id) from public.user_genres g
              where g.user_id = p.id and g.genre_id = any(me.genres)) as shared_g,
           (select array_agg(s.song_id) from public.user_baitu s
              where s.user_id = p.id and s.song_id = any(me.songs)) as shared_s
    from public.profiles p
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where p.id <> auth.uid()
      and p.soft_deleted_at is null
      and public.ST_DWithin(ul.location, me.loc, least(greatest(p_radius_km, 1), 100) * 1000)
      and not exists (select 1 from public.blocks b
                        where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                           or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
      and not exists (select 1 from public.swipes sw
                        where sw.swiper_id = auth.uid() and sw.target_type = 'user' and sw.target_id = p.id::text)
  )
  select c.id, c.display_name,
         extract(year from age(c.dob))::int as age,
         app_private.dist_band(c.dist_m) as distance_band,
         coalesce(c.shared_g, '{}') as shared_genres,
         coalesce(c.shared_s, '{}') as shared_baitu,
         c.verified, (c.last_active > now() - interval '1 day') as active_today, c.bio,
         app_private.prompts_json(c.id) as prompts
  from cand c
  order by (
      (select weight from public.ranking_weights where key='music') * coalesce(array_length(c.shared_g,1),0)
    + (select weight from public.ranking_weights where key='nearness') * (1.0 / (1 + c.dist_m/1000))
    + (select weight from public.ranking_weights where key='activity') * (case when c.last_active > now() - interval '1 day' then 1 else 0 end)
    - (select weight from public.ranking_weights where key='report_risk') * c.report_risk
    + case when exists (
        select 1 from public.swipes ss
        where ss.swiper_id = c.id and ss.target_type = 'user'
          and ss.target_id = auth.uid()::text and ss.direction = 'super'
      ) then 5.0 else 0 end
    + case when exists (
        select 1 from public.boosts b
        where b.user_id = c.id and b.expires_at > now()
      ) then 3.0 else 0 end
  ) desc
  limit greatest(p_limit, 1);
$$;
revoke execute on function public.get_discovery_candidates(int,int) from public, anon;
grant execute on function public.get_discovery_candidates(int,int) to authenticated;

-- who_liked_me returns setof discovery_candidate too -- MUST be recreated here or it
-- breaks at runtime (attribute-count mismatch) since prompts was appended to the
-- composite type above. Copy VERBATIM tu 20260706110000_candidate_bio.sql +
-- THEM DUY NHAT app_private.prompts_json(p.id) la cot cuoi (sau p.bio).
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
    limit greatest(p_limit,1);
end; $$;
revoke execute on function public.who_liked_me(int) from public, anon;
grant execute on function public.who_liked_me(int) to authenticated;
