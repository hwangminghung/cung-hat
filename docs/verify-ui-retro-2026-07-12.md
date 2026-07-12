# Verify đợt UI retro mixtape — 2026-07-12

Nhánh `feat/ui-retro` (từ master 22b35892). Nội dung đợt: Phase 1 design tokens + fix CTA (2 commit) · 21 commit Codex redesign (shared components, auth, onboarding, discovery, kèo) · 5 task plan `2026-07-11-ui-retro-remaining.md` (inbox section, PRO badge, plan v1 flag, sweep+MASTER.md, verify) · 1 bug fix thiết bị thật (KeoCard).

## Gates cuối

| Gate | Kết quả |
|---|---|
| flutter analyze | ✅ 0 issue |
| flutter test | ✅ **326/326 pass** |
| Final holistic review (đọc code thật, trọng tâm 21 commit Codex) | ✅ READY-TO-MERGE, 0 issue |
| Phạm vi diff | ✅ chỉ presentation/l10n/test/fonts/docs — không đụng application/data/domain/supabase |
| Keys hiện có | ✅ không key nào bị xoá/đổi |

## 🐛 Bug CHẶN tìm được nhờ verify thiết bị thật (widget test không bắt được)

**KeoCard `Row(crossAxisAlignment: stretch)` trong ListView → toàn bộ tab Kèo TRẮNG TRƠN khi board có kèo.**
- Hiện tượng: body tab Kèo không vẽ gì (cả header/banner) khi có ≥1 kèo có time window; board rỗng thì hiển thị bình thường. Không có exception trong logcat.
- Chẩn đoán: render-tree dump qua VM service → `RenderSliverList geometry: null`, `RenderStack size: MISSING` tại TicketCard → layout chết vì `stretch` nhận height vô hạn từ ListView item ("BoxConstraints forces an infinite height", tái hiện được bằng regression test).
- Vì sao test Codex không bắt: Keo mock trong test không có timeWindowStart/End → đi nhánh Column (không stretch). Ngoài ra `find.text` pass kể cả khi paint hỏng.
- Fix: bọc `IntrinsicHeight` (commit `a14d0025`) + regression test pump KeoCard-có-giờ trong ListView.
- Đã quét toàn repo: không còn `CrossAxisAlignment.stretch` nào trên Row trong scrollable dọc.

## Walkthrough emulator (cunghat_test3, tài khoản Minh 900000001)

| Màn | Mockup | Kết quả |
|---|---|---|
| Đôi deck | 07 | ✅ 4 nút CÓ NHÃN (Quay lại/Bỏ qua/Siêu thích/Thích), màu đúng hệ (lime/kem/teal/cam), card viền ink, chips khoảng cách + bài tủ |
| Kèo board | 11 | ✅ (sau fix) TicketCard mép khoét + đục lỗ dashed, cột giờ trái, chip "Cần duyệt" teal, genre chips, banner lime "Ghép nhóm cho tôi" |
| Chat inbox | 15 | ✅ Section "Tin nhắn đôi"; pill trạng thái sẵn có từ trước |
| Hồ sơ | 18 | ✅ Badge PRO lime cạnh "Ai đã thích bạn"; completeness card |
| Login/OTP/Settings/Store | 01/02/21/22 | ✅ Theme retro ăn toàn phần (đã chụp các phiên trước); OTP resend countdown có test cover |
| Plan v1 | 20 | ✅ qua widget test (Chỉ đường hiện, "Đặt phòng" vắng khi BOOKING_ENABLED off — mặc định) — chưa walkthrough live (cần kèo confirmed + plan; hạ tầng test data không đổi) |

Screenshots: `docs/verify-screenshots-ui-retro/` (deck, keo board sau fix, inbox, profile).

## DEFERRED (có chủ đích)

1. **Inbox section "Kèo của bạn"** (mockup 15): cần RPC `get_my_keos` backend chưa có → đợt sau.
2. **Monogram deck card dùng palette avatar cũ** (đỏ đô/xanh đậm) — lệch nhẹ tông retro; card có ảnh không ảnh hưởng. Polish sau.
3. Hard shadow offset(3,3) chưa áp cho mọi component Material (Card dùng shadowColor thường) — TicketCard/GradientButton/banner đã đúng.
4. Onboarding live walkthrough chưa chạy (tài khoản có sẵn profile bỏ qua onboarding) — 4 bước cover bằng widget test (consent grant-on-continue có test `consent_gate_test.dart`).
5. Mojibake 1 row kèo cũ trong DB local ("QA k?o karaoke t?i mai" — status planning, không hiện board) — data test cũ, không liên quan đợt này.

