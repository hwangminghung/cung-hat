-- Pill "Den luot ban" (Tinder-parity muc 7): inbox can biet ai nhan cuoi.
do $$
begin
  alter type public.match_summary add attribute last_sender_id uuid cascade;
exception
  when duplicate_column then null;
end $$;

create or replace function public.get_my_matches()
returns setof public.match_summary language sql security definer set search_path='' as $$
  select m.id,
    case when m.user_a = auth.uid() then m.user_b else m.user_a end as other_id,
    (select display_name from public.profiles p
       where p.id = case when m.user_a = auth.uid() then m.user_b else m.user_a end) as other_name,
    (select count(*)::int from public.messages msg
       where msg.thread_type='match' and msg.thread_id = m.id
         and msg.sender_id <> auth.uid()
         and msg.created_at > coalesce(
           (select last_read_at from public.message_reads r
             where r.thread_type='match' and r.thread_id=m.id and r.user_id=auth.uid()),
           'epoch')) as unread,
    (select msg.sender_id from public.messages msg
       where msg.thread_type='match' and msg.thread_id = m.id
       order by msg.created_at desc limit 1) as last_sender_id
  from public.matches m
  where m.status='active' and (m.user_a=auth.uid() or m.user_b=auth.uid())
  order by m.created_at desc;
$$;
revoke execute on function public.get_my_matches() from public, anon;
grant execute on function public.get_my_matches() to authenticated;
