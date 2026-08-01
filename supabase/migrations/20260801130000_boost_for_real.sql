-- [MATCH-AUDIT #1a] Boost 49k phải LÀM ĐƯỢC điều đã bán.
--
-- Store bán boost là consumable "Đẩy kèo lên top — hiệu lực 24 giờ";
-- validate-iap cấp entitlement 'boost' active_until = mua + 24h. Nhưng:
--   a) activate_boost đòi is_pro() → người mua boost lẻ KHÔNG kích hoạt được
--      chính thứ vừa trả tiền (pro_required);
--   b) list_open_keos xếp thuần theo giờ bắt đầu — chức năng "lên top" KHÔNG
--      TỒN TẠI ở board Kèo.
-- Tiền vẫn thu qua validate-iap mà không giao gì. Sửa cả hai đầu:
--
--   1) Board Kèo: kèo của host đang có boost (entitlement 'boost' còn hạn,
--      hoặc Pro — store card Pro ghi rõ "tăng hiển thị kèo") nổi lên ĐẦU
--      bảng, trong từng nhóm vẫn xếp theo giờ như cũ.
--   2) activate_boost (ưu tiên deck Đôi 30'): gate đổi is_pro() →
--      has_entitlement('boost') — Pro là superset nên Pro không đổi gì,
--      người mua boost lẻ dùng được trong cửa sổ 24h. Lỗi mới boost_required
--      (client map riêng, không còn nói dối "cần Pro" với người ĐÃ trả tiền).
--
-- get_my_entitlements: lọc entitlement HẾT HẠN (boost là loại duy nhất có
-- active_until) — client cache set feature theo RPC này, trả cả row hết hạn
-- thì gate client sai suốt 24h+ sau khi boost hết.

-- 1) list_open_keos — body copy VERBATIM từ 20260713180000_keo_card_member_names
--    + thêm DUY NHẤT cột sắp xếp boosted (không đổi return type).
create or replace function public.list_open_keos(p_limit int default 30, p_radius_km int default 50)
returns setof public.keo_card language sql security definer set search_path='' as $$
  with me as (select location as loc from public.user_locations where user_id = auth.uid())
  select k.id, k.title, k.area_label,
         app_private.dist_band(public.ST_Distance(k.area_geo, me.loc)) as distance_band,
         k.time_window_start, k.time_window_end, k.group_size_target,
         (select count(*)::int from public.keo_members m
            where m.keo_id = k.id and m.join_status = 'approved') as slots_filled,
         k.genres,
         (select display_name from public.profiles p where p.id = k.host_id) as host_name,
         k.status,
         k.join_mode,
         exists (select 1 from public.keo_members m3
                   where m3.keo_id = k.id and m3.user_id = auth.uid()
                     and m3.join_status in ('requested','approved'))
           or k.host_id = auth.uid()  as is_mine,
         (select array_agg(p2.display_name order by (m4.role = 'host') desc, m4.joined_at)
            from (select m4i.user_id, m4i.role, m4i.joined_at
                    from public.keo_members m4i
                   where m4i.keo_id = k.id and m4i.join_status = 'approved'
                   order by (m4i.role = 'host') desc, m4i.joined_at
                   limit 5) m4
            join public.profiles p2 on p2.id = m4.user_id) as member_names
  from public.keo k cross join me
  where k.status = 'open'
    and k.soft_deleted_at is null
    and k.time_window_end > now()
    and public.ST_DWithin(k.area_geo, me.loc, p_radius_km * 1000)
    and not exists (select 1 from public.blocks b
                    where (b.blocker_id = auth.uid() and b.blocked_id = k.host_id)
                       or (b.blocker_id = k.host_id and b.blocked_id = auth.uid()))
  order by
    exists (select 1 from public.entitlements e
             where e.user_id = k.host_id
               and e.feature in ('boost','pro')
               and (e.active_until is null or e.active_until > now())) desc,
    k.time_window_start asc
  limit greatest(p_limit, 1);
$$;
revoke execute on function public.list_open_keos(int,int) from public, anon;
grant execute on function public.list_open_keos(int,int) to authenticated;

-- 2) activate_boost — body copy VERBATIM từ 20260704110000 + đổi gate.
create or replace function public.activate_boost()
returns timestamptz language plpgsql security definer set search_path='' as $$
declare new_expiry timestamptz;
begin
  if not app_private.has_entitlement('boost') then
    raise exception 'boost_required' using errcode='check_violation';
  end if;
  if exists (select 1 from public.boosts b where b.user_id = auth.uid() and b.expires_at > now()) then
    raise exception 'boost_active' using errcode='check_violation';
  end if;
  begin
    perform app_private.enforce_rate_limit('daily_boost', 1, interval '1 day');
  exception when sqlstate '23514' then
    raise exception 'boost_limit' using errcode='check_violation';
  end;
  new_expiry := now() + interval '30 minutes';
  insert into public.boosts (user_id, expires_at) values (auth.uid(), new_expiry)
  on conflict (user_id) do update set expires_at = excluded.expires_at;
  return new_expiry;
end; $$;
revoke execute on function public.activate_boost() from public, anon;
grant execute on function public.activate_boost() to authenticated;

-- 3) get_my_entitlements — chỉ trả entitlement còn hiệu lực.
create or replace function public.get_my_entitlements()
returns setof public.entitlements language sql security definer set search_path='' as $$
  select * from public.entitlements
  where user_id = auth.uid()
    and (active_until is null or active_until > now());
$$;
revoke execute on function public.get_my_entitlements() from public, anon;
grant execute on function public.get_my_entitlements() to authenticated;
