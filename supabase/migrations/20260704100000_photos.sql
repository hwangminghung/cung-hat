-- Profile photos (multi-ảnh, max 3) stored under a PRIVATE per-uid storage bucket.
-- Others see them only via a short-lived server-minted signed URL (Edge Function,
-- access-gated) — never through direct bucket access. No-photo profiles keep the
-- monogram fallback. Adapted from the P1.5 plan's single-photo design.

-- Multi-photo: array of storage paths (was `photo_path text` in the P1.5 draft).
alter table public.profiles add column if not exists photo_paths text[] not null default '{}';

-- Private bucket; objects live under '{uid}/...'. Never public.
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', false)
on conflict (id) do nothing;

-- Owner-only CRUD on their own folder; nobody can directly read another user's object
-- (others go through the sign-photo Edge Function, which uses the service role).
create policy "own photos read" on storage.objects for select to authenticated
  using (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photos insert" on storage.objects for insert to authenticated
  with check (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photos update" on storage.objects for update to authenticated
  using (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "own photos delete" on storage.objects for delete to authenticated
  using (bucket_id='profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- Setter: replace the whole photo set (max 3), each path constrained to the caller's
-- own '{uid}/' folder so it can never point at another user's object (mirrors storage RLS).
create or replace function public.set_my_photo_paths(p_paths text[])
returns void language plpgsql security definer set search_path='' as $$
begin
  if coalesce(array_length(p_paths, 1), 0) > 3 then
    raise exception 'photo_limit' using errcode='check_violation';
  end if;
  -- Mọi path phải nằm trong folder của chính caller (khớp storage RLS).
  if exists (
    select 1 from unnest(p_paths) p
    where p not like auth.uid()::text || '/%'
  ) then
    raise exception 'photo_path_invalid' using errcode='check_violation';
  end if;
  update public.profiles set photo_paths = p_paths where id = auth.uid();
end; $$;
revoke execute on function public.set_my_photo_paths(text[]) from public, anon;
grant execute on function public.set_my_photo_paths(text[]) to authenticated;

-- The get_my_profile / upsert_my_profile RPCs return the sanitized composite type
-- public.my_profile, which ENUMERATES columns explicitly (defined in 0002, extended in
-- 0004) — it does not `to_jsonb` the whole row. So the client would never receive
-- photo_paths unless we (a) add the attribute to the composite type and (b) redefine
-- both RPCs to project it. Do both here so the Flutter Profile model can read photos.
alter type public.my_profile add attribute photo_paths text[] cascade;

create or replace function public.get_my_profile()
returns public.my_profile
language sql security definer set search_path = ''
as $$
  select p.id, p.display_name, p.full_name, p.dob, p.age_verified, p.bio, p.language, p.photo_paths
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
  select p.id,p.display_name,p.full_name,p.dob,p.age_verified,p.bio,p.language,p.photo_paths
    into result from public.profiles p where p.id=auth.uid();
  return result;
end; $$;

-- Re-assert grants (create or replace preserves them, but the P0/onboarding migrations
-- always re-issued them defensively; keep the pattern).
revoke execute on function public.get_my_profile() from public, anon;
revoke execute on function public.upsert_my_profile(text,text,date,text,text) from public, anon;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.upsert_my_profile(text,text,date,text,text) to authenticated;
