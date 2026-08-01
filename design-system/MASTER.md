# Cùng Hát — Design System (MASTER)

Nguồn sự thật cho mọi quyết định UI. Cập nhật 2026-07-25 theo theme "retro mixtape" (giấy kem +
cam citrus + ink xanh đậm). Token code tương ứng: `lib/core/theme/`
(app_colors, app_typography, app_spacing, app_motion, app_shadows).

> **File này KHÔNG phải nguồn chuẩn về màu.** `lib/core/theme/app_colors.dart` mới là nguồn chuẩn,
> và `test/theme/color_contrast_test.dart` là thứ giữ nó đúng. Bảng dưới đây chỉ để tra nhanh —
> nếu bảng và code lệch nhau thì code đúng. Lý do có dòng này: bản 2026-07-11 ghi ngưỡng cỡ chữ
> trên nền cam là "≥16 bold", trong khi WCAG cần ≥18.66px bold; code đã dùng 19px nên thoát,
> nhưng tài liệu sai suýt kéo theo mọi nút CTA viết mới.

## Style

**Retro mixtape** — giấy kem ấm, viền/ink đậm 2px, shadow cứng (offset, không blur), cam citrus
làm CTA. Light mode only (hiện tại). Tránh: neon lạnh, shadow mờ/blur, low energy, giao diện "AI
slop" generic.

## Design tokens (retro mixtape — 2026-07-11)
| Token | Giá trị | Dùng cho |
|---|---|---|
| background | #F7EFD8 | nền app (giấy kem) |
| surface | #FCF6E3 | card/sheet |
| ink | #1E3A2F | chữ, viền 2px, icon |
| primary | #E8501F | CTA cam (chữ trắng **≥19px bold** — xem ghi chú dưới) |
| secondary | #C6E534 | lime nhấn/badge |
| teal | #8FD8C8 | chip nhạc/trạng thái |
| radius | 14 (pill 999 chỉ cho chip tròn cũ) | nút/card/input |
| shadow | offset(3,3) blur 0 ink 20% | AppShadows.hard |

Typography: display Oswald (headline/title, VN đủ dấu, bundle offline) · body Be Vietnam Pro.

