-- Run with: supabase test db
-- [AUDIT P1-2] Onboarding trước đây chạy 3 lượt mạng rời nhau từ client:
-- upsert_my_profile → n× record_consent → upsert_my_taste. Rớt mạng ở giữa để
-- lại tài khoản NỬA VỜI: row profiles đã tồn tại (router coi như xong onboarding)
-- nhưng thiếu consent (rủi ro PDPL) và thiếu taste (deck rỗng), và user không
-- có đường quay lại màn onboarding để sửa.
--
-- complete_onboarding() gộp cả ba vào MỘT hàm plpgsql = một transaction: bước
-- sau nổ thì bước trước bị rollback, không sinh được trạng thái nửa vời.
begin;
select plan(6);

-- U = 00000000-0000-0000-0000-0000000000b1 (thiếu consent → phải rollback)
-- V = 00000000-0000-0000-0000-0000000000b2 (đủ consent → happy path)
set local role postgres;
insert into auth.users (id) values
  ('00000000-0000-0000-0000-0000000000b1'),
  ('00000000-0000-0000-0000-0000000000b2')
  on conflict (id) do nothing;
reset role;

select ok(
  exists(select 1 from pg_proc where proname='complete_onboarding'),
  'complete_onboarding exists');

-- Cùng khuôn khoá quyền như các RPC onboarding khác: chỉ user đã đăng nhập.
select ok(
  not has_function_privilege('anon',
    'public.complete_onboarding(text,text,date,text,text,jsonb,text,text[],text[],text[])',
    'EXECUTE'),
  'anon bị từ chối EXECUTE trên complete_onboarding');
select ok(
  has_function_privilege('authenticated',
    'public.complete_onboarding(text,text,date,text,text,jsonb,text,text[],text[],text[])',
    'EXECUTE'),
  'authenticated được EXECUTE trên complete_onboarding');

-- Bước taste đòi consent matching + cross_border (0005_consent_gate). Gửi
-- matching=false để bước CUỐI nổ sau khi bước ĐẦU đã ghi profile.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000b1"}';
select throws_ok(
  $$ select public.complete_onboarding(
       'Mai', 'Tran Mai', '1995-01-01'::date, 'hi', 'vi',
       '{"location":true,"photos":true,"matching":false,"cross_border":true}'::jsonb,
       'v1', array['vpop'], array['my_tam'], array['s2']) $$,
  '23514', null, 'thiếu consent matching → hàm raise');
reset role;

set local role postgres;
select is_empty(
  $$ select 1 from public.profiles
     where id = '00000000-0000-0000-0000-0000000000b1' $$,
  'ROLLBACK: bước taste nổ thì profile ghi trước đó KHÔNG còn');
reset role;

-- Happy path: một lời gọi ghi đủ profile + consent + taste.
set local role authenticated;
set local "request.jwt.claims" = '{"sub":"00000000-0000-0000-0000-0000000000b2"}';
select lives_ok(
  $$ select public.complete_onboarding(
       'Linh', 'Le Linh', '1995-01-01'::date, 'hi', 'vi',
       '{"location":true,"photos":true,"matching":true,"cross_border":true}'::jsonb,
       'v1', array['vpop'], array['my_tam'], array['s2']) $$,
  'đủ consent → ghi trọn profile + consent + taste trong một lượt');
reset role;

select * from finish();
rollback;
