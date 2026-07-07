-- Tien coc dat phong do SERVER quyet (dong hoa loi "client tu ra gia" cua P6).
-- VND khong co don vi le: minor = dong. Mac dinh 200k; chinh per-venue la viec BD sau.
alter table public.venues
  add column if not exists booking_deposit_minor int not null default 200000
  constraint venues_deposit_positive check (booking_deposit_minor > 0);
