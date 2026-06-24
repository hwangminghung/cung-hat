create table public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins enable row level security; -- no client policy; checked in RPCs

create or replace function app_private.is_admin()
returns boolean language sql security definer set search_path='' stable as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

create table public.moderation_audit (
  id uuid primary key default gen_random_uuid(),
  actor uuid not null references auth.users(id),
  action text not null check (action in ('hide','remove','restore','dismiss')),
  target_type text not null,
  target_id text not null,
  reason text,
  created_at timestamptz not null default now()
);
alter table public.moderation_audit enable row level security; -- admin-only via RPC

-- Reports queue for the console (admin only).
create or replace function public.admin_list_reports(p_status text default 'open')
returns setof public.reports language sql security definer set search_path='' as $$
  select r.* from public.reports r
  where app_private.is_admin() and (p_status is null or r.status = p_status)
  order by r.created_at asc;
$$;

-- Take action: hide/remove the target (soft-delete + tombstone) or dismiss; always audit.
create or replace function public.admin_action_report(p_report uuid, p_action text, p_reason text default null)
returns void language plpgsql security definer set search_path='' as $$
declare r public.reports;
begin
  if not app_private.is_admin() then raise exception 'not_admin' using errcode='check_violation'; end if;
  select * into r from public.reports where id = p_report;
  if not found then raise exception 'no_report' using errcode='no_data_found'; end if;

  if p_action in ('hide','remove') then
    if r.target_type = 'message' then
      update public.messages set hidden=true,
        soft_deleted_at = case when p_action='remove' then now() else soft_deleted_at end
        where id = r.target_id::uuid;
    elsif r.target_type = 'keo' then
      update public.keo set soft_deleted_at = now(), status='cancelled' where id = r.target_id::uuid;
    elsif r.target_type = 'profile' then
      update public.profiles set soft_deleted_at = now(), report_risk = report_risk + 1 where id = r.target_id::uuid;
    else
      raise exception 'unhandled_target_type' using errcode='check_violation';
    end if;
    update public.reports set status='actioned' where id = p_report;
  elsif p_action = 'dismiss' then
    update public.reports set status='dismissed' where id = p_report;
  end if;

  insert into public.moderation_audit(actor, action, target_type, target_id, reason)
  values (auth.uid(), p_action, r.target_type, r.target_id, p_reason);
end; $$;

revoke execute on function public.admin_list_reports(text) from public, anon;
revoke execute on function public.admin_action_report(uuid,text,text) from public, anon;
grant execute on function public.admin_list_reports(text) to authenticated;     -- gated by is_admin inside
grant execute on function public.admin_action_report(uuid,text,text) to authenticated;
