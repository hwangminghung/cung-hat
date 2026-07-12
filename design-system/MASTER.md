# Cùng Hát — Design System (MASTER)

Nguồn sự thật cho mọi quyết định UI. Cập nhật 2026-07-11 theo theme "retro mixtape" (giấy kem +
cam citrus + ink xanh đậm). Token code tương ứng: `lib/core/theme/`
(app_colors, app_typography, app_spacing, app_motion, app_shadows).

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
| primary | #E8501F | CTA cam (chữ trắng ≥16 bold) |
| secondary | #C6E534 | lime nhấn/badge |
| teal | #8FD8C8 | chip nhạc/trạng thái |
| radius | 14 (pill 999 chỉ cho chip tròn cũ) | nút/card/input |
| shadow | offset(3,3) blur 0 ink 20% | AppShadows.hard |

Typography: display Oswald (headline/title, VN đủ dấu, bundle offline) · body Be Vietnam Pro.
Component chuẩn: GradientButton (CTA), TicketCard (kèo/vé), StampChip (badge/trạng thái), WaveDivider (ngăn section).
Nguồn chuẩn: docs/redesign-mockups/ (22 ảnh, bản 2026-07-11).

Quy tắc:
- Không hardcode hex trong widget — luôn qua `AppColors`.
- Primary (cam) là màu hành động chính. Secondary (lime) là accent trạng thái/badge. Teal là chip
  nhạc/trạng thái phụ — không dùng làm màu hành động.
- Text trên `primary` (#E8501F) dùng **trắng** (`AppColors.onPrimary`), cỡ ≥16 bold.
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

- `Pressable` — wrapper scale-press cho card/tile tappable.
- `Skeleton` / `SkeletonCard` — loading >300ms dùng skeleton, không dùng spinner giữa màn hình.
- `EmptyState` — icon gradient tròn + title + subtitle + CTA; có entrance animation.
- `GradientButton` — CTA hero (đăng nhập, ghép nhóm, nâng cấp): nền `brandGradient`, chữ trắng,
  shadow `AppShadows.hard`.
- `TicketCard` — thẻ kèo/vé phong cách vé giấy (viền ink 2px, shadow cứng).
- `StampChip` — badge/trạng thái dạng con dấu (dùng `teal`/`secondary`).
- `WaveDivider` — đường ngăn section dạng sóng.
- Bottom nav: 4 tab (Đôi `group` · Kèo `mic_external_on` · Chat `chat_bubble` · Hồ sơ `person`);
  tab active = icon fill + dot dưới label, màu `primaryDark`.

## Anti-patterns (cấm)

- Emoji làm icon UI (dùng Material Symbols, một style outline nhất quán; fill chỉ cho trạng thái active).
- Spinner chặn toàn màn hình cho load danh sách.
- Màu là tín hiệu duy nhất (kèm icon/text).
- Shadow mờ/blur ngoài `AppShadows.hard` (offset(3,3) blur 0, ink alpha ~20%).
- Layout shift khi press/load (reserve space, Transform-only).
- Secondary/teal làm màu button hành động chính (chỉ primary cam).

## Pre-delivery checklist (mỗi màn hình mới)

- [ ] Contrast text ≥4.5:1 trên nền giấy kem (chú ý: chữ trên primary cam phải là trắng ≥16 bold)
- [ ] Touch target ≥44px, có press feedback
- [ ] Loading = skeleton, empty = EmptyState có CTA
- [ ] Test 360px width + font scale lớn
- [ ] Tokens từ theme, không hardcode

---
*Overrides theo màn hình: đặt tại `design-system/pages/<page>.md` — file page ghi đè MASTER.*
