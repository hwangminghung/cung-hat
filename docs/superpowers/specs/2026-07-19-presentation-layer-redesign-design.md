# Cùng Hát — Viết lại presentation layer theo 22 mockup

**Ngày:** 2026-07-19
**Trạng thái:** Đã được người dùng duyệt trong hội thoại
**Phạm vi:** Frontend Flutter, light mode, Android + iOS presentation parity + mobile web

## 1. Mục tiêu

Viết lại presentation layer của Cùng Hát dựa trên 22 ảnh trong
`docs/redesign-mockups/`, đồng thời:

- Giữ bản sắc retro mixtape của bộ mockup.
- Làm các màn hình nhận diện giàu năng lượng, còn màn hình tiện ích dễ đọc và ít trang trí hơn.
- Đạt chất lượng đồng đều trên Android, iOS presentation mode và mobile web.
- Giữ nguyên toàn bộ route, provider, model, API contract, business logic và backend.
- Duy trì hành vi, dữ liệu, quyền, entitlement, analytics và feature flag hiện có.
- Chỉ bàn giao cho người dùng sau khi đủ 22 màn hình và hoàn tất kiểm tra cuối.

## 2. Quyết định sản phẩm và thiết kế

### 2.1 Hướng thiết kế

Sử dụng phương án **hybrid**:

- Các màn hình nhận diện chính bám sát mockup.
- Form, chat, plan, store và settings được tinh chỉnh về bố cục để dễ dùng hơn.
- Không sao chép pixel một cách máy móc nếu mockup gây khó đọc, overflow hoặc không phù hợp với dữ
  liệu thực.
- Mọi khác biệt có chủ đích với mockup phải được ghi trong báo cáo bàn giao.

### 2.2 Phân bổ mức độ playful

Mức playful cao:

- Auth/onboarding.
- Đôi/discovery.
- Kèo.
- Match celebration.

Mức playful vừa hoặc thấp:

- Form dài.
- Inbox/chat.
- Plan/map.
- Booking/payment presentation.
- Store.
- Settings.

Tất cả vẫn dùng chung token, typography và component vocabulary.

### 2.3 Nền tảng và theme

- Light mode trong đợt này.
- Android, iOS presentation mode và mobile web có cùng mức độ hoàn thiện.
- Viewport chuẩn: 360dp, 393dp và 430dp.
- Android được kiểm tra trên emulator thật.
- Mobile web được chạy trên Chrome.
- Do môi trường Windows không chạy được iOS Simulator hoặc build iOS, iOS được kiểm tra bằng Flutter
  widget test với `TargetPlatform.iOS`; giới hạn này phải được ghi rõ khi bàn giao.

## 3. Ranh giới frontend-only

### 3.1 Được phép thay đổi

- `lib/core/theme/**`
- `lib/shared/widgets/**`
- `lib/features/**/presentation/**`
- Presentation shell như `lib/app/home_shell.dart`
- `lib/l10n/**` khi chỉnh microcopy nhưng không đổi nghĩa nghiệp vụ
- Widget, responsive, accessibility và presentation tests
- Tài liệu design system liên quan đến presentation layer

### 3.2 Bị cấm thay đổi

- `supabase/**`
- Migration, SQL, Edge Function, RPC và database schema
- `lib/features/**/data/**`
- `lib/features/**/domain/**`
- `lib/features/**/application/**`
- Repository, provider contract và API client
- Route declaration hoặc redirect logic
- Model, serialization và freezed output
- Payment, entitlement, auth, realtime, safety hoặc analytics logic

Nếu một presentation mới cần dữ liệu chưa có, phần UI đó phải bị loại bỏ hoặc ánh xạ sang dữ liệu
hiện có. Không được mở rộng backend để phục vụ mockup.

## 4. Kiến trúc presentation layer

Presentation mới chia thành ba tầng:

```text
Screen wiring
Provider state và callback hiện có
            ↓
Feature sections
Header, card deck, form section, timeline, settings group
            ↓
Shared UI system
Token, typography, button, card, input, chip, sheet, loading/empty/error
```

### 4.1 Screen wiring

- Screen cấp cao tiếp tục đọc provider hiện có.
- Screen chỉ chuyển dữ liệu, trạng thái và callback xuống presentation widget.
- Không thêm data fetch, mutation hoặc Supabase call trong widget.
- Giữ các `Key`, semantic label và callback mà test/automation đang dùng.

### 4.2 Feature sections

Mỗi section có một trách nhiệm rõ:

- Nhận model trình bày hoặc primitive props.
- Render một nhóm nội dung.
- Phát callback lên screen wiring.
- Không biết repository hoặc backend.

