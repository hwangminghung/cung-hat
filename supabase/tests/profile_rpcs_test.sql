-- Run with: supabase test db
begin;
select plan(2);

-- Property A: anon role CANNOT execute public.get_my_profile()
-- We check privilege directly instead of set local role anon + throws_ok,
-- because anon lacks EXECUTE on pgTAP functions themselves (which would cause
-- the throws_ok call itself to fail, not the function under test).
select ok(
  not has_function_privilege('anon', 'public.get_my_profile()', 'EXECUTE'),
  'anon role is denied EXECUTE on public.get_my_profile()'
);

-- Property B: sanitized public.my_profile type does NOT expose created_at.
-- hasnt_column() targets tables/views, not composite types; we query pg_attribute
-- joined to pg_type directly to inspect the composite type's attributes.
select ok(
  not exists (
    select 1
    from pg_attribute a
    join pg_type t on t.oid = a.attrelid  -- for composite types attrelid = typrelid
    join pg_type ct on ct.typrelid = t.oid
    where ct.typname = 'my_profile'
      and ct.typnamespace = 'public'::regnamespace
      and a.attname = 'created_at'
      and a.attnum > 0
      and not a.attisdropped
  ),
  'my_profile sanitized type omits created_at'
);

select * from finish();
rollback;
