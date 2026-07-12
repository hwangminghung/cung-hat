# UI Retro Polish — khớp bố cục mockup (đợt 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đưa 4 chỗ lệch bố cục lớn nhất về đúng mockup (`C:\Users\Hwang Ming Hung\cung-hat\docs\redesign-mockups\` — repo GỐC): Hồ sơ (18), Inbox (15), panel deck card (07), và phủ WaveDivider + logo CH (chữ ký style).

**Architecture:** Presentation-only như đợt trước. Tái dùng WaveDivider/StampChip/TicketCard/GradientButton. KHÔNG đổi provider/logic/Key hiện có (trừ khi ghi rõ). Fonts/tokens giữ nguyên.

**Tech Stack:** Flutter 3.44 / Riverpod 3.3 manual providers. Gates mỗi task: `flutter.bat analyze` 0 issue + full `flutter.bat test` 100% (hiện 326).

**Bối cảnh bắt buộc:** worktree `C:\Users\Hwang Ming Hung\cung-hat-ui-retro-wt` nhánh feat/ui-retro; flutter qua `C:\Users\Public\flutter\bin\flutter.bat`; bẫy minimumSize Size(0,52); bẫy MỚI đợt trước: KHÔNG dùng `CrossAxisAlignment.stretch` cho Row trong scrollable dọc (đã sập 1 lần, fix bằng IntrinsicHeight); text scale lớn phải không overflow (maxLines+ellipsis).

---

### Task P1: Hồ sơ tab theo mockup 18

**Files:**
- Modify: `lib/app/home_shell.dart` (khối profile tab: hero card + _CompletionCard + _ProfileTile)
- Create: `lib/shared/widgets/wave_progress.dart` (+ test `test/shared/widgets/wave_progress_test.dart`)
- Test: `test/app/home_shell_test.dart` (case badge PRO đã có phải tiếp tục pass; thêm case WaveProgress hiển thị)

- [ ] **Step 1: WaveProgress widget (TDD)** — test trước: render WaveProgress(progress: 0.75) trong MaterialApp → `expect(tester.takeException(), isNull)` + `find.byType(CustomPaint)` tồn tại + semantics label chứa '75'. Implement: StatelessWidget vẽ CustomPainter dạng cột waveform (như thanh 75% trong mockup 18): ~28 vạch dọc cao ngẫu-nhiên-định-trước (List<double> hằng, KHÔNG Random mỗi build), vạch có index/tổng ≤ progress tô `AppColors.secondaryDark` (rêu-lime đậm), còn lại `AppColors.surfaceMuted`; kèm `Semantics(label: 'Hồ sơ hoàn thiện $percent%')`; height 36; strokeWidth 3; KHÔNG repaint trừ khi progress đổi (shouldRepaint so progress).
- [ ] **Step 2: Hero hồ sơ** — trong home_shell.dart, thay khối Container cam (hiện chứa monogram M + tên + bio chữ trắng, ~dòng 100-146) bằng bố cục mockup 18 trên NỀN KEM (không còn khối cam): Row[ khung avatar 96×96 (Container viền ink 2px radius 14, nền `AppColors.primaryTint`, monogram/ảnh, bóng AppShadows.hard), SizedBox(md), Expanded(Column[ Text(tên, headlineMedium — Oswald, màu ink, maxLines 1 ellipsis), SizedBox(xs), Text(bio, bodyMedium textSecondary, maxLines 2 ellipsis), SizedBox(sm), WaveDivider() ])]. Gear: thêm Row đầu tab: Text('Hồ sơ', displaySmall) + Spacer + IconButton.outlined(icon: Icons.settings_outlined, tooltip 'Cài đặt', onPressed: push('/settings'), key: Key('profile_gear_btn')). GIỮ NGUYÊN _ProfileTile 'Cài đặt' cuối danh sách (mockup có cả hai).
- [ ] **Step 3: _CompletionCard** — thay LinearProgressIndicator/thanh trơn hiện tại bằng WaveProgress(progress) (giữ nguyên nguồn dữ liệu %, các dòng nudge "Chọn đủ 3 thể loại…" giữ nguyên).
- [ ] **Step 4: _ProfileTile icon** — ô icon đổi nền `AppColors.surface` + viền ink 2px radius 12, icon màu ink (bỏ nền salmon `primaryTint`); chevron giữ cam.
- [ ] **Step 5: Gates + commit** — full test + analyze; case badge PRO cũ pass nguyên; commit `feat(profile): ho so theo mockup 18 - hero kem + WaveProgress + icon o ink`.

### Task P2: Inbox rows theo mockup 15

**Files:**
- Modify: `lib/features/chat/presentation/inbox_screen.dart` (_InboxTile + divider)
- Test: `test/features/chat/inbox_screen_test.dart`, `test/features/chat/inbox_turn_pill_test.dart` (3 case turn-pill cũ PHẢI pass — pill giữ Key('turn_pill'))