Các section lớn phải được tách khỏi screen để tránh file trình bày quá dài và giúp test độc lập.

### 4.3 Shared UI system

Giữ API public của component đang được dùng khi có thể:

- `AppLogo`
- `GradientButton`
- `HardCard`
- `TicketCard`
- `StampChip`
- `TabHeader`
- `SectionHeader`
- `OtpInput`
- `WaveProgress`
- `WaveDivider`
- `EmptyState`
- `Skeleton`, `SkeletonTile`, `SkeletonCard`
- `Pressable`
- `ProUpsellSheet`

Internals được phép viết lại để cùng token, state và responsive behavior. Bổ sung một
`ResponsiveFrame` dùng chung cho:

- SafeArea.
- Keyboard/view inset.
- Chiều rộng nội dung 360–430dp.
- Căn giữa mobile surface trên mobile web.
- Text scale và overflow policy.

Không tạo một component system song song nếu component hiện có có thể được mở rộng an toàn.

## 5. Visual system

### 5.1 Màu

| Vai trò | Giá trị | Quy tắc |
|---|---:|---|
| Background | `#F7EFD8` | Nền giấy kem |
| Surface | `#FCF6E3` | Card, sheet, form |
| Ink | `#1E3A2F` | Text, icon, border |
| Primary | `#E8501F` | CTA chính |
| Primary dark | `#942D0E` | Pressed/action text phù hợp |
| Lime | `#C6E534` | Badge, selected state |
| Teal | `#8FD8C8` | Music chip, status phụ |

- Lime và teal không làm màu CTA chính.
- Không dùng gradient tùy ý.
- Không dùng glassmorphism hoặc shadow mờ.
- Màu không được là tín hiệu trạng thái duy nhất.

### 5.2 Typography

- Heading/display: Oswald.
- Body/control: Be Vietnam Pro.
- Body text tối thiểu 13px.
- Primary CTA: nhãn trắng `19px / 700 / 1.05` trên `#E8501F`.
- Cặp CTA cam–trắng được xem là large bold text và đạt tối thiểu 3:1.
- Chữ thông thường đạt tối thiểu 4.5:1.
- Không tracking âm cho body text tiếng Việt.

### 5.3 Shape, border và shadow

- Border chuẩn: 2px ink.
- Radius chuẩn cho card/input/button/sheet: 14px.
- Pill radius chỉ dùng cho pill/chip đã được chấp thuận.
- Hard shadow: offset 3×3px, blur 0, `#331E3A2F`.
- Press feedback dùng transform, không gây layout shift.

### 5.4 Motion

- Press/toggle: 150ms.
- Fade/chip/card: 220ms.
- Sheet/entrance: 300ms.
- Exit: 140ms.
- Match celebration là màn hình giàu chuyển động nhất.
- Tôn trọng `MediaQuery.disableAnimations` và reduced motion.

## 6. Component state

Component phải chuẩn hóa:

- Default.
- Pressed.
- Focused.
- Selected.
- Loading.
- Empty.
- Error.
- Disabled.

Quy tắc:

- Touch target tối thiểu 44×44px.
- Loading giữ nguyên không gian layout.
- List/content loading dùng skeleton thay vì blocking spinner.
- Empty state giải thích và có hành động tiếp theo phù hợp.
- Error state dùng thông báo thân thiện và retry callback hiện có.
- Swipe luôn có action button tương đương cho chuột, bàn phím và accessibility.

## 7. Thiết kế 22 màn hình

### 7.1 Auth/onboarding — 01–06

1. `01-login.png`
   - AppLogo và value proposition rõ.
   - Form phone trên paper surface.
   - Keyboard không che CTA.
2. `02-otp.png`
   - OTP ticket hierarchy.
   - Giữ resend, countdown, validation và back behavior.
3. `03-onboarding-dob.png`
   - Giữ field và age gate.
   - WaveProgress thống nhất.
4. `04-onboarding-consent.png`
   - Giữ required/optional consent semantics.
5. `05-onboarding-profile.png`
   - Giữ field, validation và thứ tự.
6. `06-onboarding-music-taste.png`
   - StampChip/selectable chip playful.
   - Giữ selection rule và completion action.

### 7.2 Đôi/discovery — 07–10

7. `07-doi-deck.png`
   - Candidate card ưu tiên ảnh và thông tin quyết định nhanh.
   - Action bar luôn ở vùng dễ với.
8. `08-doi-profile-detail.png`
   - Chia section rõ, không thêm field.
9. `09-match-celebration.png`
   - Motion nổi bật; giữ chat/continue actions.
