-- [C-I3/D] catalog tra them sku + price_minor de UI het hardcode gia.
-- Return type doi (them sku, price_minor) nen phai drop truoc khi tao lai.
drop function if exists public.get_store_products(text);
create function public.get_store_products(p_platform text)
returns table (sku text, type text, store_product_id text, price_minor int)
language sql
stable
set search_path=''
as $$
  select p.sku, p.type, p.store_product_id, p.price_minor
  from public.products p
  where p.platform = p_platform and p.is_active;
$$;

revoke execute on function public.get_store_products(text) from public, anon;
grant execute on function public.get_store_products(text) to authenticated;
