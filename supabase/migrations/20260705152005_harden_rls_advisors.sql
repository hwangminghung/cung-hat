-- Resolve Supabase advisor warnings for mutable function search_path, repeated
-- auth.uid() evaluation in RLS policies, and duplicate message SELECT policies.

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path='' as $$
begin
  new.updated_at = now();
  return new;
end; $$;

drop policy if exists profiles_select_self on public.profiles;
create policy profiles_select_self on public.profiles
  for select to authenticated using ((select auth.uid()) = id);
drop policy if exists profiles_insert_self on public.profiles;
create policy profiles_insert_self on public.profiles
  for insert to authenticated with check ((select auth.uid()) = id);
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

drop policy if exists ug_self on public.user_genres;
create policy ug_self on public.user_genres
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists ua_self on public.user_artists;
create policy ua_self on public.user_artists
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists ub_self on public.user_baitu;
create policy ub_self on public.user_baitu
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists consents_self on public.consents;
create policy consents_self on public.consents
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists blocks_self on public.blocks;
create policy blocks_self on public.blocks
  for all to authenticated
  using ((select auth.uid()) = blocker_id)
  with check ((select auth.uid()) = blocker_id);
drop policy if exists reports_insert_self on public.reports;
create policy reports_insert_self on public.reports
  for insert to authenticated with check ((select auth.uid()) = reporter_id);

drop policy if exists matches_participant on public.matches;
create policy matches_participant on public.matches
  for select to authenticated
  using ((select auth.uid()) = user_a or (select auth.uid()) = user_b);

drop policy if exists messages_select_participant on public.messages;
drop policy if exists messages_select_keo on public.messages;
drop policy if exists messages_select_thread_member on public.messages;
create policy messages_select_thread_member on public.messages
  for select to authenticated
  using (
    (thread_type = 'match' and app_private.in_match(thread_id))
    or (thread_type = 'keo' and app_private.in_keo(thread_id))
  );

drop policy if exists message_reads_self on public.message_reads;
create policy message_reads_self on public.message_reads
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "match members receive broadcasts" on realtime.messages;
create policy "match members receive broadcasts"
  on realtime.messages for select to authenticated
  using (
    exists (
      select 1 from public.matches m
      where 'match:' || m.id::text = realtime.topic()
        and m.status = 'active'
        and (m.user_a = (select auth.uid()) or m.user_b = (select auth.uid()))
    )
  );
drop policy if exists "keo members receive broadcasts" on realtime.messages;
create policy "keo members receive broadcasts"
  on realtime.messages for select to authenticated
  using (
    exists (
      select 1 from public.keo_members m
      where 'keo:' || m.keo_id::text = realtime.topic()
        and m.user_id = (select auth.uid())
        and m.join_status = 'approved'
        and m.confirmed
    )
  );

drop policy if exists keo_host_write on public.keo;
create policy keo_host_write on public.keo
  for all to authenticated
  using ((select auth.uid()) = host_id)
  with check ((select auth.uid()) = host_id);
drop policy if exists keo_members_self on public.keo_members;
create policy keo_members_self on public.keo_members
  for select to authenticated
  using (
    (select auth.uid()) = user_id
    or exists (
      select 1 from public.keo k
      where k.id = keo_id and k.host_id = (select auth.uid())
    )
  );

drop policy if exists plan_conf_self on public.plan_confirmations;
create policy plan_conf_self on public.plan_confirmations
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
drop policy if exists checkins_member on public.checkins;
create policy checkins_member on public.checkins
  for all to authenticated
  using (exists (select 1 from public.plans p where p.id = plan_id and app_private.in_keo(p.keo_id)))
  with check ((select auth.uid()) = user_id);
drop policy if exists share_plans_owner on public.share_plans;
create policy share_plans_owner on public.share_plans
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists purchases_read_self on public.purchases;
create policy purchases_read_self on public.purchases
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists entitlements_read_self on public.entitlements;
create policy entitlements_read_self on public.entitlements
  for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists venue_bookings_self on public.venue_bookings;
create policy venue_bookings_self on public.venue_bookings
  for select to authenticated using ((select auth.uid()) = user_id);

drop policy if exists device_tokens_self on public.device_tokens;
create policy device_tokens_self on public.device_tokens
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

do $$
begin
  if to_regclass('public.boosts') is not null then
    execute 'drop policy if exists boosts_read_self on public.boosts';
    execute 'create policy boosts_read_self on public.boosts for select to authenticated using ((select auth.uid()) = user_id)';
  end if;
end $$;
