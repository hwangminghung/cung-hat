# Cùng Hát — Design System (MASTER)

Nguồn sự thật cho mọi quyết định UI. Cập nhật 2026-07-02 theo bộ giao diện Stitch export
(Quicksand + Inter, palette coral/lime/tím). Token code tương ứng: `lib/core/theme/`
(app_colors, app_typography, app_spacing, app_motion).

## Style

**Warm Vibrant & Friendly** — năng lượng Gen-Z, thân thiện, không phải dating app.
Light mode only (hiện tại). Tránh: neon lạnh, shadow phức tạp, low energy, giao diện "AI slop" generic.

## Colors (`AppColors`)

| Role | Token | Hex |
|------|-------|-----|
| Primary (coral) | `primary` / `primaryDark` / `primaryTint` / `primarySoft` | `#FF6B4A` / `#AE3115` / `#FFDAD2` / `#FFB4A3` |
| Secondary (lime) | `secondary` / `secondaryDark` / `secondaryTint` | `#C8F252` / `#4F6600` / `#F1FFD0` |
| Tertiary (tím) | `tertiary` / `tertiaryPop` / `tertiaryTint` | `#674BB5` / `#A488F7` / `#E8DDFF` |
| Accent pop | `pink` / `cyan` | `#F472B6` / `#65D6E8` |
| Background / Surface / SurfaceAlt | | `#FAF9F6` / `#FFFFFF` / `#F4F3F1` |
| Surface warm / muted | `surfaceWarm` / `surfaceMuted` | `#FFF4EF` / `#E9E8E5` |
| Text primary / secondary / hint | | `#1A1C1A` / `#59413C` / `#8D716A` |
| Border | | `#E1BFB8` |
| Success / Warning / Error | | `#2E9E6B` / `#E8A33D` / `#BA1A1A` |
| Brand gradient | `brandGradient` | coral `#FF6B4A` → pink `#F472B6`, cho CTA hero/upsell |
| Warm gradient | `warmGradient` | coral → amber, dùng phụ |
| Shadow tint | `shadow` | `#8C1900` ở alpha thấp (card dùng ~0.08–0.14) |

Quy tắc:
- Không hardcode hex trong widget — luôn qua `AppColors`/`ColorScheme`.
- Coral là màu hành động chính. Lime là accent trạng thái/verified. Tím + pink là accent
  trang trí (blob nền, illustration, badge) — không dùng làm màu hành động.
- Text trên `primary` (#FF6B4A) dùng **trắng**, không dùng `#661000` (contrast không đủ).

## Typography (`AppTypography`)

- **Display/Heading:** Quicksand (600/700) — playful, hỗ trợ tiếng Việt. displayLarge 40 ·
  headlineLarge 32 · headlineMedium 28 (mobile headline) · titleLarge 22 · titleMedium 20/w600.
- **Body:** Inter — bodyLarge 16/1.45 · bodyMedium 14/1.42 · bodySmall 13/1.35.
- **Label:** labelLarge 15/w700 · labelMedium 12/w600 + letterSpacing 0.6 (label-bold).
- Body tối thiểu 13px; không tracking âm trên body.

## Spacing & Shape (`AppSpacing`)

Nhịp 4/8: xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32.
Radius: input 12 · button pill (999) · card 24 · sheet 28 · pill 999.
Button cao 56, input 56, bottom nav 72. Touch target ≥44px.

## Motion (`AppMotion`)

- fast 150ms (press/toggle) · base 220ms (fade/chip) · slow 300ms (sheet/entrance) · exit 140ms.
- Enter `easeOutCubic`, exit `easeInCubic`, pop `easeOutBack`.
- Press feedback: `Pressable` scale 0.97 (không shift layout). Stagger list 40ms/item.
- Luôn tôn trọng `MediaQuery.disableAnimations` (reduced motion).

## Components (shared/widgets)

- `Pressable` — wrapper scale-press cho card/tile tappable.
- `Skeleton` / `SkeletonCard` — loading >300ms dùng skeleton, không dùng spinner giữa màn hình.
- `EmptyState` — icon gradient tròn + title + subtitle + CTA; có entrance animation.
- CTA hero (đăng nhập, ghép nhóm, nâng cấp): nền `brandGradient`, chữ trắng, pill, shadow coral nhẹ.
- Bottom nav: 4 tab (Đôi `group` · Kèo `mic_external_on` · Chat `chat_bubble` · Hồ sơ `person`);
  tab active = icon fill + dot dưới label, màu `primaryDark`.

## Anti-patterns (cấm)

- Emoji làm icon UI (dùng Material Symbols, một style outline nhất quán; fill chỉ cho trạng thái active).
- Spinner chặn toàn màn hình cho load danh sách.
- Màu là tín hiệu duy nhất (kèm icon/text).
- Shadow ngẫu nhiên ngoài scale card (elevation 2, shadow tint ấm `#8C1900`).
- Layout shift khi press/load (reserve space, Transform-only).
- Tím/pink làm màu button hành động (chỉ coral).

## Pre-delivery checklist (mỗi màn hình mới)

- [ ] Contrast text ≥4.5:1 trên nền warm white (chú ý: chữ trên coral phải là trắng)
- [ ] Touch target ≥44px, có press feedback
- [ ] Loading = skeleton, empty = EmptyState có CTA
- [ ] Test 360px width + font scale lớn
- [ ] Tokens từ theme, không hardcode

---
*Overrides theo màn hình: đặt tại `design-system/pages/<page>.md` — file page ghi đè MASTER.*
