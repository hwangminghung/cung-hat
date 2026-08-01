-- [MATCH-AUDIT #3] Push khi có match mới.
--
-- Trước đây trigger push chỉ có cho tin nhắn / xin vào kèo / plan (0022):
-- người vuốt like trước không hề được báo khi đối phương vuốt lại — cú hích
-- quay-lại-app lớn nhất của thể loại app này bị bỏ trống, user chỉ biết khi
-- tự mở app.
--
-- AFTER INSERT là đủ: record_swipe tạo match qua INSERT ... ON CONFLICT DO
-- NOTHING — cặp đã có row (kể cả unmatched) thì không insert nên không bắn
-- lại; row unmatched không bao giờ được "hồi sinh" (xem block_sever) nên
-- không có đường push trùng cho cùng một cặp.
create or replace function app_private.on_match_push()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  perform app_private.notify_push(
    array[new.user_a, new.user_b],
    'new_match',
    jsonb_build_object('match_id', new.id));
  return new;
end; $$;

drop trigger if exists matches_push on public.matches;
create trigger matches_push after insert on public.matches
  for each row execute function app_private.on_match_push();
