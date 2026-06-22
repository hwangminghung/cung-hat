-- Reference: artists + curated karaoke songs (public read)
create table public.music_artists (
  id text primary key, name text not null, is_curated boolean not null default true, sort int not null default 0
);
create table public.songs (
  id text primary key, title text not null, artist text not null, is_curated boolean not null default true
);
alter table public.music_artists enable row level security;
alter table public.songs enable row level security;
create policy music_artists_read on public.music_artists for select using (true);
create policy songs_read on public.songs for select using (true);

insert into public.music_artists (id, name, sort) values
  ('son_tung','Sơn Tùng M-TP',1),('my_tam','Mỹ Tâm',2),('den_vau','Đen Vâu',3),
  ('hoang_thuy_linh','Hoàng Thùy Linh',4),('blackpink','BLACKPINK',5),('taylor_swift','Taylor Swift',6);
insert into public.songs (id, title, artist) values
  ('s1','Lạc Trôi','Sơn Tùng M-TP'),('s2','Ước Gì','Mỹ Tâm'),
  ('s3','Đưa Nhau Đi Trốn','Đen Vâu'),('s4','Để Mị Nói Cho Mà Nghe','Hoàng Thùy Linh'),
  ('s5','Nơi Này Có Anh','Sơn Tùng M-TP'),('s6','Em Của Ngày Hôm Qua','Sơn Tùng M-TP');

-- Taste graph (self-owned)
create table public.user_genres (
  user_id uuid references auth.users(id) on delete cascade,
  genre_id text references public.music_genres(id),
  primary key (user_id, genre_id)
);
create table public.user_artists (
  user_id uuid references auth.users(id) on delete cascade,
  artist_id text references public.music_artists(id),
  primary key (user_id, artist_id)
);
create table public.user_baitu (
  user_id uuid references auth.users(id) on delete cascade,
  song_id text references public.songs(id),
  position int not null default 0,
  primary key (user_id, song_id)
);
alter table public.user_genres enable row level security;
alter table public.user_artists enable row level security;
alter table public.user_baitu enable row level security;
create policy ug_self on public.user_genres for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy ua_self on public.user_artists for all using (auth.uid()=user_id) with check (auth.uid()=user_id);
create policy ub_self on public.user_baitu for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- Consents (PDPL)
create table public.consents (
  user_id uuid references auth.users(id) on delete cascade,
  purpose text not null check (purpose in ('location','photos','matching','marketing','cross_border')),
  granted boolean not null,
  granted_at timestamptz not null default now(),
  withdrawn_at timestamptz,
  policy_version text not null,
  primary key (user_id, purpose)
);
alter table public.consents enable row level security;
create policy consents_self on public.consents for all using (auth.uid()=user_id) with check (auth.uid()=user_id);

create or replace function public.record_consent(p_purpose text, p_granted boolean, p_policy_version text)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.consents (user_id, purpose, granted, policy_version, withdrawn_at)
  values (auth.uid(), p_purpose, p_granted, p_policy_version, case when p_granted then null else now() end)
  on conflict (user_id, purpose) do update
    set granted = excluded.granted,
        granted_at = case when excluded.granted then now() else public.consents.granted_at end,
        withdrawn_at = case when excluded.granted then null else now() end,
        policy_version = excluded.policy_version;
end; $$;

-- Replace upsert_my_profile: compute age_verified from DOB, REJECT under-18 (server-enforced gate)
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
  select p.id,p.display_name,p.full_name,p.dob,p.age_verified,p.bio,p.language
    into result from public.profiles p where p.id=auth.uid();
  return result;
end; $$;
revoke execute on function public.upsert_my_profile(text,text,date,text,text) from public, anon;
grant execute on function public.upsert_my_profile(text,text,date,text,text) to authenticated;

-- Taste read/write
create or replace function public.get_my_taste()
returns jsonb language sql security definer set search_path='' as $$
  select jsonb_build_object(
    'genres', coalesce((select jsonb_agg(genre_id) from public.user_genres where user_id=auth.uid()), '[]'::jsonb),
    'artists', coalesce((select jsonb_agg(artist_id) from public.user_artists where user_id=auth.uid()), '[]'::jsonb),
    'baitu', coalesce((select jsonb_agg(song_id order by position) from public.user_baitu where user_id=auth.uid()), '[]'::jsonb)
  );
$$;

create or replace function public.upsert_my_taste(p_genre_ids text[], p_artist_ids text[], p_song_ids text[])
returns void language plpgsql security definer set search_path='' as $$
begin
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

revoke execute on function public.record_consent(text,boolean,text) from public, anon;
revoke execute on function public.get_my_taste() from public, anon;
revoke execute on function public.upsert_my_taste(text[],text[],text[]) from public, anon;
grant execute on function public.record_consent(text,boolean,text) to authenticated;
grant execute on function public.get_my_taste() to authenticated;
grant execute on function public.upsert_my_taste(text[],text[],text[]) to authenticated;
