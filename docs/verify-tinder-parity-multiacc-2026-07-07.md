# Cùng Hát — Tinder-parity MULTI-ACCOUNT verify (2 emulator, 2026-07-07)

**Branch/commit under test:** `feat/pro-keo-gating` @ `2cd932e6` (đã verify 1-tài-khoản trong
`docs/verify-tinder-parity-2026-07-07.md` — bản này bổ sung các hành vi **2 chiều/cross-account**:
prompts hiển thị trên máy người khác, match flow 2 bên, pill lượt-chat 2 chiều, realtime chat).
**App package:** `dev.cunghat.cung_hat` (DEBUG banner trong mọi screenshot).
**Backend:** local Supabase (`supabase_db_cung-hat`).
**Screenshots:** `docs/screenshots/tinder-parity/multiacc-01 … multiacc-20`.

## Preamble — DB state khác brief gốc (điều chỉnh có phê duyệt)

Brief gốc của điều phối viên giả định tồn tại tài khoản "Test B" (`900000002`) / "Test C"
(`900000003`), match sẵn A↔C và block B→A — **các dữ liệu đó KHÔNG còn tồn tại** trong DB hiện tại
(chúng thuộc phiên verify 2026-07-04, seed đã được thay bằng bộ QA sau một lần db reset). Kiểm chứng
trước khi chạy: `900000002` = **QA Linh Ballad**, `900000003` = QA Nam Rap; không có match nào của
Minh; block duy nhất là QA Vy → QA Hân (không liên quan). Đã báo cáo BLOCKED và điều phối viên
quyết định **Option 2: chạy lại matrix trên bộ tài khoản QA seed thật** — phiên này thực hiện đúng
quyết định đó. Không tự ý bịa/seed lại tài khoản Test B/C.

## Mapping tài khoản / emulator

| Vai | Emulator | AVD | Phone (nhập) | UUID | Ghi chú |
|-----|----------|-----|--------------|------|---------|
| **A** | `emulator-5554` | `cunghat_test` | `900000001` | `0462e321-daad-4a01-b460-a95647634617` (Minh) | dogfood, 2 ảnh, 0 swipe/0 match đầu phiên |
| **L** | `emulator-5556` | `cunghat_test2` | `900000002` | `90000000-0000-4000-8000-000000000002` (QA Linh Ballad) | 2 ảnh, genres ballad+vpop, **đã like Minh từ 2026-07-05** (row này phải sống sót sau cleanup), đủ 4 consent → vào thẳng home |

Thiết bị thật Realme `2783ff85` có cắm máy nhưng **không đụng tới** (đúng quy định).

## Config OTP + restart Supabase (Step 0 — bắt buộc)

`supabase/config.toml [auth.sms.test_otp]` ban đầu chỉ có `84900000001`. Đã làm đúng quy trình:

1. Thêm `84900000002 = "123456"` vào config.toml.
2. `export SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN=localdummytoken` (bắt buộc, thiếu là `start` fail).
3. `npx supabase stop` → `npx supabase start` (config chỉ reload qua stop→start; data giữ trong docker volume).
4. Kiểm tra: 10 container healthy; `select count(*) from profiles` = 10 (data nguyên vẹn);
   `docker exec supabase_auth_cung-hat env | grep TEST_OTP` → `84900000001:123456,84900000002:123456` ✅.
5. `git checkout -- supabase/config.toml` — file sạch ngay sau đó (`git diff` trống, đã re-check cuối phiên).
   Runtime giữ config đã load cho tới lần restart kế tiếp.

## Ghi chú build/APK (lệch giả định, đã xử lý)

APK sẵn có `build/app/outputs/flutter-apk/app-debug.apk` (mtime hôm nay) hoá ra được build bằng
`env/dev.device.json` (SUPABASE_URL=`http://127.0.0.1:54321` — bản build cuối của phiên trước là bản
cho ĐIỆN THOẠI THẬT), không phải `dev.emulator.json` (`10.0.2.2`). Lần OTP đầu fail
`Connection refused 127.0.0.1:54321`. **Không rebuild** — dùng đúng cơ chế của verify device trước:
`adb -s <serial> reverse tcp:54321 tcp:54321` trên CẢ 2 emulator → mọi call `127.0.0.1:54321` trong
emulator forward về host. Hoạt động ổn định suốt phiên. (Anon key 2 env giống nhau nên không lệch auth.)

## Kết quả matrix

