create table public.blocks (
  blocker_id uuid references auth.users(id) on delete cascade,
  blocked_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
alter table public.blocks enable row level security;
create policy blocks_self on public.blocks for all using (auth.uid()=blocker_id) with check (auth.uid()=blocker_id);
create index blocks_blocked_ix on public.blocks(blocked_id);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users(id) on delete cascade,
  target_type text not null check (target_type in ('profile','keo','message','photo')),
  target_id text not null,
  reason text,
  status text not null default 'open' check (status in ('open','actioned','dismissed')),
  created_at timestamptz not null default now()
);
alter table public.reports enable row level security;
create policy reports_insert_self on public.reports for insert with check (auth.uid()=reporter_id);
-- No client SELECT: moderation console (P5) reads via a moderation role.

-- Generic atomic rate limiter (used across swipes/messages/reports/OTP).
create table public.rate_limits (
  user_id uuid references auth.users(id) on delete cascade,
  bucket text not null,
  window_start timestamptz not null,
  count int not null default 0,
  primary key (user_id, bucket, window_start)
);
alter table public.rate_limits enable row level security;
-- no client policy; only touched inside SECURITY DEFINER RPCs

create or replace function app_private.enforce_rate_limit(p_bucket text, p_limit int, p_window interval)
returns void language plpgsql security definer set search_path='' as $$
-- Tumbling window: snap now() down to the start of the current p_window-sized
-- bucket (epoch-aligned). interval '1 day' -> per-UTC-day, interval '1 minute'
-- -> per-minute, etc. The PK (user_id, bucket, window_start) dedupes per window.
declare w timestamptz := to_timestamp(
  floor(extract(epoch from now()) / extract(epoch from p_window)) * extract(epoch from p_window));
declare c int;
begin
  insert into public.rate_limits (user_id, bucket, window_start, count)
  values (auth.uid(), p_bucket, w, 1)
  on conflict (user_id, bucket, window_start) do update set count = public.rate_limits.count + 1
  returning count into c;
  if c > p_limit then
    raise exception 'rate_limit_exceeded' using errcode = 'check_violation';
  end if;
end; $$;

create or replace function public.block_user(p_blocked uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.blocks(blocker_id, blocked_id) values (auth.uid(), p_blocked)
  on conflict do nothing;
end; $$;

create or replace function public.report_user(p_target uuid, p_reason text)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform app_private.enforce_rate_limit('report', 20, interval '1 day');
  insert into public.reports(reporter_id, target_type, target_id, reason)
  values (auth.uid(), 'profile', p_target::text, p_reason);
end; $$;

revoke execute on function public.block_user(uuid) from public, anon;
revoke execute on function public.report_user(uuid,text) from public, anon;
grant execute on function public.block_user(uuid) to authenticated;
grant execute on function public.report_user(uuid,text) to authenticated;
