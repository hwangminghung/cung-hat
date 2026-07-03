# Verify log — Đôi tab Tinder-quality upgrade, 2026-07-04

## Verdict: PASS (emulator, APK debug thật, Supabase local)

**Scope:** plan `docs/superpowers/plans/2026-07-03-doi-tinder-upgrade.md` (Task 1–7)
— swipe overlays, action bar, quota DB, paywall, rewind Pro, detail sheet,
match celebration v2 — theo design system `design-system/MASTER.md`.

**Method:** build local (workaround AF_UNIX) → cài `emulator-5554` → drive bằng
adb (tap/motionevent giữ giữa cú kéo) + screencap; seed/asert dữ liệu qua psql
trong container. Screenshot t01–t22 tại scratchpad phiên làm việc.

## Các cảnh đã PASS

1. ✅ **Overlay theo ngón tay** — kéo phải giữa chừng: card xoay theo hướng kéo,
   stamp **THÍCH** viền success mờ dần theo tiến độ; nhả dưới ngưỡng card về giữa.
2. ✅ **Action bar** — 4 nút tròn rewind/X/★/♥; rewind mờ 0.45 khi user free,
   full opacity khi Pro.
3. ✅ **Detail sheet** — tap card mở sheet: monogram gradient, "Tên, tuổi",
   band khoảng cách, empty-safe copy gu nhạc/bài tủ, nút Bỏ qua/Thích, Báo cáo/Chặn.
4. ✅ **Rewind free → ProUpsellSheet** "Rút lại lượt vuốt?".
5. ✅ **Quota like server-side** — seed 30 `daily_like` → tap ♥ → paywall
   "Hết lượt thích hôm nay" (like KHÔNG được ghi vào swipes — xác nhận SQL).
6. ✅ **Match celebration v2** — mutual like: full-screen gradient, 2 bong bóng
   monogram M♥C, "Hợp cạ rồi!", mưa nốt nhạc; **Nhắn tin ngay** vào đúng
   ChatScreen của match (get_match_id_with).
7. ✅ **Pro rewind end-to-end** — pass card → tap rewind → server xoá swipe
   (xác nhận SQL) + card quay lại đầu deck.
8. ✅ **Super-like quota** — Pro seed 5 `daily_super` → super bị chặn, không ghi.
9. ✅ **Deck exhaust-recovery** (bug tìm thấy TRONG lúc verify, đã fix cùng đợt) —
   xem Findings #1.

## Findings

1. 🐛→✅ **CardSwiper reuse giữ index cạn sau khi vuốt hết deck + refetch** —
   list mới fetch về không hiển thị (màn trống, chỉ header + action bar); phải
   đổi tab mới hồi. Bug TIỀM ẨN từ P1 (pattern onEnd+invalidate), lộ rõ khi có
   action bar. **Fix:** `key: ObjectKey(candidates)` trên CardSwiper — mỗi lần
   fetch dựng swiper mới. Đã tái hiện đúng kịch bản (quota chặn ghi → exhaust →
   refetch non-empty) và xác nhận hết stuck.
2. ⚠️ **Swipe optimistic khi server từ chối** — card vẫn bay đi về mặt UI dù
   record_swipe bị quota chặn (dữ liệu đúng — không ghi; chỉ UI đi trước).
   Người dùng mở lại/refetch sẽ thấy lại card. Polish sau: khôi phục card ngay
   khi RPC lỗi (controller.undo() trong catch) — cân nhắc vì đụng animation.
3. ⚠️ **Perf nốt nhạc match celebration** — `_NoteRainPainter` layout 18
   TextPainter mỗi frame (~1.4s). Bounded, không giật cảm nhận được trên
   emulator; follow-up: precompute position/size một lần.
4. ℹ️ Quota "ngày" = cửa sổ UTC (reset 7h sáng VN) — hành vi của
   `enforce_rate_limit` sẵn có; cần xác nhận ý đồ sản phẩm trước launch.

## Suites cuối

- `flutter analyze` sạch · `flutter test` **122/122** · `supabase test db`
  **85 pgTAP PASS** (chat_media_test vẫn `.pending` đúng chủ đích).

## Dữ liệu test sau verify (đã cleanup)

Seed hosts a1/a3 trả về vị trí gốc (HN/TN); xoá rate_limits seed; thu hồi
entitlement `pro` promo của user test. GIỮ LẠI: match user↔a2 (dùng test chat),
swipe super→a2 đã xoá từ trước.
