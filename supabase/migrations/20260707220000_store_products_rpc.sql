-- Catalog product id theo platform cho IapController (het hardcode client).
-- SECURITY INVOKER: RLS products_read (is_active) van ap dung.
create or replace function public.get_store_products(p_platform text)
returns table (type text, store_product_id text)
language sql
stable
set search_path=''
as $$
  select p.type, p.store_product_id
  from public.products p
  where p.platform = p_platform and p.is_active;
$$;
