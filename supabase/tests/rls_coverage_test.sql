-- Run with: supabase test db
-- [AUDIT M4] baseline_grants dung `alter default privileges` grant-all cho bang
-- tuong lai -> migration nao tao bang ma QUEN enable RLS la authenticated
-- doc/ghi tu do ngay. Guard: moi bang thuong trong public phai relrowsecurity.
begin;
select plan(1);
-- Loai bang thuoc extension (pg_depend deptype 'e'): spatial_ref_sys cua
-- PostGIS la data tham chieu cong khai, khong bat RLS duoc/khong can.
select is_empty(
  $$ select c.relname::text from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
     where n.nspname = 'public' and c.relkind = 'r'
       and not c.relrowsecurity
       and not exists (
         select 1 from pg_depend d
         where d.objid = c.oid and d.classid = 'pg_class'::regclass
           and d.deptype = 'e') $$,
  'moi bang public (ngoai extension) deu bat RLS');
select * from finish();
rollback;
