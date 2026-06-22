-- Require matching + cross_border consent before storing taste/matching data (PDPL).
create or replace function public.upsert_my_taste(p_genre_ids text[], p_artist_ids text[], p_song_ids text[])
returns void language plpgsql security definer set search_path='' as $$
begin
  if not exists (select 1 from public.consents
                 where user_id=auth.uid() and purpose='matching' and granted=true)
     or not exists (select 1 from public.consents
                 where user_id=auth.uid() and purpose='cross_border' and granted=true) then
    raise exception 'consent_required' using errcode='check_violation';
  end if;
  delete from public.user_genres where user_id=auth.uid();
  delete from public.user_artists where user_id=auth.uid();
  delete from public.user_baitu where user_id=auth.uid();
  insert into public.user_genres (user_id, genre_id)
    select auth.uid(), unnest(p_genre_ids);
  insert into public.user_artists (user_id, artist_id)
    select auth.uid(), unnest(p_artist_ids);
  insert into public.user_baitu (user_id, song_id, position)
    select auth.uid(), s, ordinality from unnest(p_song_ids) with ordinality as t(s, ordinality);
end; $$;
revoke execute on function public.upsert_my_taste(text[],text[],text[]) from public, anon;
grant execute on function public.upsert_my_taste(text[],text[],text[]) to authenticated;
