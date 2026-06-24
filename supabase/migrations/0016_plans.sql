create table public.plans (
  id uuid primary key default gen_random_uuid(),
  keo_id uuid not null references public.keo(id) on delete cascade,
  venue_id uuid not null references public.venues(id),
  scheduled_at timestamptz not null,
  status text not null default 'proposed' check (status in ('proposed','confirmed','done','cancelled')),
  created_at timestamptz not null default now()
);
alter table public.plans enable row level security;
create policy plans_member_read on public.plans for select using (app_private.in_keo(keo_id));

create table public.plan_confirmations (
  plan_id uuid references public.plans(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  confirmed_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);
alter table public.plan_confirmations enable row level security;
create policy plan_conf_self on public.plan_confirmations for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

create table public.checkins (
  plan_id uuid references public.plans(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  arrived_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);
alter table public.checkins enable row level security;
create policy checkins_member on public.checkins for all
  using (exists (select 1 from public.plans p where p.id=plan_id and app_private.in_keo(p.keo_id)))
  with check (auth.uid()=user_id);

create table public.share_plans (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references public.plans(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  share_token text not null unique default encode(gen_random_bytes(16),'hex'),
  expires_at timestamptz not null default (now() + interval '1 day')
);
alter table public.share_plans enable row level security;
create policy share_plans_owner on public.share_plans for all
  using (auth.uid()=user_id) with check (auth.uid()=user_id);

-- Host proposes a plan (keo must be in planning); members then confirm.
create or replace function public.propose_keo_plan(p_keo uuid, p_venue uuid, p_when timestamptz)
returns uuid language plpgsql security definer set search_path='' as $$
declare pid uuid;
begin
  perform app_private.assert_host(p_keo);
  if (select status from public.keo where id=p_keo) <> 'planning' then
    raise exception 'keo_not_planning' using errcode='check_violation';
  end if;
  insert into public.plans(keo_id, venue_id, scheduled_at) values (p_keo, p_venue, p_when)
  returning id into pid;
  return pid;
end; $$;

-- A member confirms the plan; when all approved members confirmed → plan + keo 'confirmed'.
create or replace function public.confirm_keo_plan(p_plan uuid)
returns void language plpgsql security definer set search_path='' as $$
declare kid uuid; approved_n int; confirmed_n int;
begin
  select keo_id into kid from public.plans where id=p_plan;
  if not app_private.in_keo(kid) then raise exception 'not_in_keo' using errcode='check_violation'; end if;
  perform pg_advisory_xact_lock(hashtextextended(kid::text, 0));
  insert into public.plan_confirmations(plan_id, user_id) values (p_plan, auth.uid())
  on conflict do nothing;
  select count(*) filter (where m.join_status='approved'),
         count(*) filter (where m.join_status='approved'
           and exists (select 1 from public.plan_confirmations c
                       where c.plan_id=p_plan and c.user_id=m.user_id))
    into approved_n, confirmed_n
  from public.keo_members m where m.keo_id=kid;
  if approved_n >= 2 and confirmed_n >= approved_n then
    update public.plans set status='confirmed' where id=p_plan;
    update public.keo set status='confirmed' where id=kid;
  end if;
end; $$;

create or replace function public.checkin_arrived(p_plan uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  insert into public.checkins(plan_id, user_id) values (p_plan, auth.uid())
  on conflict do nothing;
end; $$;

create or replace function public.create_share_link(p_plan uuid)
returns text language plpgsql security definer set search_path='' as $$
declare tok text;
begin
  insert into public.share_plans(plan_id, user_id) values (p_plan, auth.uid())
  returning share_token into tok;
  return tok;
end; $$;

revoke execute on function public.propose_keo_plan(uuid,uuid,timestamptz) from public, anon;
revoke execute on function public.confirm_keo_plan(uuid) from public, anon;
revoke execute on function public.checkin_arrived(uuid) from public, anon;
revoke execute on function public.create_share_link(uuid) from public, anon;
grant execute on function public.propose_keo_plan(uuid,uuid,timestamptz) to authenticated;
grant execute on function public.confirm_keo_plan(uuid) to authenticated;
grant execute on function public.checkin_arrived(uuid) to authenticated;
grant execute on function public.create_share_link(uuid) to authenticated;
