# Cùng Hát — Redesign giao diện (Coral / Be Vietnam Pro)

Ngày: 2026-06-26
Trạng thái: spec chờ duyệt

## Mục tiêu

Thay giao diện "Material mặc định" (hiện chỉ `ThemeData(colorSchemeSeed: #6750A4, useMaterial3: true)`, không font riêng, không tùy biến component) bằng một **design system tập trung** trông chỉn chu, native, có bản sắc cho app gặp-gỡ-hát-karaoke "Cùng Hát".

Lưu ý: chữ `??` trên emulator chỉ là thiếu font tiếng Việt của emulator, KHÔNG phải lỗi app — không nằm trong phạm vi sửa.

## Quyết định đã chốt

| Hạng mục | Lựa chọn |
|----------|----------|
| Hướng | **Coral ấm áp** (thân thiện, cộng đồng) |
| Phạm vi | **Design system + tinh chỉnh tay các màn chính** |
| Font | **Be Vietnam Pro** (qua `google_fonts`) |
| Chế độ | **Chỉ Light** (dark mode để sau) |
| Cách làm | **Cách 1** — ThemeData tập trung + vài widget tái dùng |

## Kiến trúc

Một thư mục theme là nguồn chân lý duy nhất; `app.dart` dùng nó. Mọi màn hình hiện có hưởng style mới tự động qua `ThemeData`; các màn chính được tinh chỉnh tay thêm.

```
lib/core/theme/
  app_colors.dart       // hằng số màu (coral palette + warm neutral + semantic)
  app_typography.dart   // TextTheme dựng từ GoogleFonts.beVietnamProTextTheme
  app_spacing.dart      // radius + spacing tokens
  app_theme.dart        // AppTheme.light → ThemeData đầy đủ (component themes)
lib/shared/widgets/
  app_logo.dart         // wordmark "Cùng Hát" + icon tròn
  section_header.dart   // tiêu đề mục (taste, …)
  empty_state.dart      // trạng thái rỗng thân thiện (icon + title + sub + CTA)
  otp_input.dart        // ô nhập 6 ký tự rời (custom; hoặc pinput)
lib/features/keo/presentation/widgets/
  keo_card.dart         // thẻ kèo mới
```

## Tokens (Phần 1 — đã duyệt)

Màu (light):
- Primary `#E05732`, Primary tint `#FCE9E2`, on-primary `#FFFFFF`
- Nền app `#FBF6F3`, Card/Surface `#FFFFFF`
- Text chính `#2A1D18`, phụ `#7A6A63`, hint `#A89A93`, viền `#F0E6E0`
- Success `#2E9E6B`, Warning `#E8A33D`, Error `#D64545`

Chữ — Be Vietnam Pro (400/500/600/700), map vào Material TextTheme:
- display/headline 26/600 · titleLarge 20/600 · titleMedium 16/600
- bodyLarge 15/400 · bodySmall 13/400 · labelLarge (nút) 15/600

Bo góc & khoảng cách:
- Radius: nút 14 · input 12 · card 16 · chip/pill 999 · sheet 24
- Spacing: 4 · 8 · 12 · 16 · 20 · 24
- Bóng: rất nhẹ (card = viền mảnh + bóng mờ)

## Component themes (Phần 2 — đã duyệt)

Cấu hình trong `app_theme.dart` để toàn app áp dụng:
- `filledButtonTheme` / `elevatedButtonTheme`: coral, chữ trắng 15/600, bo 14, cao 52
- `outlinedButtonTheme` / `textButtonTheme`: chữ coral, viền coral mảnh
- `inputDecorationTheme`: nền trắng, viền `#F0E6E0`, bo 12, focus viền coral 1.5px, label nổi
- `cardTheme`: trắng, bo 16, viền mảnh, bóng nhẹ
- `chipTheme`: pill; selected coral/trắng; unselected trắng + viền
- `navigationBarTheme`: nền trắng, cao 64, indicator `#FCE9E2`, chọn = coral, chưa = `#A89A93`, label 12/600
- `appBarTheme`: nền liền `#FBF6F3`, tiêu đề 20/600, không bóng, icon coral
- `snackBarTheme`: floating, nền `#2A1D18`, chữ trắng, bo 12
- `bottomSheetTheme` / `dialogTheme`: bo trên 24, nền trắng
- `colorScheme`: dựng từ các token trên (ColorScheme.light tùy biến, không dùng seed)

## Màn chính tinh chỉnh tay (Phần 3 — đã duyệt)

1. Login (`phone_screen.dart`): hero `AppLogo` + tagline + icon tròn ở trên; ô SĐT prefix +84; nút "Gửi mã OTP" full-width. Bỏ căn giữa trống trải.
2. OTP (`otp_screen.dart`): dùng `OtpInput` 6 ô rời; dòng "Mã đã gửi tới …"; đếm giờ gửi lại; "Xác nhận" full-width.
3. Onboarding (`onboarding_flow.dart` + `dob_step`, `consent_step`, `taste_step`): dòng "Bước x/4"; stepper coral; DOB pill; consent có nhãn + dấu bắt buộc; taste dùng `SectionHeader` + chip mới; "Hoàn tất" nổi bật.
4. Kèo board (`keo_board_screen.dart`): header chào + nhãn vị trí; banner "Ghép nhóm cho tôi" coral nhạt; `KeoCard` mới (tiêu đề, meta có icon 📍/👥/🕐, chip thể loại, chủ kèo, "Tham gia"); FAB "Tạo kèo"; `EmptyState` thân thiện.
5. Nav shell (`home_shell.dart`): NavigationBar theo theme mới.
6. Trạng thái rỗng/đang tải/lỗi: thống nhất qua `EmptyState` + spinner coral.

Điểm nhấn dùng icon + hình khối đơn giản (mic, nốt nhạc) — không cần asset ảnh nặng.

## Phụ thuộc (dependencies)

- Thêm `google_fonts` (tải Be Vietnam Pro runtime). Cân nhắc bundle font vào assets để chạy offline ổn định (khuyên: bundle để khỏi phụ thuộc mạng lần đầu).
- `pinput` (tùy chọn) cho ô OTP — hoặc tự viết `OtpInput` để khỏi thêm dep. Mặc định: tự viết.

## Kiểm thử (testing)

- `flutter analyze` sạch; `flutter test` cũ vẫn pass (các `Key` hiện có: `send_otp_btn`, `verify_otp_btn`, `onb_*`, `consent_*` được GIỮ NGUYÊN để không vỡ test/luồng).
- Thêm widget smoke test: `AppTheme.light` dựng được; `KeoCard`/`EmptyState` render.
- Verify thật trên emulator qua harness adb đã có (chụp màn hình từng màn: login, OTP, onboarding, home, Kèo board) — so trước/sau.

## Ngoài phạm vi (non-goals)

- Dark mode (để sau).
- Đổi logic/nghiệp vụ, schema, hay luồng điều hướng (chỉ đổi diện mạo; giữ nguyên các `Key`).
- Asset ảnh/illustration nặng; thiết kế lại các màn phụ ngoài danh sách (chúng vẫn đẹp lên nhờ theme chung).

## Rủi ro

- `google_fonts` tải mạng lần đầu → cân nhắc bundle font.
- Đụng nhiều file UI → giữ thay đổi thuần diện mạo, không sửa logic, chạy analyze/test sau mỗi nhóm.
