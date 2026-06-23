-- NOTE: public.swipes is created in 0008 (so get_discovery_candidates can reference it).
create table public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references auth.users(id) on delete cascade,
  user_b uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active','unmatched')),
  created_at timestamptz not null default now(),
  unmatched_at timestamptz,
  unique (user_a, user_b),
  check (user_a < user_b)              -- canonical ordering dedupes pairs
);
alter table public.matches enable row level security;
create policy matches_participant on public.matches for select
  using (auth.uid() = user_a or auth.uid() = user_b);

-- Returns true if this swipe created a mutual match.
create or replace function public.record_swipe(p_target uuid, p_direction text)
returns boolean language plpgsql security definer set search_path='' as $$
declare a uuid; b uuid; reciprocal boolean; matched boolean := false;
begin
  perform app_private.enforce_rate_limit('swipe', 200, interval '1 day');
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
