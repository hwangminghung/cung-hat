-- Private schema NOT exposed by PostgREST; all definer logic lives here.
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

-- Sanitized return type = the privacy boundary (never SELECT * of base tables).
create type public.my_profile as (
  id uuid, display_name text, full_name text, dob date,
  age_verified boolean, bio text, language text
);

create or replace function public.get_my_profile()
returns public.my_profile
language sql security definer set search_path = ''
as $$
  select p.id, p.display_name, p.full_name, p.dob, p.age_verified, p.bio, p.language
  from public.profiles p
  where p.id = auth.uid();
$$;

create or replace function public.upsert_my_profile(
  p_display_name text, p_full_name text, p_dob date, p_bio text, p_language text
) returns public.my_profile
language plpgsql security definer set search_path = ''
as $$
declare result public.my_profile;
begin
  insert into public.profiles (id, display_name, full_name, dob, bio, language)
  values (auth.uid(), p_display_name, p_full_name, p_dob, p_bio, coalesce(p_language, 'vi'))
  on conflict (id) do update
    set display_name = excluded.display_name,
        full_name    = excluded.full_name,
        dob          = excluded.dob,
        bio          = excluded.bio,
        language     = excluded.language;
  select p.id, p.display_name, p.full_name, p.dob, p.age_verified, p.bio, p.language
    into result from public.profiles p where p.id = auth.uid();
  return result;
end; $$;

-- Lock execution: deny anon/public, allow only logged-in users.
revoke execute on function public.get_my_profile() from public, anon;
revoke execute on function public.upsert_my_profile(text,text,date,text,text) from public, anon;
grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.upsert_my_profile(text,text,date,text,text) to authenticated;
