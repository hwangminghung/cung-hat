# Verify log — Đôi Ảnh hồ sơ + Carousel + Boost, 2026-07-04

## Verdict: PASS (emulator `cunghat_test`, APK debug thật, Supabase local)

**Scope:** plan `docs/superpowers/plans/2026-07-04-doi-photos-boost.md` (Task 1–8)
— ảnh hồ sơ multi (max 3) + carousel trên card & detail sheet, Boost là
quyền lợi Pro (1 lần/ngày, 30 phút), và 2 polish (khôi phục card khi swipe bị
server từ chối; note-rain precompute).

**Method:** rebuild APK debug local (workaround AF_UNIX
`JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=…`) → cài `emulator-5554` →
drive UI bằng vòng lặp `screencap → Read PNG → adb input tap/swipe` → seed/assert
dữ liệu qua `psql` trong container `supabase_db_cung-hat`. Ảnh test upload bằng
`service_role` qua Storage REST. Screenshot bằng chứng ở `docs/verify-screenshots/`.

## Đăng nhập + TESTUID

- **TESTUID = `0462e321-daad-4a01-b460-a95647634617`** (display_name "Minh",
  phone `84900000001`, vị trí Sài Gòn 10.776/106.7).
- **Cách login:** session đã persist sẵn trên emulator — app mở thẳng vào deck
  Đôi, không cần nhập OTP. (Test OTP có sẵn nếu cần: config.toml
  `[auth.sms.test_otp] 84900000001 = "123456"`.)
- **Seed a2** (`a0000000-0000-4000-8000-0000000000a2`, "Cùng Hát Sài Gòn", SG):
  tạo 2 JPEG 600×800 ("Anh 1" xanh, "Anh 2" đỏ) → upload service_role vào
  `profile-photos/a2/1.jpg,2.jpg` → `update profiles set photo_paths=…`. a2 ở
  0 m so với TESTUID nên vào deck sau khi xoá tạm swipe/match cũ.

## Lưu ý môi trường (đã xử lý, KHÔNG commit)

Edge runtime local nướng cứng `SUPABASE_URL=http://kong:8000`, nên signed URL
`sign-photo` trả về host `kong:8000` — emulator không resolve được (ảnh sẽ rơi
về monogram). Trong lúc verify đã **tạm** rewrite host trong
`supabase/functions/sign-photo/index.ts` sang `http://10.0.2.2:54321`
(host-reachable từ emulator; token signed là host-independent) + restart edge
runtime. **Đã revert về đúng bản commit và restart lại** ở bước cleanup — file
này không có trong commit. (Nếu sau này verify lại: cân nhắc override
`SUPABASE_URL` của edge runtime, hoặc chạy trên thiết bị thật qua reverse
tunnel.)

## Các cảnh đã PASS (6/6)

1. ✅ **Card hiện ẢNH thật + dots** — card a2 trong deck Đôi hiển thị ảnh "Anh 1"
   (không phải monogram) + 2 dots (dot đầu active). → `card-photos.png`
2. ✅ **Carousel detail sheet vuốt được** — tap card mở sheet, vuốt carousel sang
   **ảnh 2 ("Anh 2")**, dot thứ 2 active. → `sheet-carousel-2.png`
3. ✅ **Ảnh hồ sơ consent-gated** —
   - Consent `photos` bị thu hồi → mở "Ảnh hồ sơ" hiện CTA khoá
     "Bật trong Cài đặt" (không hiện slot). → `photos-consent-cta.png`
   - Vào Cài đặt bật switch "Lưu và hiển thị ảnh hồ sơ" (`consent_photos`) →
     quay lại → hiện **3 ô ảnh** (+camera). → `photos-3slots.png`
4. ✅ **Boost free → Pro upsell** — user free tap nút bolt header → sheet
   "Boost hồ sơ của bạn" ("Pro được 1 lần Boost 30 phút mỗi ngày…"). →
   `boost-upsell.png`
5. ✅ **Boost Pro → SnackBar + boosts row** — cấp Pro
   (`entitlements feature=pro source=promo`), restart app, tap bolt → SnackBar
   "Đang boost 30 phút — hồ sơ của bạn được ưu tiên quanh đây." + icon bolt
   chuyển màu primary. → `boost-snackbar.png`
   `boosts` row xác nhận:
   ```
   user_id                              | expires_at                    | time_left
   0462e321-daad-4a01-b460-a95647634617 | 2026-07-04 09:04:00.201365+00 | 00:29:36
   ```
   `rate_limits daily_boost` count=1 (đúng: 1 lần/ngày).
6. ✅ **Polish — card khôi phục khi like bị từ chối** — user FREE, seed
   `daily_like` count=30 (cap), tap ♥ → paywall "Hết lượt thích hôm nay" VÀ
   card a2 **quay lại deck** sau khi đóng paywall (khác verify trước — trước đây
   card bay đi mất). Swipe KHÔNG được ghi (server từ chối `like_limit`). →
   `paywall-card-restored.png`

## Findings

1. ℹ️ **Emulator segfault 1 lần** (`swiftshader_indirect`, exit 139) giữa chừng
   — reboot lại là xong, không phải lỗi app. App bị gỡ khi đó → cài lại APK.
2. ℹ️ **daily_like quota chỉ áp cho non-Pro** (đúng thiết kế, migration
   `20260703100000` dòng 14 `if … and not app_private.is_pro()`). Nên để verify
   state #6 phải thu Pro trước (Pro like không giới hạn). Đã xử lý đúng.
3. ℹ️ **psql heredoc qua Bash tool không nạp được `set_config`/DELETE tin cậy**
   trên máy này — chuyển hẳn sang `docker cp *.sql` + `psql -f` (PowerShell
   docker cp, tránh MSYS path mangling). Không ảnh hưởng kết quả.

## Suites cuối (gates)

- `supabase test db` → **PASS · Files=21, Tests=96** (chat_media_test vẫn
  `.pending` đúng chủ đích).
- `flutter test` → **137/137 PASS** (xem mục dưới nếu số khác).

## Dữ liệu test sau verify (đã cleanup)

- Thu hồi entitlement `pro` promo của TESTUID.
- Xoá `rate_limits` seed (`daily_like`, `daily_boost`).
- Xoá `boosts` row đã tạo.
- Consent `photos` để lại **granted** (đúng trạng thái trước verify).
- **GIỮ LẠI:** 2 ảnh a2 (`profile-photos/a2/1.jpg,2.jpg` + `photo_paths`) cho
  các verify sau; match TESTUID↔a2 + reciprocal like swipes (khôi phục lại như
  trước verify, dùng cho test chat).
- Revert `supabase/functions/sign-photo/index.ts` về bản commit + restart edge
  runtime.
