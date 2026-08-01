-- [MATCH-AUDIT #4a] "Ai đã thích bạn" không được hiện người mình ĐÃ vuốt.
--
-- Trước đây who_liked_me chỉ loại cặp đã match và cặp đã block: người mình
-- đã PASS vẫn nằm trong danh sách trả phí — bấm "thích lại" họ (tính năng đi
-- kèm migration này ở client) cũng vô nghĩa vì swipe là 1 hàng/cặp, đã pass
-- thì record_swipe on-conflict-do-nothing không đổi được hướng.
--
-- Loại MỌI target mình đã vuốt là đúng ngữ nghĩa màn hình "chờ bạn đáp lại":
--   - đã like → nếu họ cũng like thì đã thành match (bị loại bởi điều kiện
--     match sẵn có) — không tồn tại trạng thái "đã like mà còn trong list";
--   - đã pass → mình đã trả lời rồi, hiện lại chỉ gây bấm nhầm.
--
-- Body copy VERBATIM từ 20260708120000_block_sever.sql (bản mới nhất, có
-- bio + prompts + lọc block) + thêm DUY NHẤT điều kiện chưa-từng-vuốt.
create or replace function public.who_liked_me(p_limit int default 20)
returns setof public.discovery_candidate language plpgsql security definer set search_path='' as $$
begin
  if not app_private.has_entitlement('see_likes') then
    raise exception 'entitlement_required' using errcode='check_violation';
  end if;
  return query
    with me as (select location as loc from public.user_locations where user_id=auth.uid())
    select p.id, p.display_name, extract(year from age(p.dob))::int,
           app_private.dist_band(public.ST_Distance(ul.location, me.loc)),
           '{}'::text[], '{}'::text[], p.verified_badge,
           (p.last_active > now() - interval '1 day'),
           p.bio,
           app_private.prompts_json(p.id)
    from public.swipes s
    join public.profiles p on p.id = s.swiper_id
    join public.user_locations ul on ul.user_id = p.id
    cross join me
    where s.target_type='user' and s.target_id = auth.uid()::text
      and s.direction in ('like','super') and p.soft_deleted_at is null
      and not exists (select 1 from public.matches m
        where (m.user_a=least(auth.uid(),p.id) and m.user_b=greatest(auth.uid(),p.id)))
      and not exists (select 1 from public.blocks b
             where (b.blocker_id = auth.uid() and b.blocked_id = p.id)
                or (b.blocker_id = p.id and b.blocked_id = auth.uid()))
      and not exists (select 1 from public.swipes ms
             where ms.swiper_id = auth.uid() and ms.target_type = 'user'
               and ms.target_id = p.id::text)
    limit greatest(p_limit,1);
end; $$;
revoke execute on function public.who_liked_me(int) from public, anon;
grant execute on function public.who_liked_me(int) to authenticated;
