begin;
select plan(2);
select ok(exists(select 1 from pg_proc where proname='register_device_token'), 'register_device_token exists');
select ok(exists(select 1 from cron.job where jobname='purge-deleted-daily'), 'purge cron scheduled');
select * from finish();
rollback;
