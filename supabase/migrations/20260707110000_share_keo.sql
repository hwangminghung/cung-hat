-- Share keo qua token (backlog muc 10) — mirror share_plans (0016) + resolve anon (0023).
create table public.share_keos (
  share_token text primary key default encode(gen_random_bytes(16), 'hex'),
  keo_id uuid not null references public.keo(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days'
);
alter table public.share_keos enable row level security;
-- khong policy client: tao qua RPC, doc qua resolve RPC

-- Gate: host HOAC thanh vien approved — KHONG dung app_private.in_keo (helper do doi
-- status planning+ trong khi ca share chinh la keo dang OPEN tuyen nguoi).
create or replace function public.create_keo_share_link(p_keo uuid)
returns text language plpgsql security definer set search_path='' as $$
declare tok text;
begin
  if not exists (
    select 1 from public.keo k
    where k.id = p_keo and k.soft_deleted_at is null
      and (k.host_id = auth.uid() or exists (
        select 1 from public.keo_members m
        where m.keo_id = p_keo and m.user_id = auth.uid() and m.join_status = 'approved'))
  ) then
    raise exception 'not_keo_member' using errcode='check_violation';
  end if;
  insert into public.share_keos (keo_id, created_by) values (p_keo, auth.uid())
  returning share_token into tok;
  return tok;
end; $$;
revoke execute on function public.create_keo_share_link(uuid) from public, anon;
grant execute on function public.create_keo_share_link(uuid) to authenticated;

-- View sanitized: KHONG toa do; keo_id duoc phep lo (uuid — moi doc/ghi that deu
-- RPC-gated) de user da dang nhap dieu huong vao detail.
create type public.shared_keo_view as (
  keo_id uuid, title text, area_label text, time_window_start timestamptz,
  size_target int, slots_filled int, genres text[], host_name text,
  join_mode text, status text, expired boolean
);
create or replace function public.resolve_share_keo(p_token text)
returns public.shared_keo_view language sql security definer set search_path='' as $$
  select k.id, k.title, k.area_label, k.time_window_start,
         k.group_size_target,
         (select count(*)::int from public.keo_members m
            where m.keo_id = k.id and m.join_status = 'approved'),
         k.genres,
         (select display_name from public.profiles p where p.id = k.host_id),
         k.join_mode, k.status,
         (sk.expires_at < now()) as expired
  from public.share_keos sk
  join public.keo k on k.id = sk.keo_id and k.soft_deleted_at is null
  where sk.share_token = p_token;
$$;
revoke execute on function public.resolve_share_keo(text) from public;
grant execute on function public.resolve_share_keo(text) to anon, authenticated;
