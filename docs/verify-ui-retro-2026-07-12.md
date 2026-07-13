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
| 12 auto-match | Kèo hợp với bạn | ✅ khớp + 4 chip lý do; ~~🐛 giờ raw UTC~~ **ĐÃ FIX** (giờ local, `fix-automatch-local-time.png`) |
| 13 create | Tạo kèo (B, Pro) | ✅ khớp (header, card "Chọn quán sau", 8 chip thể loại, Cần duyệt/Mở); free user thấy Pro-gate sheet (đúng nghiệp vụ) |
| 14 kèo detail | Chi tiết kèo | ✅ **ĐÃ FIX cả 2** (2026-07-13): ticket header thêm giờ (toLocal) + khu vực qua RPC mới `get_keo_header`; roster chip "Đã xác nhận" + nút teal disabled "Đã xác nhận tham gia" khi confirmed (`fix-keo-detail-header-confirmed.png`) |
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

## Đợt fix pre-merge (2026-07-13) — plan `2026-07-13-fix-mockup-gaps.md`

3 lỗi từ bảng so khớp đã fix và verify live trên emulator:
1. **F1** commit `match sheet gio local`: `_formatTimeWindow` toLocal, bỏ hậu tố UTC; test expected tính động theo TZ máy (không hardcode — CI khác TZ).
2. **F2+F3** commit `chi tiet keo hien gio+khu vuc, nut confirm doi trang thai`: migration `20260713120000` (roster + confirmed, RPC `get_keo_header`), model/repo/provider, UI header + trạng thái confirm, pgTAP `keo_header_test.sql`.

Gates: **analyze 0 · Flutter 336/336 · pgTAP 206/206** (41 file, +6 case mới). Migration đã áp vào DB local đang chạy (drop/alter type/recreate OK). Emulator: header kèo demo hiện `08:01 – 10:01 · 13/7` + `Hoàn Kiếm, Hà Nội`; Minh chip "Đã xác nhận" + nút teal disabled; sheet auto-match hiện `07:58 - 09:58` khớp board.
Gotcha build ghi lại: `build_runner --build-filter` + `--delete-conflicting-outputs` XOÁ generated files ngoài filter (khôi phục bằng `git checkout --`); build APK từ shell phải export `JAVA_TOOL_OPTIONS` unixdomain workaround như memory.

## Đợt "Kèo của bạn" (2026-07-13, nhánh feat/my-keos-inbox) — plan `2026-07-13-my-keos-inbox.md`

Vá gap UX nặng nhất: RPC `get_my_keos` (migration `20260713150000`) + section "Kèo của bạn" đầu tab Chat (mockup 15). Gates: **analyze 0 · Flutter 339/339 · pgTAP 212/212** (42 file, +6 case `my_keos_test.sql`). Emulator: B (host QA Linh) thấy kèo mình tạo + chip "Chủ kèo" + tap vào detail đầy đủ (`mykeos-host-inbox.png`); A (Minh) thấy kèo joined "Đang mở · 2/4" + 2 kèo planning cũ mình host trước đây "mất tích" nay hiện lại (`mykeos-member-inbox.png`). Test cũ không stub provider mới vẫn pass nhờ degrade AsyncError→ẩn section.

## Kết luận điều tra ghost-swipe (2026-07-13, đóng chip task_d22edf1e)

**Không phải bug app/DB.** Bằng chứng: (1) bảng `swipes` RLS bật + **0 policy** → client không thể insert trực tiếp kể cả khi có grant; đường ghi duy nhất là `record_swipe` SECURITY DEFINER (tức swipe ma là UI swipe THẬT bị bơm input) hoặc psql/service_role; (2) giả thuyết cũ "không qua record_swipe vì không tạo match" SAI — timeline cho thấy lúc batch 15:44 UTC chạy thì reciprocal like của Phúc CHƯA tồn tại (tôi tạo tay 15:51) nên record_swipe không tạo match là ĐÚNG hành vi; (3) sau khi tắt tooling: **28h+ dùng nặng emulator, 0 swipe lạ** (row duy nhất 17:55 là cú Thích demo có chủ đích).

**Nguồn:** input bơm từ tooling test trên AVD cunghat_test3 — nghi phạm chính là **DroidRun portal a11y service** (chỉ cài trên máy A — trùng account bị ma; 2 batch đều quét NGUYÊN deck với nhịp ~1.2s = đúng tốc độ animation CardSwiper; account B máy không có portal thì chưa từng bị); phụ: `monkey` launcher (đã bỏ, dùng `am start`). Lưu ý: lần tắt a11y đầu bị MẤT khi emulator reboot → lần này set cả 2 khoá (`enabled_accessibility_services=""` + `accessibility_enabled=0`) **và uninstall com.mobilerun.portal** khỏi AVD.

**Việc còn theo dõi:** không — nếu tái phát khi không có tooling nào chạy thì mở lại với nghi phạm mới.

## Fix CI pgTAP — baseline grants (2026-07-13, nhánh fix/ci-pgtap-grants, chip task_82689167)

**Root cause thật (bug prod, không phải bug test):** DB dựng tươi từ migrations KHÔNG có table grant nào cho `authenticated`/`service_role` — local che khuất vì grants drift từ state cũ. Hậu quả trên deploy tươi: app đọc bảng trực tiếp (messages/plans/consents/reference) sập, edge functions cũng sập (service_role BYPASSRLS vẫn cần GRANT). 5 file pgTAP fail trên CI chỉ là triệu chứng.