**Về `docs/redesign-mockups/` (22 ảnh):** đây là ảnh do AI sinh, dùng làm *cảm hứng thị giác*, KHÔNG
phải đặc tả. Ảnh không giữ được nhất quán giữa các màn (nút back 5 kiểu, status bar chỉ có ở 1/22
màn, cam trôi từ #EC4809 tới #FC531C) và không phản ánh code hiện tại — `TabHeader`,
`HeaderActionButton`, `OtpInput` đều mới hơn ảnh. Khi ảnh và code mâu thuẫn: **code đúng**.

Quy tắc:
- Không hardcode hex trong widget — luôn qua `AppColors`.
- Primary (cam) là màu hành động chính. Secondary (lime) là accent trạng thái/badge. Teal là chip
  nhạc/trạng thái phụ — không dùng làm màu hành động.
- Text trên `primary` (#E8501F) dùng **trắng** (`AppColors.onPrimary`), cỡ **≥19px + w700**
  (`AppColors.onPrimaryMinBoldSize`). Lý do: trắng-trên-cam chỉ đạt **3.75:1**, tỉ lệ này chỉ hợp lệ
  khi chữ được tính là "chữ lớn" theo WCAG — tức bold ≥18.66px. Ở 16px bold thì ngưỡng là 4.5:1 và
  **trượt**. Đừng dùng ink làm chữ trên cam (3.29:1), cũng đừng dùng cam làm màu chữ trên nền giấy
  (3.27:1).
- `warmGradient` (cam→lime) đã `@Deprecated`: không màu chữ nào đạt 4.5:1 trên cả dải (trắng ở đầu
  lime chỉ 1.43:1). Chỉ dùng làm nền trang trí, không đặt chữ lên.
- Fill nhạt (lime, teal, các tint) chỉ đạt 1.0–1.5:1 so với nền — **hợp lệ vì mọi component có viền
  ink 2px**, ranh giới do viền gánh (ink vs nền = 10.75:1). Widget nào vẽ trần không viền (kiểu
  `WaveProgress`) phải tự bổ sung đường ink làm khung.
- Các token phụ (`primaryTint`, `primaryDark`, `surfaceWarm`, `errorTint`...) xem trực tiếp
  `lib/core/theme/app_colors.dart` — bảng trên chỉ liệt kê token gốc.

## Typography (`AppTypography`)

- **Display/Heading:** Oswald (w600/w700), condensed, hỗ trợ đủ dấu tiếng Việt, bundle offline
  (không phụ thuộc mạng). displayLarge 44 · displayMedium 38 · displaySmall 32 · headlineLarge 30
  · headlineMedium 26 · headlineSmall 22 · titleLarge 22 · titleMedium 18 · titleSmall 14.
- **Body:** Be Vietnam Pro (w400) — bodyLarge 16/1.5 · bodyMedium 14/1.45 · bodySmall 13/1.4
  (màu `textSecondary`).
- **Label:** labelLarge 16/w700 · labelMedium 12/w600 + letterSpacing 0.4 · labelSmall 11/w500 +
  letterSpacing 0.3.
- Body tối thiểu 13px; không tracking âm trên body.

## Spacing & Shape (`AppSpacing`)

Nhịp 4/8: xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32.
Radius: input/button/card/sheet 14 · pill 999 (chỉ chip tròn cũ).
Button cao 52, input 56, bottom nav 72. Touch target ≥44px.

## Motion (`AppMotion`)

- fast 150ms (press/toggle) · base 220ms (fade/chip) · slow 300ms (sheet/entrance) · exit 140ms.
- Enter `easeOutCubic`, exit `easeInCubic`, pop `easeOutBack`.
- Press feedback: `Pressable` scale 0.97 (không shift layout). Stagger list 40ms/item.
- Luôn tôn trọng `MediaQuery.disableAnimations` (reduced motion).

## Components (shared/widgets)

- `Pressable` — wrapper scale-press cho card/tile tappable; có vòng focus 2 lớp (lime ngoài + ink
  trong). Vòng lime một mình chỉ 1.25:1 — **đừng bỏ vòng ink**, nó mới là thứ làm focus nhìn thấy được.
- `Skeleton` / `SkeletonCard` — loading >300ms dùng skeleton, không dùng spinner giữa màn hình.
- `EmptyState` — icon + title + subtitle + CTA chính/phụ; có entrance animation, tôn trọng reduced motion.
- `GradientButton` — CTA hero (đăng nhập, ghép nhóm, nâng cấp): nền `brandGradient`, chữ trắng
  19px/w700, shadow `AppShadows.hard`. Disabled = nền `surfaceMuted` + chữ `onDisabled` (ink), bỏ
  shadow — **không** bọc `Opacity` (bản cũ làm nhãn nút tụt còn 1.23:1, không đọc được).
- `TicketCard` — thẻ kèo/vé phong cách vé giấy (viền ink 2px, shadow cứng, khía + đục lỗ).
- `HardCard` — mặt phẳng viền ink 2px + shadow cứng, dùng cho card thường.
- `StampChip` — badge/trạng thái dạng con dấu (`lime`/`teal`), **không tương tác được** — đừng dùng
  thay nút.
- `TabHeader` + `HeaderActionButton` — khung header CHUNG cho 4 tab; action luôn 44×44. Mọi màn cấp
  1 phải dùng cái này thay vì tự dựng header.
- `OtpInput` — 6 ô + một TextField ẩn; có `autofillHints: oneTimeCode` và cờ `hasError`. Khi mã sai
  phải bật `hasError` **và** hiện câu lỗi bằng chữ.
- `WaveProgress` — thanh hoàn thiện hồ sơ dạng sóng, có khung ink làm thang đo + nhãn Semantics %.
- `WaveDivider` — đường ngăn section dạng sóng (trang trí, không dùng thay divider danh sách).
- `SectionHeader`, `ResponsiveFrame`, `AppLogo`, `ProUpsellSheet` — xem trực tiếp `shared/widgets/`.
- Bottom nav: `NavigationBar` (Material 3, tự xử lý safe area) — 4 tab (Đôi `group` · Kèo
  `mic_external_on` · Chat `chat_bubble` · Hồ sơ `person`), tab active dùng icon fill.

## Anti-patterns (cấm)

- Emoji làm icon UI (dùng Material Symbols, một style outline nhất quán; fill chỉ cho trạng thái active).
- Spinner chặn toàn màn hình cho load danh sách.
- Màu là tín hiệu duy nhất (kèm icon/text).
- Shadow mờ/blur ngoài `AppShadows.hard` (offset(3,3) blur 0, ink alpha ~20%).
- Layout shift khi press/load (reserve space, Transform-only).
- Secondary/teal làm màu button hành động chính (chỉ primary cam).

## Pre-delivery checklist (mỗi màn hình mới)

- [ ] `flutter test test/theme/color_contrast_test.dart` xanh (chạy tự động nếu đổi `AppColors`)
- [ ] Contrast text ≥4.5:1 trên nền giấy kem — chữ trắng trên primary cam phải **≥19px + w700**
- [ ] Touch target ≥44px, có press feedback, hành động phá huỷ có bước xác nhận
- [ ] Loading = skeleton, empty = `EmptyState` có CTA — **và** đã vẽ cả nhánh lỗi + mất mạng +
      người dùng từ chối quyền, không chỉ happy path
- [ ] Header cấp 1 dùng `TabHeader`, không tự dựng
- [ ] Trạng thái nào cũng có icon/chữ đi kèm, không chỉ dựa vào màu
- [ ] Test 360px width + font scale lớn
- [ ] Tokens từ theme, không hardcode

## Còn nợ (audit 2026-07-25 — cập nhật 2026-07-26)

- **Dark mode** chưa có. Nền kem #F7EFD8 rất chói trong phòng hát buổi tối — đúng bối cảnh dùng chính.

Đã trả trong đợt BANGIAO (commit `f8aded79`, 2026-07-25): ~~paywall thiếu kỳ hạn giá/khôi phục mua
hàng/link điều khoản~~ (store_screen đủ cả ba) · ~~consent gộp mục đích~~ (nút gộp chỉ bật
requiredConsents, cross_border tách riêng chỉ nói về lưu trữ Singapore, có dòng ToS riêng).
Món "onboarding thiếu bước ảnh" là cáo buộc SAI từ đầu — bước `/onboarding/photos` có từ P1-6
(xem BANGIAO.md mục "Ba cáo buộc đã bị bác bỏ").

---
*Overrides theo màn hình: đặt tại `design-system/pages/<page>.md` — file page ghi đè MASTER.*
