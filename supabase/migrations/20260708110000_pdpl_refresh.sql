-- [D] export_my_data lac hau sau P6/P7/post-v1 — bo sung du lieu nguoi dung so huu.
-- Dung to_jsonb(row) - '<id cols>' de khong phu thuoc chi tiet cot.
-- Doi chieu cot voi migration goc truoc khi viet:
--   share_plans (0016_plans.sql): cot chu (owner) la `user_id`, KHONG PHAI `created_by`.
--   share_keos  (20260707110000_share_keo.sql): ton tai, cot chu la `created_by` —
--     them khoa share_keo_links moi (khong co trong export goc).
create or replace function public.export_my_data()
returns jsonb language sql security definer set search_path='' as $$
  select jsonb_build_object(
    'profile', (select to_jsonb(p) - 'report_risk' from public.profiles p where p.id = auth.uid()),
    'genres',  (select coalesce(jsonb_agg(genre_id), '[]'::jsonb) from public.user_genres where user_id = auth.uid()),
    'artists', (select coalesce(jsonb_agg(artist_id),'[]'::jsonb) from public.user_artists where user_id = auth.uid()),
    'baitu',   (select coalesce(jsonb_agg(song_id),  '[]'::jsonb) from public.user_baitu where user_id = auth.uid()),
    'consents',(select coalesce(jsonb_agg(to_jsonb(c)),'[]'::jsonb) from public.consents c where c.user_id = auth.uid()),
    'prompts', (select coalesce(jsonb_agg(to_jsonb(pp) - 'user_id'),'[]'::jsonb) from public.profile_prompts pp where pp.user_id = auth.uid()),
    'messages_sent', (select coalesce(jsonb_agg(to_jsonb(m) - 'sender_id'),'[]'::jsonb) from public.messages m where m.sender_id = auth.uid()),
    'swipes_made', (select coalesce(jsonb_agg(to_jsonb(s) - 'swiper_id'),'[]'::jsonb) from public.swipes s where s.swiper_id = auth.uid()),
    'matches', (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'status', m.status, 'created_at', m.created_at)),'[]'::jsonb)
                from public.matches m where m.user_a = auth.uid() or m.user_b = auth.uid()),
    'keo_hosted', (select coalesce(jsonb_agg(jsonb_build_object('id',k.id,'title',k.title,'status',k.status,'time_window_start',k.time_window_start)),'[]'::jsonb)
                   from public.keo k where k.host_id = auth.uid()),
    'keo_joined', (select coalesce(jsonb_agg(jsonb_build_object('keo_id',km.keo_id,'join_status',km.join_status,'confirmed',km.confirmed)),'[]'::jsonb)
                   from public.keo_members km where km.user_id = auth.uid()),
    'purchases', (select coalesce(jsonb_agg(to_jsonb(pu) - 'user_id'),'[]'::jsonb) from public.purchases pu where pu.user_id = auth.uid()),
    'entitlements', (select coalesce(jsonb_agg(to_jsonb(e) - 'user_id'),'[]'::jsonb) from public.entitlements e where e.user_id = auth.uid()),
    'venue_bookings', (select coalesce(jsonb_agg(to_jsonb(vb) - 'user_id'),'[]'::jsonb) from public.venue_bookings vb where vb.user_id = auth.uid()),
    'boosts', (select coalesce(jsonb_agg(to_jsonb(bo) - 'user_id'),'[]'::jsonb) from public.boosts bo where bo.user_id = auth.uid()),
    'checkins', (select coalesce(jsonb_agg(to_jsonb(ci) - 'user_id'),'[]'::jsonb) from public.checkins ci where ci.user_id = auth.uid()),
    'device_tokens', (select coalesce(jsonb_agg(to_jsonb(dt) - 'user_id'),'[]'::jsonb) from public.device_tokens dt where dt.user_id = auth.uid()),
    'blocks_made', (select coalesce(jsonb_agg(blocked_id),'[]'::jsonb) from public.blocks where blocker_id = auth.uid()),
    'share_links', (select coalesce(jsonb_agg(to_jsonb(sp) - 'user_id'),'[]'::jsonb) from public.share_plans sp where sp.user_id = auth.uid()),
    'share_keo_links', (select coalesce(jsonb_agg(to_jsonb(sk) - 'created_by'),'[]'::jsonb) from public.share_keos sk where sk.created_by = auth.uid())
  );
$$;

-- [D] deletion bo sung: device_tokens (het push sau khi xoa), prompts, an anh ngay.
-- Body con lai copy VERBATIM tu 0019_pdpl.sql (doi chieu tung dong truoc khi apply).
create or replace function public.request_account_deletion()
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.profiles
    set soft_deleted_at = now(), tombstone = true,
        display_name = 'Người dùng đã rời', full_name = null, bio = null,
        photo_paths = '{}'
    where id = auth.uid();
  delete from public.device_tokens where user_id = auth.uid();
  delete from public.profile_prompts where user_id = auth.uid();
  update public.keo set status='cancelled', soft_deleted_at=now() where host_id = auth.uid() and status <> 'done';
  update public.keo_members set join_status='left' where user_id = auth.uid();
  update public.matches set status='unmatched', unmatched_at=now() where user_a=auth.uid() or user_b=auth.uid();
  -- Hide the departing user's messages immediately (bodies otherwise stay visible until P7 hard-delete).
  update public.messages set hidden = true where sender_id = auth.uid();
  -- Cancel any non-done plans for keos this user hosts.
  update public.plans set status = 'cancelled'
    where status <> 'done'
      and keo_id in (select id from public.keo where host_id = auth.uid());
end; $$;

revoke execute on function public.export_my_data() from public, anon;
revoke execute on function public.request_account_deletion() from public, anon;
grant execute on function public.export_my_data() to authenticated;
grant execute on function public.request_account_deletion() to authenticated;
