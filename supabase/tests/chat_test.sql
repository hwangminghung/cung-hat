begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='send_message'), 'send_message exists');
set local role authenticated;
-- with no auth.uid()/match, sending must fail the membership check
select throws_ok(
  $$ select public.send_message('00000000-0000-0000-0000-000000000000'::uuid, 'hi') $$,
  '23514', null, 'non-member cannot send');
reset role;
select * from finish();
rollback;
