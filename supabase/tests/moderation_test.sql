begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='admin_action_report'), 'admin RPC exists');
set local role authenticated;
select throws_ok(
  $$ select public.admin_action_report('00000000-0000-0000-0000-000000000000'::uuid,'dismiss') $$,
  '23514', null, 'non-admin cannot moderate');
select * from finish();
rollback;
