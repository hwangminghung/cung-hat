-- P2-T1: raise the profile photo cap from 3 to 6.
-- The cap lives ONLY inside public.set_my_photo_paths (defined in
-- 20260704100000_photos.sql, lines 27-43) — there is no table CHECK constraint
-- enforcing it. This migration redefines that function VERBATIM, changing only
-- the `> 3` threshold to `> 6`; the photo_path_invalid validation loop and the
-- revoke/grant lines are byte-identical to the source. No other migration
-- redefines set_my_photo_paths (grep confirms 20260704100000 is the only hit),
-- so this is the single source of truth going forward.
--
-- supabase/functions/sign-photo/index.ts signs the entire photo_paths array
-- with no count cap of its own, so it needs no change for this bump.
create or replace function public.set_my_photo_paths(p_paths text[])
returns void language plpgsql security definer set search_path='' as $$
begin
  if coalesce(array_length(p_paths, 1), 0) > 6 then
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
