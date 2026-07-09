-- [A-I1] Nguoi dung can duong cat ket noi khong can block/xoa tai khoan.
create or replace function public.unmatch(p_match uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not exists (select 1 from public.matches m
                 where m.id = p_match and (m.user_a = auth.uid() or m.user_b = auth.uid())) then
    raise exception 'not_in_match' using errcode='check_violation';
  end if;
  update public.matches set status='unmatched', unmatched_at=now()
   where id = p_match and status = 'active';  -- idempotent: da unmatched -> no-op
end; $$;
revoke execute on function public.unmatch(uuid) from public, anon;
grant execute on function public.unmatch(uuid) to authenticated;
