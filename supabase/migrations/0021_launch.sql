create extension if not exists pg_cron;
create extension if not exists pg_net;

create table public.device_tokens (
  user_id uuid references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null check (platform in ('ios','android')),
  updated_at timestamptz not null default now(),
  primary key (user_id, fcm_token)
);
alter table public.device_tokens enable row level security;
create policy device_tokens_self on public.device_tokens for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

create or replace function public.register_device_token(p_token text, p_platform text)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.device_tokens(user_id, fcm_token, platform)
  values (auth.uid(), p_token, p_platform)
  on conflict (user_id, fcm_token) do update set updated_at = now();
end; $$;
revoke execute on function public.register_device_token(text,text) from public, anon;
grant execute on function public.register_device_token(text,text) to authenticated;

-- Daily retention hard-delete: profiles tombstoned > 30 days ago are purged from auth.users
-- (cascades remove their data). Runs as a SECURITY DEFINER routine invoked by pg_cron.
create or replace function app_private.purge_expired_accounts()
returns void language plpgsql security definer set search_path='' as $$
begin
  delete from auth.users u
  using public.profiles p
  where p.id = u.id and p.tombstone and p.soft_deleted_at < now() - interval '30 days';
end; $$;

select cron.schedule('purge-deleted-daily', '0 3 * * *', $$ select app_private.purge_expired_accounts(); $$);