| Bước | Hành động | Kết quả | Screenshot | Verdict |
|------|-----------|---------|-----------|---------|
| 1a | Boot 2 emulator headless (5554/5556), cài APK, login A `900000001`/OTP `123456` | A vào thẳng deck Đôi; card đầu tiên chính là **QA Linh Ballad** (cô ấy đã like Minh → ranking đẩy lên đầu) | `multiacc-01-A-home.png` | ✅ |
| 1b | Login L `900000002`/`123456` trên 5556 | OTP screen "Mã đã gửi tới +84900000002" (test_otp mới nhận sau restart) → vào thẳng home (đủ consent, không qua onboarding), deck hiện QA An KPop | `multiacc-02-L-home.png` | ✅ |
| 2 | **L đặt prompts (T6 editor):** Hồ sơ → Thẻ hỏi-đáp → trả lời p2 "Thể loại mình hát khi buồn…" = `Ballad khi troi mua`, p5 "Điểm 10 của mình khi cầm mic…" = `Giong cao khong can beat` → Lưu → mở lại | Sheet 6 câu render đúng; sau Lưu completion **45% → 60%**; mở lại thấy đúng 2 câu đã lưu (highlight), 4 câu còn lại trống; DB: 2 row `profile_prompts` (p2 pos 0, p5 pos 1) | `multiacc-03-L-prompts-editor.png`, `multiacc-04-L-prompts-persisted.png` | ✅ |
| 3a | **Khám Phá board (T9) trên A** (trước mọi swipe) | 5 theme card + live count: Đêm Ballad 🌙 **3 người**, Hội Rap 🔥 1, Bolero chill 🍵 1, Đêm K-Pop ✨ 1, V-Pop party 🎉 2 | `multiacc-05-A-theme-board.png` | ✅ |
| 3b | Vào deck **Đêm Ballad** | **KHÔNG crash emulator** (khác hẳn phiên 1-account: crash 3/3 lần trên emulator chạy lâu). Deck genre render đúng: header "Đêm Ballad / Chậm rãi, tình cảm" + nút back + refresh, **không** có boost/explore icon; card đầu = QA Linh Ballad ảnh 1, chip "Cách 5+ km" + "cùng 2 bài tủ" | `multiacc-06-A-ballad-deck-photo1.png` | ✅ (giải toả blocker T9 phiên trước) |
| 3c | **Chip rotation trên card thật của L (T3):** tap nửa phải ảnh | Sang ảnh 2 ("Linh 2"), dot chuyển, hàng chip đổi theo index ảnh (ảnh 2 = dòng thể loại "Chưa chung thể loại nào" — đúng vì Minh chưa chọn genre nào) | `multiacc-07-A-ballad-linh-photo2.png` | ✅ |
| 3d | ⓘ → detail sheet của L trên máy A — **T6 cross-account** | Sheet đủ: carousel ảnh (vuốt được → ảnh 2, xem 3e), "Gu nhạc chung", "Bài tủ chung: s2 · s5", và **2 thẻ prompt của L vừa lưu từ máy kia** ("Thể loại mình hát khi buồn… / Ballad khi troi mua", "Điểm 10 của mình khi cầm mic… / Giong cao khong can beat") + nút Bỏ qua/Thích + Báo cáo/Chặn | `multiacc-08-A-linh-detail-prompts.png` | ✅ **đường prompts xuyên tài khoản chứng minh trọn vẹn** |
| 3e | Vuốt carousel trong sheet | Sang "Linh 2", dot 2 active | `multiacc-09-A-linh-detail-carousel2.png` | ✅ |
| 4 | Fallback QA An KPop prompts | **Không cần** — 3d đã pass | — | (bỏ qua theo kế hoạch) |
| 5a | **Match flow (T8):** trên MAIN deck của A, card Linh đứng đầu sẵn → bấm nút TIM (đúng **1 right-swipe duy nhất** được phép của A) | **MatchCelebration**: "Hợp cạ rồi! Bạn và QA Linh Ballad đã thích nhau", monogram M ♥ Q, chip "Cùng tủ: s2 · s5"; DB: match `95c40f78` active + đúng 1 swipe like của A | `multiacc-10-A-match-celebration.png` | ✅ |
| 5b | "Nhắn tin ngay" → chat mở → back KHÔNG gửi | Chat screen header "QA Linh Ballad" + "Lập kèo", empty state "Chưa có tin nhắn. Rủ nhau bằng một bài tủ đi." | `multiacc-11-A-chat-from-celebration.png` | ✅ |
| 5c | Pill **"Nhắn trước đi"** 2 phía (match mới, 0 tin nhắn) | A inbox: tile "QA Linh Ballad" + pill; L inbox: tile "Minh" + pill (xuất hiện không cần thao tác gì thêm) — tile "QA Vy Bolero" của L cũng pill này (match cũ chưa ai nhắn, đúng logic) | `multiacc-12-A-inbox-nhan-truoc-di.png`, `multiacc-13-L-inbox-nhan-truoc-di.png` | ✅ |
| 5d | L gửi `Toi nay hat khong?` | Bubble gửi hiển thị bên L; DB messages +1 (sender = L) | `multiacc-14-L-sent-msg1.png` | ✅ |
| 5e | A inbox: pill **"Đến lượt bạn"** + badge chưa đọc | Thấy sau khi **restart app A** (xem ⚠️-1): tile "QA Linh Ballad" + pill "Đến lượt bạn" + badge đỏ **1** | `multiacc-15-A-inbox-den-luot-ban.png` | ✅ (kèm ⚠️-1) |
| 5f | A mở chat (đánh dấu đọc) → thấy tin của L → trả lời `Di luon!` | Tin L hiện bubble trái; reply A gửi thành công bubble phải | `multiacc-16-A-chat-received.png`, `multiacc-17-A-replied.png` | ✅ |
| 5g | **Realtime 2 chiều** (yêu cầu thêm của điều phối viên): (i) reply `Di luon!` của A hiện **live** trong chat đang mở của L; (ii) L gửi `Chot 20h nhe` trong khi chat A đang MỞ → hiện live bên A, không reload | Cả 2 chiều đều hiện tức thì (≤4s, không thao tác refresh nào) | `multiacc-18-A-realtime-receive.png` (chiều L→A; chiều A→L quan sát trực tiếp cùng cơ chế) | ✅ |
| 5h | A gửi `Ok chot` (để chốt trạng thái A-nhắn-cuối) → back về inbox | Tile A **không pill**, subtitle mặc định "Sẵn sàng rủ đi hát" (A là người nhắn cuối) — inbox tự refetch nhờ invalidate-khi-quay-lại-từ-chat (by design) | `multiacc-19-A-inbox-no-pill.png` | ✅ |
| 5i | L back về inbox | Tile "Minh" pill **"Đến lượt bạn"** (A nhắn cuối → tới lượt L); không badge (L đã xem tin trong chat đang mở) | `multiacc-20-L-inbox-den-luot-ban.png` | ✅ |
| 6 | Interleave promo kèo (T4) | **Không gặp** — phiên này A không left-swipe lần nào (Linh đứng đầu deck sẵn), nên không tới ngưỡng chèn promo. Đã verify đầy đủ ở phiên 1-account. | — | (không áp dụng) |
| 7 | Logcat sanity 2 emulator | Chỉ có dòng benign quen thuộc `Push init skipped: … FirebaseOptions` (Firebase không cấu hình ở local dev, có từ trước). **0 error/exception Flutter khác** trên cả 2 máy | — | ✅ |

