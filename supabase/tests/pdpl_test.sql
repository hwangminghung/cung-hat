begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='export_my_data'), 'export_my_data exists');
select ok(exists(select 1 from pg_proc where proname='request_account_deletion'), 'deletion RPC exists');
select * from finish();
rollback;