**Fix:** migration `20260713170000_baseline_grants.sql` — grant SIUD all tables + sequences + default privileges cho `authenticated` + `service_role`; **anon chủ đích KHÔNG grant** (chưa đăng nhập không đọc bảng trực tiếp; RPC pre-login đều SECURITY DEFINER). RLS vẫn là lớp kiểm soát (bảng RLS-0-policy như `swipes` vẫn deny-all dù có grant).

**Bằng chứng:** repro local revoke 4 bảng → 5 file fail y hệt CI; áp migration → 212/212. CI run `29214175532` (nhánh fix/ci-pgtap-grants): **job db XANH lần đầu tiên từ merge audit-hardening** (1m51s) + job flutter xanh.

## Polish chat + board (2026-07-13, nhánh feat/chat-board-polish, stack trên fix/ci-pgtap-grants)

3 gap nhỏ từ bảng so khớp mockup 11/16/17:
1. **Chat nhóm (17):** subtitle tên kèo dưới "Chat nhóm" (RPC `get_keo_header` tái dùng, degrade ẩn khi lỗi) + tên người gửi màu tertiaryPop trên bubble người khác (map từ roster).
2. **Share bài tủ (16):** quy ước v1 body text prefix `'♪ '` (`♪ Title · Artist`) — không đổi schema, client cũ degrade thành text thường. Sheet "Gửi bài tủ" liệt kê đúng bài TỦ CỦA MÌNH (`get_my_taste`.baitu × songs), bubble render card nốt nhạc (`SongShareContent`) ở cả chat 1-1 lẫn nhóm.
3. **Board (11):** `keo_card` thêm `member_names text[]` (host trước, giới hạn 5) → card kèo hiện dải avatar monogram thành viên + số slot trống.

Fix kèm: `_GroupRulesBanner` đổi DecoratedBox → `Material` wrapper (assertion ink-splash do widget test đầu tiên của KeoChatScreen bắt được).

**Verify live 2 emulator:** board hiện strip Q+M+2 vòng trống (`polish3-board-member-strip.png`); Minh gửi "♪ Ước Gì · Mỹ Tâm" từ sheet → Linh nhận realtime card nốt nhạc + tên người gửi + subtitle tên kèo (`polish3-song-share-sent/received.png`, `polish3-groupchat-subtitle-sender.png`).

## Walkthrough onboarding live (2026-07-13, user tươi 84900000099 trên emulator B)

Mục 01-06 cuối cùng còn deferred — nay đã đi live đủ 4 bước bằng tài khoản mới hoàn toàn (test OTP tạm thời, đã revert config về 001-only sau khi xong):

| Bước | Mockup | Kết quả |
|---|---|---|
| Login + OTP | 01, 02 | ✅ khớp (đã verify từ phiên trước, lặp lại OK với số mới) |
| 1/4 Ngày sinh | 03 | ✅ khớp (wave progress, banner 18+, 3 ô Ngày/Tháng/Năm, date picker Material default 1/1/2000) — `ob-01`, `ob-02` |
| 2/4 Quyền riêng tư | 04 | ✅ khớp (5 mục, chip "Bắt buộc", toggle khuyến mãi OFF mặc định); consent lưu đúng — xem lại ở Cài đặt sau khi hoàn tất | 
| 3/4 Thiết lập hồ sơ | 05 | ✅ khớp (card monogram + preview chữ cái theo tên gõ vào, 2 field) — `ob-04` |
| 4/4 Gu nhạc | 06 | ✅ khớp (3 nhóm chip Thể loại/Nghệ sĩ/Bài tủ, chip chọn đổi nền đậm + check lime) — `ob-05` |
| Hoàn tất | — | ✅ vào deck, empty state đúng "Chưa có bạn hát quanh đây" + nút mở rộng 100km (user chưa có location) — `ob-06`; Hồ sơ hiện Trang 25% + 2 gợi ý (`ob-07`) |

**DB sau hoàn tất:** profiles row (Trang / bio / 2000-01-01 / vi), user_genres 2, user_artists 1, user_baitu 1 — đúng từng lựa chọn trên UI.

**🐛 Bug MỚI tìm được (warm-path, chưa fix — ngoài phạm vi đợt này):** ngay sau verify OTP của user TƯƠI trên app đang chạy ấm (vừa logout user CÓ profile), router cho vào thẳng deck thay vì /onboarding và KHÔNG tự sửa (đứng deck 2+ phút, còn thấy deck cache của user trước). Cold restart thì gate chạy đúng (`ob-01` chính là cold start vào 1/4). Nghi cơ chế: `myProfileProvider` bị invalidate khi SIGNED_IN nhưng redirect đọc `profile.hasValue` — Riverpod giữ previous value (profile user cũ, non-null) trong lúc refresh → `hasProfile=true` → cho qua '/'; sau khi refetch trả null, notifyListeners có chạy nhưng màn không đổi (cần điều tra thêm ở `router.dart:60-66` + `GoRouterRefreshStream`). Tần suất prod thấp (đổi tài khoản trên cùng máy sang số chưa có hồ sơ) nhưng UX sai rõ — đã mở chip task riêng.

**Khôi phục sau walkthrough:** B đăng xuất 099 → đăng nhập lại QA Linh (002) OK; `supabase/config.toml` test_otp đã revert về chỉ 84900000001 (diff so HEAD = rỗng); runtime Supabase vẫn giữ các số test tới lần stop/start kế — không ảnh hưởng gì ngoài local.