## Ghi chú vận hành verify

- APK PHẢI build với `--dart-define-from-file=env/dev.emulator.json` (env bị gitignore — copy từ repo gốc vào worktree, đã copy sẵn).
- Kèo seed hết hạn theo thời gian thực → muốn board có kèo: `update public.keo set time_window_start = now() + interval '7 hours', time_window_end = now() + interval '9 hours' where status='open';`
- Debug màn trắng không exception: dump render tree qua VM service HTTP `http://127.0.0.1:<port>/<token>/ext.flutter.debugDumpRenderTree?isolateId=<id>` (adb forward) — tìm `geometry: null`/`size: MISSING`.

## Polish đợt 2 (cùng ngày) — khớp bố cục mockup sau phản hồi user "nhiều chỗ chưa giống"

Plan: `docs/superpowers/plans/2026-07-12-ui-retro-polish.md` (P1-P5, subagent-driven + 2-stage review).

| Task | Nội dung | Commit | Review |
|---|---|---|---|
| P1 | Hồ sơ mockup 18: hero kem + avatar viền ink, **WaveProgress** meter waveform, gear header, icon ô ink | 5fa9e6be + c75f8110 | APPROVED (fix bug biên progress=0 + test 0.0/1.0) |
| P2 | Inbox mockup 15: avatar vuông 64 viền ink, pill lime turn_pill, WaveDivider giữa hàng | 69895e99 | APPROVED (giữ Key turn_pill, off-by-one divider verified) |
| P3 | Deck mockup 07: hàng "Online hôm nay" + chips #genre teal, monogram palette retro, waveform tiêu đề | 9939698d + 14587842 | APPROVED (fix contrast chữ trên tertiaryPop/pink → ink) |
| P4 | Logo CH badge + WaveDivider keo board/settings/store | c8a05797 | APPROVED (deviation bỏ height cố định logo — verified hợp lý) |

Gates cuối polish: **334/334 test + analyze 0**. Emulator: 4 screenshot mới `polish-*.png` — Hồ sơ/Inbox/Deck/Kèo board đều khớp bố cục mockup tương ứng.

Deferred thêm: badge unread + timestamp cột phải inbox (MatchSummary chưa có field thời gian — cần backend); chips #genre trên deck chỉ hiện khi candidate có sharedGenres (QA seed phần lớn rỗng).

## Demo đa tài khoản 2 emulator (2026-07-13)

2 phiên đồng thời: **A = Minh** (cunghat_test3, emulator-5554) · **B = QA Linh Ballad** (cunghat_test2, emulator-5556, có Pro qua SQL). Screenshots `multiacc-*.png`.

| Luồng | Kết quả |
|---|---|
| Match mới qua `record_swipe` (Minh ↔ QA Phúc Rock) | ✅ hiện trong inbox A với pill "Nhắn trước đi" |
| Kèo mở: Minh join "Kèo demo tối nay" (host = B) qua UI | ✅ auto-approve, chip "Đã duyệt" teal, roster 2 người, detail TicketCard retro |
| Chat 1-1 realtime B → A | ✅ B gửi "Toi nay hat Uoc Gi nhe"; inbox A tự cập nhật pill lime "Đến lượt bạn" + badge cam "1" KHÔNG cần refresh |
| Chat 1-1 realtime A → B | ✅ A trả lời "Chot 20h nhe"; hiện trên màn B tức thì (B đang mở chat) |

