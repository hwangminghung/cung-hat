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
