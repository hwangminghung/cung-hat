-- "Keo cua ban": sau khi keo roi trang thai 'open' (join xong / all-confirm ->
-- planning) thi bien mat khoi board (list_open_keos chi tra 'open' chua tham gia)
-- -> ca host lan member MAT LOI VAO keo cua minh. RPC nay cap danh sach keo
-- caller dang dinh liu cho section "Keo cua ban" tren tab Chat (mockup 15).
-- RETURNS TABLE alias khop JsonKey model `Keo` phia Flutter (khong dung
-- composite keo_card — type do bi drop/recreate nhieu dot, tranh coupling).
create or replace function public.get_my_keos()
returns table (
  id uuid,
  title text,
  area_label text,
  time_window_start timestamptz,
  time_window_end timestamptz,
  size_target int,
  slots_filled int,
  genres text[],
  host_name text,
  status text,
  join_mode text,
  is_mine boolean
) language sql security definer set search_path='' as $$
  select k.id, k.title, k.area_label,
         k.time_window_start, k.time_window_end,
         k.group_size_target,
         (select count(*)::int from public.keo_members m
            where m.keo_id = k.id and m.join_status = 'approved') as slots_filled,
         k.genres,
         (select display_name from public.profiles p where p.id = k.host_id) as host_name,
         k.status,
         k.join_mode,
         (k.host_id = auth.uid()) as is_mine
  from public.keo k
  where k.soft_deleted_at is null
    and k.status in ('open', 'full', 'planning', 'confirmed')
    -- grace 7 ngay: 'done' con write-dead nen keo vua hat xong van can vao
    -- chat/plan; keo qua cu tu an.
    and k.time_window_end > now() - interval '7 days'
    and (k.host_id = auth.uid()
         or exists (select 1 from public.keo_members m2
                    where m2.keo_id = k.id
                      and m2.user_id = auth.uid()
                      and m2.join_status in ('approved', 'requested')))
  order by k.time_window_start asc;
$$;
revoke execute on function public.get_my_keos() from public, anon;
grant execute on function public.get_my_keos() to authenticated;