Giới hạn ghi nhận: B (host) không có đường UI vào kèo mình tạo (inbox "Kèo của bạn" cần RPC `get_my_keos` — deferred #1) nên chưa demo chat nhóm; ~~nút "Đồng ý tham gia" trên A tap không thấy phản hồi UI~~ **ĐÍNH CHÍNH 2026-07-13: nút hoạt động ĐÚNG** (keo_members.confirmed=t, kèo chuyển status planning) — vấn đề thật là nút không đổi trạng thái hiển thị sau confirm (xem mục so khớp mockup bên dưới).
Gotcha thao tác: `adb shell input text` phải escape space bằng `%s`, không thì chuỗi bị cắt ở từ đầu tiên.

## So khớp mockup toàn diện (2026-07-13, walkthrough 2 emulator)

Đối chiếu từng màn live với 22 mockup. Screenshots `cmp_*.png` (scratchpad phiên làm việc; các màn chính đã có bản commit ở `polish-*.png`/`multiacc-*.png`).

| Mockup | Màn | Verdict |
|---|---|---|
| 07 deck | Đôi hát | ✅ khớp — Online hôm nay + chip #vpop #ballad + "cùng 2 bài tủ" (số liệu xác minh đúng theo DB), 4 nút có nhãn |
| 08 detail sheet | Sheet ứng viên | ✅ khớp cấu trúc (Gu nhạc chung/Bài tủ chung/Bỏ qua-Thích/Báo cáo-Chặn); thiếu tính năng photo-prompt "Trả lời ảnh này"/"Trả lời" (ngoài phạm vi v1) |
| 09 match | Hợp cạ rồi! | ✅ khớp (2 card + chip "Cùng tủ: …" + CTA); thiếu cụm mic+waveform giữa màn (cosmetic) |
| 10 explore | Khám phá theo gu nhạc | ✅ khớp copy từng chữ + 5 theme card; decor emoji thay line-art |
| 11 board | Kèo quanh bạn | ✅ khớp bố cục ticket; thiếu dải avatar thành viên + tên quán trên card (quán vốn chốt sau ở Kế hoạch) |
| 12 auto-match | Kèo hợp với bạn | ✅ khớp + 4 chip lý do; **🐛 giờ hiện raw UTC** thay vì định dạng +7 như board |
| 13 create | Tạo kèo (B, Pro) | ✅ khớp (header, card "Chọn quán sau", 8 chip thể loại, Cần duyệt/Mở); free user thấy Pro-gate sheet (đúng nghiệp vụ) |
| 14 kèo detail | Chi tiết kèo | ⚠️ **thiếu hàng giờ + địa điểm trong ticket header** (mockup có 3 cột giờ/quán/số người); **🐛 nút "Đồng ý tham gia" không đổi trạng thái sau confirm** (mockup dùng chip "Đã xác nhận") |
| 15 inbox | Tin nhắn | ✅ rows khớp (avatar vuông, pill, wave, badge unread cam); thiếu section "Kèo của bạn" (get_my_keos) + timestamp cột phải (backend) — deferred đã ghi |
| 16 chat 1-1 | Chat | ✅ bubble cam/kem + Lập kèo; thiếu avatar+chấm online trên header và card share bài hát (thuộc khối chat-media chưa merge) |
| 17 group chat | Chat nhóm | ✅ khung + banner Luật nhóm; thiếu subtitle tên kèo + nút thành viên góc phải |
| 18 profile | Hồ sơ | ✅ khớp (5 tile đúng thứ tự, PRO badge, WaveProgress, gear) |
| 19 plan | Kế hoạch | ✅ cấu trúc (map pins + venue card + dòng "Gợi ý vì gần điểm cân bằng…"); tile map chờ Maps billing; "Chọn quán này" chỉ host (đúng); chưa thấy chip "Điểm giữa nhóm" |
| 20 booking | — | ✅ ẨN đúng chủ đích (BOOKING_ENABLED=false, quyết định v1) |
| 21 store | Nâng cấp | ✅ nội dung khớp 100% (4 gói + giá 199k/49k/99k/79k + mô tả); hero style khác nhẹ |
| 22 settings | Cài đặt | ✅ khớp 4 section + toggle lime; thêm toggle PDPL Singapore (bắt buộc pháp lý) |
| 01-06 auth/onboarding | — | Theme đã verify phiên trước; onboarding live vẫn deferred (cần tài khoản mới) |

**Phát hiện sự cố UX xuyên suốt (nặng nhất):** kèo đã join/đã chuyển `planning` biến mất khỏi board (board chỉ hiện kèo `open` chưa tham gia) → cả host lẫn member mất mọi lối vào kèo của mình. Cần ưu tiên `get_my_keos` + section "Kèo của bạn" (mockup 15) ngay đợt sau.

**Đính chính điều tra cũ:** nghi vấn "Bài tủ chung hiển thị sai" là BÁO ĐỘNG NHẦM — tôi tra nhầm ID QA seed (007 = Hân, không phải 003); RPC `get_discovery_candidates` tính giao bài tủ/genre ĐÚNG (xác minh bằng gọi RPC trực tiếp dưới JWT Minh).

**Data demo bổ sung hôm nay (DB local):** Minh thêm `user_genres` {ballad,vpop} + bài tủ s1 (trước đó Minh 0 genre → chip #genre không bao giờ hiện); xoá 4 swipe ma 15:44 UTC; kèo demo set lại `open` + gia hạn window.
