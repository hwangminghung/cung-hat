create table public.music_genres (
  id text primary key,
  name_vi text not null,
  name_en text not null,
  sort int not null default 0
);
alter table public.music_genres enable row level security;
create policy music_genres_read on public.music_genres for select using (true);

insert into public.music_genres (id, name_vi, name_en, sort) values
  ('vpop','V-Pop','V-Pop',1),
  ('ballad','Ballad','Ballad',2),
  ('bolero','Bolero','Bolero',3),
  ('rap_vn','Rap Việt','Vietnamese Rap',4),
  ('kpop','K-Pop','K-Pop',5),
  ('us_uk','US-UK','US-UK',6),
  ('rock','Rock','Rock',7),
  ('indie','Indie','Indie',8);
