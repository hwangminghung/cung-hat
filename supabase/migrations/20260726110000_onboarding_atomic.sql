-- [AUDIT P1-2] Onboarding phải NGUYÊN TỬ.
--
-- Trước đây client chạy 3 lượt mạng rời nhau: upsert_my_profile →
-- n× record_consent → upsert_my_taste. Rớt mạng ở giữa để lại tài khoản nửa
-- vời: row profiles ĐÃ tồn tại nên router coi như onboarding xong và thả user
-- vào app, trong khi consent thiếu (rủi ro PDPL) và taste rỗng (deck trắng) —
-- và không còn đường quay lại màn onboarding để sửa.
--
-- Gộp cả ba vào MỘT hàm plpgsql: thân hàm chạy trong một transaction, bước sau
-- nổ thì mọi bước trước bị rollback. Cố ý GỌI LẠI ba hàm cũ thay vì chép logic
-- để giữ nguyên hai cổng đã được kiểm chứng: chặn dưới 18 tuổi
-- (upsert_my_profile) và bắt buộc consent matching + cross_border trước khi ghi
-- taste (upsert_my_taste, migration 0005).
create or replace function public.complete_onboarding(
  p_display_name text,
  p_full_name text,
  p_dob date,
  p_bio text,
  p_language text,
  p_consents jsonb,
  p_policy_version text,
  p_genre_ids text[],
  p_artist_ids text[],
  p_song_ids text[]
) returns public.my_profile
language plpgsql security definer set search_path='' as $$
declare
  result public.my_profile;
  k text;
  v text;
begin
  -- Profile trước: cổng 18+ raise ngay, chưa kịp sinh side-effect nào.
  -- Gán bằng `:=` chứ KHÔNG `select ... into`: dạng select map theo CỘT nên
  -- nhét nguyên composite vào field đầu (id uuid) → 22P02.
  result := public.upsert_my_profile(
    p_display_name, p_full_name, p_dob, p_bio, p_language);

  -- Consent trước taste: upsert_my_taste đòi matching + cross_border đã granted.
  for k, v in select key, value from jsonb_each_text(coalesce(p_consents, '{}'::jsonb))
  loop
    perform public.record_consent(k, v::boolean, p_policy_version);
  end loop;

  perform public.upsert_my_taste(p_genre_ids, p_artist_ids, p_song_ids);
  return result;
end; $$;

-- Cùng khuôn khoá quyền như các RPC onboarding khác: chỉ user đã đăng nhập.
revoke execute on function public.complete_onboarding(
  text,text,date,text,text,jsonb,text,text[],text[],text[]) from public, anon;
grant execute on function public.complete_onboarding(
  text,text,date,text,text,jsonb,text,text[],text[],text[]) to authenticated;