- [ ] **Step 1: Test bổ sung** — case mới: khi có match, `find.byType(WaveDivider)` findsWidgets (divider giữa các hàng).
- [ ] **Step 2: _InboxTile redesign** — mỗi hàng (bỏ Card bọc nếu đang có): Row[ Avatar vuông 64×64: Container viền ink 2px radius 14 nền primaryTint, Text monogram titleLarge ink; SizedBox(md); Expanded(Column[ Text(tên, titleLarge Oswald ink, maxLines 1 ellipsis), SizedBox(xs), pill trạng thái: GIỮ widget/Key('turn_pill') hiện có nhưng restyle = Container nền `AppColors.secondary` viền ink 1.5 radius 6 chữ ink w700 (như chip lime mockup); khi null thì bỏ trống ]), cột phải Column[ badge unread hiện có (giữ), Text(thời gian nếu model có — nếu MatchSummary KHÔNG có timestamp thì BỎ QUA, đừng bịa data) ], chevron bỏ ]. Giữ nguyên onTap + invalidate.
- [ ] **Step 3: Divider** — giữa các hàng render `Padding(vertical sm, child: WaveDivider())` thay divider/space hiện tại.
- [ ] **Step 4: Gates + commit** — 3 case turn-pill + case section "Tin nhắn đôi" pass nguyên; commit `feat(chat): inbox rows theo mockup 15 - avatar vuong + pill lime + WaveDivider`.

### Task P3: Deck card panel + tiêu đề theo mockup 07

**Files:**
- Modify: `lib/features/discovery/presentation/candidate_card.dart` (panel info + palette monogram), `lib/features/discovery/presentation/doi_deck_screen.dart` (waveform cạnh tiêu đề)
- Test: `test/features/discovery/` file test card hiện có (thêm case)

- [ ] **Step 1: Test** — case: Candidate(activeToday: true, sharedGenres: ['ballad','vpop']) → panel hiện 'Online hôm nay' + chip '#ballad'; Candidate(activeToday: false, sharedGenres: []) → KHÔNG hiện hai thứ đó.
- [ ] **Step 2: Panel info card** — trong candidate_card.dart, panel dưới (đang có tên + Cách x km + cùng n bài tủ): thêm (a) nếu `candidate.activeToday` → hàng đầu: chấm tròn 8px màu `AppColors.secondary` + Text('Online hôm nay', bodySmall ink); (b) cột phải panel: Wrap chips từ `candidate.sharedGenres.take(2)` → StampChip(label: '#$genre', tone: StampChipTone.teal). Layout: Row[Expanded(cột trái hiện có + Online), Wrap chips phải] — KHÔNG stretch; chips maxLines an toàn vì Wrap.
- [ ] **Step 3: Monogram palette** — thay bảng màu monogram cũ (đỏ đô/hash cũ) bằng list retro: `[AppColors.primary, AppColors.secondaryDark, AppColors.tertiaryPop, AppColors.pink, AppColors.primaryDark]` (chọn theo hash id như cơ chế cũ — chỉ đổi list màu).
- [ ] **Step 4: Tiêu đề** — doi_deck_screen.dart: cạnh Text('Đôi hát') thêm `Expanded(child: Padding(left lg, child: WaveDivider()))` trong Row (title bên trái, waveform chạy sang phải như mockup).
- [ ] **Step 5: Gates + commit** — `feat(discovery): panel deck online+genre chips + monogram retro + waveform tieu de (mockup 07)`.

### Task P4: Phủ WaveDivider + logo CH

**Files:**
- Modify: `lib/shared/widgets/app_logo.dart`; các màn: inbox đã có (P2); thêm dưới tiêu đề ở: keo_board_screen.dart (dưới subtitle header), settings_screen.dart (dưới AppBar/đầu list), store_screen.dart (dưới banner đầu)
- Test: test hiện có các màn đó pass nguyên

- [ ] **Step 1: AppLogo** — redesign: Container nền kem viền ink 2px radius 16 + Text('CH', Oswald w700 màu ink cỡ theo size widget) + dưới chữ 1 WaveDivider màu cam ngắn (Padding horizontal sm). Giữ nguyên API (size param) để login screen không đổi call-site.
- [ ] **Step 2: Rải WaveDivider** — mỗi màn liệt kê thêm đúng 1 WaveDivider ở vị trí ghi trên (Padding vertical sm, màu mặc định). KHÔNG thêm vào màn khác ngoài danh sách.
- [ ] **Step 3: Gates + commit** — `feat(ui): logo CH + phu WaveDivider cac man chinh`.

### Task P5: Verify emulator đợt polish

- [ ] Build APK dart-define emulator + cài; walkthrough chụp: Hồ sơ, Inbox (có match), Đôi deck, Kèo board, login (logo CH); so mockup 18/15/07/11/01; cập nhật `docs/verify-ui-retro-2026-07-12.md` (thêm section "Polish đợt 2") + commit.

## Self-review đã chạy
- Coverage: 4 nhóm lệch user thấy → P1-P4; verify → P5. Đục lỗ/texture/ảnh AI ngoài phạm vi (đã chốt).
- Data: activeToday/sharedGenres có thật trong Candidate (đã đọc model); MatchSummary timestamp CHƯA chắc có → P2 ghi rõ "không bịa data".
- Type: WaveProgress mới định nghĩa ở P1 chỉ dùng ở P1; StampChip tone teal API đúng; WaveDivider dùng constructor mặc định.
- Bẫy: không stretch-Row-trong-list; Key('turn_pill') giữ; API AppLogo giữ.
