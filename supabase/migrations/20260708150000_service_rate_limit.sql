-- [B-1] Rate-limit goi tu edge (service role) cho user bat ky — chong scrape sign-photo.
-- KHONG cap cho authenticated (ho co the tu dot bucket cua minh/nguoi khac).
create or replace function public.consume_service_rate_limit(
  p_user uuid, p_bucket text, p_limit int, p_window interval)
returns boolean language plpgsql security definer set search_path='' as $$
declare w timestamptz := to_timestamp(
  floor(extract(epoch from now()) / extract(epoch from p_window)) * extract(epoch from p_window));
declare c int;
begin
  insert into public.rate_limits (user_id, bucket, window_start, count)
  values (p_user, p_bucket, w, 1)
  on conflict (user_id, bucket, window_start) do update set count = public.rate_limits.count + 1
  returning count into c;
  return c <= p_limit;
end; $$;
revoke execute on function public.consume_service_rate_limit(uuid,text,int,interval) from public, anon, authenticated;
grant execute on function public.consume_service_rate_limit(uuid,text,int,interval) to service_role;
