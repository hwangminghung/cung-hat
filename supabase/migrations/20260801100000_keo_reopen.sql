-- [MATCH-AUDIT #2] Kèo full phải MỞ LẠI được khi tụt dưới target.
--
-- Trước đây không một RPC nào đưa status từ 'full' về 'open' (grep toàn bộ
-- migrations: 0 chỗ). Kèo lấp đầy → 'full' → rơi khỏi list_open_keos; sau đó
-- một thành viên rời (leave_keo) hoặc bị host đá (decline_join) thì kèo kẹt
-- 'full' vĩnh viễn với chỗ trống — mất nguồn cung board.
--
-- Kèm 2 lỗi trong approve_join (0013):
--   a) UPDATE không ràng join_status: host "duyệt" được cả người đã RỜI kèo
--      (kéo họ vào lại không có sự đồng ý) — nay chỉ nhận 'requested' và
--      'declined' (host đảo quyết định của chính mình là hợp lệ).
--   b) Đánh dấu 'full' theo filled+1 mà không kiểm tra UPDATE có match hàng
--      nào — duyệt một request không tồn tại cũng khoá kèo. Nay IF NOT FOUND
--      → raise, và đếm LẠI sau update thay vì tin filled+1.

create or replace function app_private.maybe_reopen_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int;
begin
  select count(*) into filled
    from public.keo_members where keo_id=p_keo and join_status='approved';
  select group_size_target into target from public.keo where id=p_keo;
  -- CHỈ kéo 'full' về 'open'. Kèo đã planning/confirmed là nhóm ĐÃ chốt
  -- (maybe_open_keo) — mở lại tuyển người ở giai đoạn đó là sai sản phẩm.
  if filled < target then
    update public.keo set status='open' where id=p_keo and status='full';
  end if;
end; $$;

create or replace function public.approve_join(p_keo uuid, p_user uuid)
returns void language plpgsql security definer set search_path='' as $$
declare filled int; target int;
begin
  perform app_private.assert_host(p_keo);
  perform pg_advisory_xact_lock(hashtextextended(p_keo::text, 0));
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  select group_size_target into target from public.keo where id=p_keo;
  if filled >= target then raise exception 'keo_full' using errcode='check_violation'; end if;
  update public.keo_members set join_status='approved'
   where keo_id=p_keo and user_id=p_user and join_status in ('requested','declined');
  if not found then
    raise exception 'no_such_request' using errcode='check_violation';
  end if;
  -- Đếm lại sau update (không tin filled+1): 'full' chỉ khi THẬT SỰ đủ chỗ.
  select count(*) into filled from public.keo_members where keo_id=p_keo and join_status='approved';
  if filled >= target then update public.keo set status='full' where id=p_keo; end if;
end; $$;

-- decline_join/leave_keo: body 0013 + thêm maybe_reopen_keo ở cuối.
-- maybe_open_keo chạy TRƯỚC (giữ nguyên): nếu nhóm còn lại đủ điều kiện chốt
-- (>=2 approved, tất cả confirmed) thì lên planning — lúc đó status không còn
-- 'full' nên reopen tự thành no-op.
create or replace function public.decline_join(p_keo uuid, p_user uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  perform app_private.assert_host(p_keo);
  update public.keo_members set join_status='declined', confirmed=false where keo_id=p_keo and user_id=p_user;
  perform app_private.maybe_open_keo(p_keo);
  perform app_private.maybe_reopen_keo(p_keo);
end; $$;

create or replace function public.leave_keo(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.keo_members set join_status='left', confirmed=false where keo_id=p_keo and user_id=auth.uid();
  perform app_private.maybe_open_keo(p_keo);
  perform app_private.maybe_reopen_keo(p_keo);
end; $$;

-- Khuôn khoá quyền giữ nguyên như 0013 (helper app_private không expose).
revoke execute on function public.approve_join(uuid,uuid) from public, anon;
revoke execute on function public.decline_join(uuid,uuid) from public, anon;
revoke execute on function public.leave_keo(uuid) from public, anon;
grant execute on function public.approve_join(uuid,uuid) to authenticated;
grant execute on function public.decline_join(uuid,uuid) to authenticated;
grant execute on function public.leave_keo(uuid) to authenticated;
