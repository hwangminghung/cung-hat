-- [A-C1] moderation_audit.actor NO-ACTION chan purge PDPL hang loat khi actor da bi xoa.
-- Giu audit row, mat danh tinh actor (set null) — chap nhan cho audit noi bo.
alter table public.moderation_audit alter column actor drop not null;
alter table public.moderation_audit
  drop constraint moderation_audit_actor_fkey;
alter table public.moderation_audit
  add constraint moderation_audit_actor_fkey
  foreign key (actor) references auth.users(id) on delete set null;

-- [A-M1] pg_net loi KHONG duoc abort insert message/join/plan (AFTER trigger).
-- Copy VERBATIM tu 0022_push_triggers.sql, chi boc http_post trong exception guard.
create or replace function app_private.notify_push(p_user_ids uuid[], p_event text, p_data jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare url text := current_setting('app.fanout_url', true);
        secret text := current_setting('app.fanout_secret', true);
begin
  if url is null or url = '' or p_user_ids is null or array_length(p_user_ids,1) is null then
    return;  -- unconfigured (local/test) or no recipients → no-op
  end if;
  begin
    perform net.http_post(
      url := url,
      headers := jsonb_build_object('Content-Type','application/json','x-fanout-secret', coalesce(secret,'')),
      body := jsonb_build_object('user_ids', to_jsonb(p_user_ids), 'title', p_event, 'body', p_event, 'data', p_data)
    );
  exception when others then
    null;  -- fire-and-forget: push loi khong duoc lam hong giao dich goc
  end;
end; $$;
