-- Fire-and-forget push fan-out. No-ops unless app.fanout_url GUC is set (prod only),
-- so local/test inserts never attempt an HTTP call.
create or replace function app_private.notify_push(p_user_ids uuid[], p_event text, p_data jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare url text := current_setting('app.fanout_url', true);
        secret text := current_setting('app.fanout_secret', true);
begin
  if url is null or url = '' or p_user_ids is null or array_length(p_user_ids,1) is null then
    return;  -- unconfigured (local/test) or no recipients → no-op
  end if;
  perform net.http_post(
    url := url,
    headers := jsonb_build_object('Content-Type','application/json','x-fanout-secret', coalesce(secret,'')),
    body := jsonb_build_object('user_ids', to_jsonb(p_user_ids), 'title', p_event, 'body', p_event, 'data', p_data)
  );
end; $$;

-- New message → notify the other thread participants (match: the peer; keo: approved+confirmed members), minus sender.
create or replace function app_private.on_message_push()
returns trigger language plpgsql security definer set search_path='' as $$
declare recipients uuid[];
begin
  if new.thread_type = 'match' then
    select array_remove(array[m.user_a, m.user_b], new.sender_id) into recipients
    from public.matches m where m.id = new.thread_id;
  elsif new.thread_type = 'keo' then
    select array_agg(km.user_id) into recipients
    from public.keo_members km
    where km.keo_id = new.thread_id and km.join_status='approved' and km.confirmed and km.user_id <> new.sender_id;
  end if;
  perform app_private.notify_push(recipients, 'new_message', jsonb_build_object('thread_type', new.thread_type, 'thread_id', new.thread_id));
  return new;
end; $$;
create trigger messages_push after insert on public.messages
  for each row execute function app_private.on_message_push();

-- New join request → notify the keo host.
create or replace function app_private.on_join_request_push()
returns trigger language plpgsql security definer set search_path='' as $$
declare host uuid;
begin
  if new.join_status = 'requested' then
    select host_id into host from public.keo where id = new.keo_id;
    perform app_private.notify_push(array[host], 'keo_join_request', jsonb_build_object('keo_id', new.keo_id));
  end if;
  return new;
end; $$;
create trigger keo_members_push after insert on public.keo_members
  for each row execute function app_private.on_join_request_push();

-- New plan proposed → notify approved+confirmed keo members.
create or replace function app_private.on_plan_push()
returns trigger language plpgsql security definer set search_path='' as $$
declare recipients uuid[];
begin
  select array_agg(km.user_id) into recipients
  from public.keo_members km
  where km.keo_id = new.keo_id and km.join_status='approved' and km.confirmed;
  perform app_private.notify_push(recipients, 'plan_proposed', jsonb_build_object('keo_id', new.keo_id, 'plan_id', new.id));
  return new;
end; $$;
create trigger plans_push after insert on public.plans
  for each row execute function app_private.on_plan_push();
