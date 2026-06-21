-- Extensions
create extension if not exists postgis;
create extension if not exists pgcrypto;

-- updated_at trigger helper
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

-- profiles: core identity, self-scoped
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) <= 50),
  full_name    text check (char_length(full_name) <= 100),
  dob          date,
  age_verified boolean not null default false,
  bio          text check (char_length(bio) <= 500),
  language     text not null default 'vi',
  last_active     timestamptz not null default now(),
  soft_deleted_at timestamptz,
  tombstone       boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

create policy profiles_select_self on public.profiles
  for select using (auth.uid() = id);
create policy profiles_insert_self on public.profiles
  for insert with check (auth.uid() = id);
create policy profiles_update_self on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);
