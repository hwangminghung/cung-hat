-- Export everything the user owns as one JSON document.
create or replace function public.export_my_data()
returns jsonb language sql security definer set search_path='' as $$
  select jsonb_build_object(
    'profile', (select to_jsonb(p) - 'report_risk' from public.profiles p where p.id = auth.uid()),
    'genres',  (select coalesce(jsonb_agg(genre_id), '[]'::jsonb) from public.user_genres where user_id = auth.uid()),
    'artists', (select coalesce(jsonb_agg(artist_id),'[]'::jsonb) from public.user_artists where user_id = auth.uid()),
    'baitu',   (select coalesce(jsonb_agg(song_id),  '[]'::jsonb) from public.user_baitu where user_id = auth.uid()),
    'consents',(select coalesce(jsonb_agg(to_jsonb(c)),'[]'::jsonb) from public.consents c where c.user_id = auth.uid())
  );
$$;

-- Soft-delete now (immediate UX), tombstone for the retention window; a scheduled
-- Edge Function (P7) performs the hard delete + auth.users removal after the window.
create or replace function public.request_account_deletion()
returns void language plpgsql security definer set search_path='' as $$
begin
  update public.profiles
    set soft_deleted_at = now(), tombstone = true,
        display_name = 'Người dùng đã rời', full_name = null, bio = null
    where id = auth.uid();
  update public.keo set status='cancelled', soft_deleted_at=now() where host_id = auth.uid() and status <> 'done';
  update public.keo_members set join_status='left' where user_id = auth.uid();
  update public.matches set status='unmatched', unmatched_at=now() where user_a=auth.uid() or user_b=auth.uid();
end; $$;

revoke execute on function public.export_my_data() from public, anon;
revoke execute on function public.request_account_deletion() from public, anon;
grant execute on function public.export_my_data() to authenticated;
grant execute on function public.request_account_deletion() to authenticated;
