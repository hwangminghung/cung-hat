# UI Upgrade 2026-08-01 — Dark mode + polish 4 màn + chuẩn hoá state + push primer

User chốt: làm **tất cả 4 khối** từ audit UI 2026-07-26, theo Hướng A ("giữ hồn
retro, đổi nền theo đêm"), dark mode kiểu **theo máy + toggle trong Cài đặt**.
Các quyết định chi tiết dưới đây user uỷ quyền ("tuỳ bạn cho là tốt nhất").

Nhánh: `ui-upgrade-0801` (master đã ở `053af52a`, tag `audit-match-0801`).

## Đợt 1 — Dark mode (nền tảng, làm trước)

### Bảng màu "retro mixtape đêm"

Nguyên tắc: **không phải Material dark xám generic**. Nền là ink sẫm ánh rêu,
chữ/viền là chính màu giấy kem của brand, cam CTA giữ nguyên, shadow cứng
offset(3,3) giữ nguyên ngôn ngữ. Trong quán karaoke tối vẫn nhận ra Cùng Hát.

| Vai trò | Light (giữ nguyên) | Dark (giá trị đích*) |
|---|---|---|
| background | #F7EFD8 | #14231C |
| surface | #FCF6E3 | #1B2E25 |
| surfaceAlt / surfaceMuted | #EFE4C8 / #E2D6B9 | #24382C / #2E4237 |
| ink (chữ+viền+icon) | #1E3A2F | #F2EAD3 (kem dịu) |
| textSecondary / textHint | #405B50 / #5C7168 | #B7C7BB / #93A79A |
| primary / onPrimary | #E8501F / trắng ≥19px bold | GIỮ NGUYÊN (quy tắc 3.75:1 chữ lớn không phụ thuộc nền) |
| primaryTint (nền chip cam) | #F8C9B8 | #4A2417 (rỉ sét tối) — chữ trên tint đổi sang #FFB59B |
| secondary lime / teal / pink | giữ | giữ (fill + chữ ink-của-light #1E3A2F trên fill sáng) |
| secondaryTint / tertiaryTint | #EDF6B7 / #DDF3EE | #333D12 / #1F3A34 |
| success / warning / error | #287A56 / #9A5400 / #B42318 | #58C389 / #D99A3D / #EF6A5E (đạt ≥4.5:1 trên nền tối) |
| các *Tint trạng thái | sáng | bản tối tương ứng (~#163326 / #3A2E14 / #45201C) |
| shadow | ink 20% | đen 55% |

*Giá trị đích: hex cuối cùng do `color_contrast_test` quyết — test sẽ chạy
**cả hai palette** qua đúng danh sách cặp màu hiện có; hex nào trượt thì chỉnh
hex, không nới ngưỡng. MASTER.md cập nhật sau, kèm ghi chú "code là nguồn chuẩn".

### Kiến trúc token (quyết định quan trọng nhất)

Toàn bộ code gọi `AppColors.x` tĩnh (quy tắc design system). Để ít churn nhất:

- Thêm `AppPalette` — class thuần dữ liệu chứa toàn bộ ~35 màu, hai instance
  `AppPalette.light` / `AppPalette.dark` (const).
- `AppColors` **giữ nguyên tên member** nhưng đổi từ `static const` sang
  `static Color get x => _p.x;` với `static AppPalette _p` + `select(Brightness)`.
  → mọi call-site giữ nguyên; những chỗ dùng trong `const` widget sẽ thành
  **compile error** — compiler tự liệt kê hết, sweep bỏ `const` ở đúng các chỗ đó.
- `AppTheme.dark()` dựng từ `AppPalette.dark` (mirror `light()`; hai hàm nhận
  palette chung một builder để không lệch nhau).
- KHÔNG dùng ThemeExtension/context.colors: đổi hàng trăm call-site, không đáng
  cho app 1 người bảo trì.

### Chọn mode + persist

- `ThemeModeController` (Notifier<ThemeMode>, pref `theme_mode`: 'light'|'dark';
  vắng = system) — copy đúng khuôn `LocaleController` (seed trong main() trước
  runApp để không nháy frame đầu).
- `CungHatApp.build`: resolve brightness hiệu lực (mode + platformBrightness,
  lắng nghe đổi qua WidgetsBindingObserver) → `AppColors.select(...)` TRƯỚC khi
  dựng MaterialApp; MaterialApp nhận `theme` + `darkTheme` + `themeMode`.
- Cài đặt: mục "Giao diện" 3 lựa chọn Sáng/Tối/Theo máy — giống UI đổi ngôn ngữ.
- Widget test mặc định palette light (không đổi hành vi test cũ); test dark
  gọi `AppColors.select(Brightness.dark)` + addTearDown reset.

## Đợt 2 — Polish 4 màn theo audit

1. **Kế hoạch (PlanScreen)**: một CTA chính full-width; hàng action phụ đồng cỡ
   (OutlinedButton, icon + label ngắn); sửa "Chia sẻ cho bạn bè" đang xuống 3
   dòng (label ngắn lại + Expanded đúng chỗ).
2. **Chat rỗng (1-1)**: 3 chip gợi ý "Gửi bài tủ" (mở sheet bài tủ sẵn có) ·
   "Hỏi gu nhạc" · "Rủ đi hát" (2 cái sau chèn template vào ô nhập); nút gửi
   **disable khi ô trống** (cả chat 1-1 lẫn chat kèo).
3. **Store**: tách section "Gói Pro" (hero card đầu trang) và "Mua lẻ"; các
   item lẻ mang chip "Đã gồm trong Pro"; user đã Pro thì item lẻ hiện trạng
   thái sở hữu thay vì nút Mua.
4. **Shared Plan**: đồng bộ khuôn SharedKeoScreen — Skeleton khi tải, lỗi mạng
   ra EmptyState + Thử lại, chỉ "Không tìm thấy" khi server trả null thật.

## Đợt 3 — Chuẩn hoá loading/error + accessibility

- Quét toàn app: màn nào còn spinner trần khi loading list / báo lỗi cụt không
  retry → đưa về chuẩn `Skeleton*` + `EmptyState(actionLabel: Thử lại)`.
  (Inventory cụ thể nằm trong plan — grep `CircularProgressIndicator` +
  `error: (` toàn lib/, loại trừ nút đang-lưu.)
- 4 lỗ audit: tooltip nút xoá prompt_editor_sheet · Semantics + nút bàn phím
  cho photo_carousel · datetime_format theo locale (`DateFormat.yMd(locale)`)
  · `...` → `…` trong app_vi.arb.

## Đợt 4 — Push primer (món nợ P1-3)

- `PushPrimerSheet`: giải thích 2 lợi ích (kèo sắp diễn ra, có match mới) + 2
  nút "Bật thông báo" / "Để sau".
- Luồng: HomeShell hiện sheet MỘT lần khi (có hồ sơ) && (chưa từng trả lời —
  pref `push_primer_choice`). "Bật" → gọi `registerForSignedInUser()` (hộp
  thoại quyền OS bật tại đây, đúng ngữ cảnh); các phiên sau tự đăng ký im lặng.
  "Để sau" → không tự hỏi lại; Cài đặt thêm mục "Thông báo" để bật sau.
- `pushRegistrationProvider` đổi: chỉ auto-register khi user ĐÃ từng bấm Bật.

## Kiểm chứng

- `color_contrast_test` parametrize 2 palette; test mới cho ThemeModeController
  (persist + system fallback), Settings switcher, từng màn polish, primer sheet.
- Gates mỗi đợt: analyze 0 · full Flutter test · vi/en parity · build APK.
- Cuối cùng: verify live emulator cả light lẫn dark (đi 4 tab + Store + Kế
  hoạch + chat), screenshot đối chứng.

## Ngoài phạm vi (nói rõ để khỏi trôi)

- Không redesign layout theo 22 mockup AI (MASTER.md đã kết luận: cảm hứng,
  không phải spec; code mới hơn ảnh).
- Không đổi typography/spacing/motion tokens.
- Không đụng gallery test states (mục 6 audit P2 — thuộc integration test,
  không phải UI runtime; để đợt riêng nếu cần).