10. `10-explore-themes.png`
   - Card/chip hierarchy rõ; giữ filter và selection behavior.

### 7.3 Kèo/chat — 11–17

11. `11-keo-board.png`
   - TicketCard thống nhất hierarchy thời gian, địa điểm, thành viên và trạng thái.
12. `12-keo-auto-match.png`
   - Giữ input, matching rule và result behavior.
13. `13-create-keo.png`
   - Form grouping rõ; giữ field, validation và submit.
14. `14-keo-detail.png`
   - Giữ host/member permissions và action.
15. `15-inbox.png`
   - Tách rõ chat Đôi/Kèo; giữ unread và routing meaning.
16. `16-chat-1to1.png`
   - Timeline dễ đọc; composer ổn định khi mở keyboard.
17. `17-keo-group-chat.png`
   - Sender identity rõ; giữ message ordering và group behavior.

### 7.4 Profile/plan/commerce/settings — 18–22

18. `18-profile.png`
   - Tổng quan hồ sơ, completion và PRO rõ.
19. `19-plan-map.png`
   - Cân bằng map với venue/action card; không đổi map logic.
20. `20-booking-payment.png`
   - Chỉ hiển thị capability hiện có và tôn trọng feature flag.
21. `21-store.png`
   - Làm rõ value, price và CTA; không đổi product/entitlement.
22. `22-settings.png`
   - Nhóm cài đặt rõ; thao tác nguy hiểm được phân tách và xác nhận như hiện tại.

## 8. Data flow và hành vi

```text
Provider hiện có
  ├─ AsyncData  → screen/section render dữ liệu
  ├─ AsyncLoading → skeleton có cùng geometry
  └─ AsyncError → EmptyState/error panel + retry callback hiện có

User action
  → callback từ presentation widget
  → screen wiring gọi controller/provider hiện có
  → state mới render lại presentation
```

- Không gọi data layer trong shared widget hoặc feature section.
- Không thay đổi thứ tự message, membership, entitlement hoặc permission.
- Không đổi feature flag.
- Không đổi analytics event hoặc thời điểm nghiệp vụ của event.
- Microcopy có thể được chỉnh cho rõ nhưng phải giữ nguyên ý nghĩa và hành động.

## 9. Tổ chức triển khai nội bộ

Mặc dù người dùng chỉ duyệt khi hoàn tất toàn bộ, việc triển khai được chia thành bốn gói:

1. Foundations, app shell và auth/onboarding.
2. Đôi/discovery.
3. Kèo/inbox/chat.
4. Profile/plan/booking-payment presentation/store/settings.

Mỗi gói có test và review nội bộ riêng. Không trình người dùng duyệt giữa các gói.

## 10. Kiểm thử

### 10.1 Baseline

- Giữ toàn bộ 437 Flutter test hiện đang pass.
- Không chấp nhận regression bị che bằng cách xóa hoặc làm yếu assertion.

### 10.2 Presentation tests

- Widget test cho từng screen và shared component được viết lại.
- Giữ các key, semantic label và callback behavior quan trọng.
- Test loading, empty, error, disabled, selected và permission-specific state phù hợp.

### 10.3 Responsive và platform

- Test 360dp, 393dp, 430dp.
- Test text scale 1.0, 1.2 và 1.4.
- Test Android và `TargetPlatform.iOS`.
- Mobile web chạy trên Chrome.
- Kiểm tra pointer, keyboard, focus order và swipe fallback trên web.

### 10.4 Visual verification

- Chạy các luồng chính trên Android emulator `emulator-5554`.
- Chụp đủ 22 màn hình.
- So sánh với `docs/redesign-mockups/`.
- Ghi lại khác biệt có chủ đích.
- Kiểm tra không overflow, clipped CTA, keyboard obstruction hoặc layout shift.

### 10.5 Backend boundary audit

Trước khi bàn giao, Git diff phải xác nhận không có thay đổi trong:

- `supabase/`
- `lib/features/**/data/`
- `lib/features/**/domain/`
- `lib/features/**/application/`
- Route/redirect logic
- Repository/API/model/serialization

## 11. Tiêu chí hoàn thành

- Đủ 22 màn hình.
- Bám art direction của mockup theo chiến lược hybrid.
- Shared component và token nhất quán.
- Android, iOS presentation tests và mobile web không overflow.
- Loading/empty/error/disabled state đầy đủ.
- 437 baseline test và test mới pass.
- Không sửa backend hoặc business logic.
- Có ảnh trước/sau và báo cáo test cuối.
- Người dùng chỉ được yêu cầu duyệt sau khi toàn bộ 22 màn hình hoàn tất.