**Tổng: 16/16 mục thực hiện đều PASS** (1 mục bỏ qua có chủ đích vì mục chính đã pass, 1 mục không
áp dụng vì không phát sinh left-swipe).

## ⚠️ Ghi chú quan sát (không phải regression của batch)

1. **⚠️-1 Inbox không tự refetch khi đổi tab / pull-refresh:** `inboxProvider` là `FutureProvider`
   thường (fetch 1 lần), chỉ `ref.invalidate` khi quay lại từ màn chat (`inbox_screen.dart:76`);
   màn inbox không có RefreshIndicator và không subscribe realtime. Hệ quả: pill "Đến lượt bạn" +
   badge chưa đọc KHÔNG hiện nếu user đứng yên ở tab Chat khi tin đến — phải mở app lại / vào-ra một
   chat. Trong test phải restart app A để chụp 5e. Realtime **trong màn chat** thì hoạt động tốt
   (5g). Đề xuất cân nhắc: invalidate inbox khi tab Chat được focus, hoặc subscribe stream. Đây là
   hành vi có sẵn của inbox, không phải lỗi mới của batch tinder-parity.
2. **Genre-deck crash phiên trước KHÔNG tái hiện:** trên emulator boot mới (phiên ngắn), vào deck
   Đêm Ballad hoạt động bình thường ngay lần đầu. Củng cố giả thuyết "WHPX/swiftshader bất ổn theo
   phiên emulator chạy dài" của Known issue #1 (verify 1-account) — không phải bug app. Task nền
   `task_3b925fe2` coi như có thêm dữ kiện xác nhận.
