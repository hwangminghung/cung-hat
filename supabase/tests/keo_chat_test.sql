begin;
select plan(1);
set local role authenticated;
select throws_ok(
  $$ select public.send_keo_message('00000000-0000-0000-0000-000000000000'::uuid,'hi') $$,
  '23514', null, 'non-member cannot send keo message');
select * from finish();
rollback;
