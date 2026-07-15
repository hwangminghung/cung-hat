-- [AUDIT H1] admin_action_report hide/remove set hidden/soft_deleted_at nhung
-- policy select KHONG loc -> tin bi moderate van hien nguyen voi participant
-- (T&S vo tac dung; PDPL hide chi duoc cuu mot phan nho unmatch).
-- Fix: loc hidden + soft_deleted_at ngay trong policy (ca 2 thread type),
-- va get_my_matches khong dem/khong lay last_sender tu tin da an.
-- [AUDIT L2] mark_match_read / mark_keo_read khong check membership ->
-- insert duoc row rac message_reads voi uuid bat ky. Fix: check nhu send_message.

drop policy if exists messages_select_participant on public.messages;
create policy messages_select_participant on public.messages for select
  using (thread_type='match'
         and hidden = false
         and soft_deleted_at is null
         and app_private.in_match(thread_id));

drop policy if exists messages_select_keo on public.messages;
create policy messages_select_keo on public.messages for select
  using (thread_type='keo'
         and hidden = false
         and soft_deleted_at is null
         and app_private.in_keo(thread_id));

-- Body copy tu 20260706140000_inbox_turn_pill.sql, them loc hidden/soft_deleted_at
-- vao 2 subquery unread + last_sender_id.
create or replace function public.get_my_matches()
returns setof public.match_summary language sql security definer set search_path='' as $$
  select m.id,
    case when m.user_a = auth.uid() then m.user_b else m.user_a end as other_id,
    (select display_name from public.profiles p
       where p.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end) as other_name,
    (select count(*)::int from public.messages msg
       where msg.thread_type='match' and msg.thread_id = m.id
         and msg.sender_id <> auth.uid()
         and msg.hidden = false and msg.soft_deleted_at is null
         and msg.created_at > coalesce(
           (select last_read_at from public.message_reads r
             where r.thread_type='match' and r.thread_id=m.id and r.user_id=auth.uid()),
           'epoch')) as unread,
    (select msg.sender_id from public.messages msg
       where msg.thread_type='match' and msg.thread_id = m.id
         and msg.hidden = false and msg.soft_deleted_at is null
       order by msg.created_at desc limit 1) as last_sender_id
  from public.matches m
  where m.status='active' and (m.user_a=auth.uid() or m.user_b=auth.uid())
  order by m.created_at desc;
$$;

create or replace function public.mark_match_read(p_thread uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not app_private.in_match(p_thread) then
    raise exception 'not_a_member' using errcode='check_violation';
  end if;
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('match', p_thread, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;

create or replace function public.mark_keo_read(p_keo uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not app_private.in_keo(p_keo) then
    raise exception 'not_in_keo' using errcode='check_violation';
  end if;
  insert into public.message_reads(thread_type, thread_id, user_id)
  values ('keo', p_keo, auth.uid())
  on conflict (thread_type, thread_id, user_id) do update set last_read_at = now();
end; $$;
