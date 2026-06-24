begin;
select plan(1);
select ok(exists(select 1 from pg_proc where proname='confirm_keo_plan'), 'confirm_keo_plan exists');
select * from finish();
rollback;
