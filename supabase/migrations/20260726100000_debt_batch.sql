-- Debt batch (muc "Chua lam" cua BANGIAO.md, 2026-07-26):
--
-- 1) is_admin_self(): /admin la route mo coi — client can biet co hien tile
--    Cai dat khong. app_private.is_admin() khong expose duoc cho client; RPC
--    read-only nay chi tra boolean, khong lo them gi.
-- 2) get_my_blocks(): Cai dat chua co danh sach "Da chan". Row blocks doc duoc
--    qua RLS (blocks_self) nhung display_name cua nguoi BI chan thi khong chac
--    doc duoc (block cat visibility hai chieu o cac RPC khac), nen join profiles
--    trong security definer. UNBLOCK khong can RPC: policy blocks_self FOR ALL
--    cho phep DELETE thang row cua chinh minh.
-- 3) cancel_keo_plan(): plan_repository chi co propose/confirm/checkin/share —
--    khong co duong huy. Host huy plan proposed/confirmed; neu keo dang
--    'confirmed' (do plan nay day len) thi tra keo ve 'planning' de chot lai.
-- 4) propose_keo_plan REDEFINE (copy nguyen body tu 20260628193420, chi them
--    buoc huy plan 'proposed' cu): truoc day "sua ke hoach" = propose ban moi,
--    ban cu thanh mo coi vinh vien trong bang plans.
-- 5) plan_conf_member_read: thanh vien keo xem duoc AI da xac nhan plan.
--    Policy cu (plan_conf_self FOR ALL) chi cho doc row cua chinh minh nen UI
--    khong the hien danh sach "3/4 da dong y".

create or replace function public.is_admin_self()
returns boolean language sql stable security definer set search_path='' as $$
  select app_private.is_admin();
$$;
revoke execute on function public.is_admin_self() from public, anon;
grant execute on function public.is_admin_self() to authenticated;

create or replace function public.get_my_blocks()
returns table(blocked_id uuid, display_name text, created_at timestamptz)
language sql stable security definer set search_path='' as $$
  select b.blocked_id, p.display_name, b.created_at
  from public.blocks b
  left join public.profiles p on p.id = b.blocked_id
  where b.blocker_id = auth.uid()
  order by b.created_at desc;
$$;
revoke execute on function public.get_my_blocks() from public, anon;
grant execute on function public.get_my_blocks() to authenticated;

create or replace function public.cancel_keo_plan(p_plan uuid)
returns void language plpgsql security definer set search_path='' as $$
declare kid uuid; pstatus text;
begin
  select keo_id, status into kid, pstatus from public.plans where id = p_plan;
  if kid is null then
    raise exception 'plan_not_found' using errcode='check_violation';
  end if;
  perform app_private.assert_host(kid);
  if pstatus not in ('proposed', 'confirmed') then
    -- 'done' da di choi xong, 'cancelled' huy roi — ca hai deu bat bien.
    raise exception 'plan_not_cancellable' using errcode='check_violation';
  end if;
  update public.plans set status='cancelled' where id = p_plan;
  -- confirm_keo_plan tung day keo len 'confirmed' khi du nguoi dong y; huy
  -- plan do thi keo quay ve 'planning' de host propose lai. Plan 'proposed'
  -- thi keo van dang planning/open — update nay khong khop row nao.
  update public.keo set status='planning' where id = kid and status='confirmed';
end; $$;
revoke execute on function public.cancel_keo_plan(uuid) from public, anon;
grant execute on function public.cancel_keo_plan(uuid) to authenticated;

create or replace function public.propose_keo_plan(
  p_keo uuid,
  p_venue uuid,
  p_when timestamptz
)
returns uuid language plpgsql security definer set search_path='' as $$
declare
  pid uuid;
  keo_status text;
begin
  perform app_private.assert_host(p_keo);

  select status into keo_status
  from public.keo
  where id = p_keo;

  if keo_status not in ('open', 'full', 'planning') then
    raise exception 'keo_not_planning' using errcode='check_violation';
  end if;

  -- [DEBT 2026-07-26] Ban de xuat cu chua ai dong y thi tu huy khi host doi y
  -- — het mo coi. Plan 'confirmed' KHONG bi dong nay dung: keo luc do da
  -- 'confirmed' nen da bi chan o check tren (host phai cancel_keo_plan truoc).
  update public.plans set status='cancelled'
   where keo_id = p_keo and status = 'proposed';

  insert into public.plans(keo_id, venue_id, scheduled_at)
  values (p_keo, p_venue, p_when)
  returning id into pid;

  return pid;
end; $$;

create policy plan_conf_member_read on public.plan_confirmations for select
  using (
    exists (
      select 1 from public.plans p
      where p.id = plan_id and app_private.in_keo(p.keo_id)
    )
  );