3. **APK env lệch giả định** (device-env thay vì emulator-env): xử lý bằng `adb reverse`, ghi rõ ở
   mục Build/APK phía trên. Lần sau muốn test emulator thuần thì rebuild với `env/dev.emulator.json`.
4. Text nhập qua adb không gõ được dấu tiếng Việt → nội dung prompt/tin nhắn dùng ASCII không dấu
   (giống phiên 1-account). Không ảnh hưởng logic.

## DB prep + cleanup log

**VERIFY_START = `2026-07-06 10:04:16.955343+00`** (giờ DB, `select now()` trước mọi thao tác ghi).

Prep: **không cần seed/sửa dữ liệu gì** — khác brief gốc, không có block nào phải gỡ/chèn lại
(block duy nhất trong DB là QA Vy → QA Hân, không liên quan Minh, giữ nguyên không đụng).
Vị trí L có sẵn (HN `POINT(105.885 20.984)`, cách A ~5 km).

Phát sinh trong test (tất cả sau VERIFY_START):
- 1 swipe like `A → L` (10:17:59)
- 1 match `95c40f78` (A↔L) + 2 row `message_reads`
- 4 messages trong thread match đó: L `Toi nay hat khong?`, A `Di luon!`, L `Chot 20h nhe`, A `Ok chot`

Cleanup đã chạy (thứ tự: message_reads → messages → match → swipes) và **verify từng mục**:

| Kiểm tra sau cleanup | Kỳ vọng | Thực tế |
|----------------------|---------|---------|
| Swipes của A sau VERIFY_START | 0 | 0 ✅ |
| Swipes của A tổng | 0 (như đầu phiên) | 0 ✅ |
| **Like gốc của L → A (2026-07-05, PRE-verify)** | 1 (phải sống sót) | 1 ✅ |
| Swipes của L sau VERIFY_START | 0 | 0 ✅ |
| Matches tổng | 1 (chỉ Linh↔Vy cũ) | 1 ✅ |
| Matches dính A | 0 | 0 ✅ |
| Messages sau VERIFY_START (toàn DB) | 0 | 0 ✅ |
| **Prompts của L (GIỮ theo kế hoạch)** | 2 | 2 ✅ |
| Blocks tổng (Vy→Hân cũ, không đụng) | 1 | 1 ✅ |

- **GIỮ LẠI có chủ đích:** 2 prompts của QA Linh (dữ liệu test hữu ích, đẹp cho deck).
- 2 emulator đã kill (`adb emu kill` OK, `adb devices` chỉ còn thiết bị thật — không đụng).
- `supabase/config.toml`: `git diff` trống (đã revert từ Step 0, re-check cuối phiên).
- Supabase local để chạy tiếp (trạng thái sau restart là chủ đích — runtime đang giữ 2 số test OTP).
- KHÔNG chạy `supabase db reset`; không sửa function/schema nào; không mua/boost gì.

## Screenshot

Tất cả ở `docs/screenshots/tinder-parity/`:
`multiacc-01-A-home.png`, `multiacc-02-L-home.png`, `multiacc-03-L-prompts-editor.png`,
`multiacc-04-L-prompts-persisted.png`, `multiacc-05-A-theme-board.png`,
`multiacc-06-A-ballad-deck-photo1.png`, `multiacc-07-A-ballad-linh-photo2.png`,
`multiacc-08-A-linh-detail-prompts.png`, `multiacc-09-A-linh-detail-carousel2.png`,
`multiacc-10-A-match-celebration.png`, `multiacc-11-A-chat-from-celebration.png`,
`multiacc-12-A-inbox-nhan-truoc-di.png`, `multiacc-13-L-inbox-nhan-truoc-di.png`,
`multiacc-14-L-sent-msg1.png`, `multiacc-15-A-inbox-den-luot-ban.png`,
`multiacc-16-A-chat-received.png`, `multiacc-17-A-replied.png`,
`multiacc-18-A-realtime-receive.png`, `multiacc-19-A-inbox-no-pill.png`,
`multiacc-20-L-inbox-den-luot-ban.png`.
(24 file rác `_check-*.png` phục vụ điều hướng đã xoá — chỉ commit 20 artifact cuối.)
