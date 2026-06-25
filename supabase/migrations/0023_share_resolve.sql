-- Public-by-token read of a shared plan (venue + time only; no member identities).
create type public.shared_plan_view as (venue_name text, address text, scheduled_at timestamptz, expired boolean);
create or replace function public.resolve_share_plan(p_token text)
returns public.shared_plan_view language sql security definer set search_path='' as $$
  select v.name, v.address, pl.scheduled_at, (sp.expires_at < now())
  from public.share_plans sp
  join public.plans pl on pl.id = sp.plan_id
  join public.venues v on v.id = pl.venue_id
  where sp.share_token = p_token;
$$;
-- Resolvable without login (a friend may not have the app) → grant to anon too.
grant execute on function public.resolve_share_plan(text) to anon, authenticated;
