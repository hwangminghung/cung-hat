# Gói bàn giao Cùng Hát cho Claude Design

**Ngày:** 2026-07-19  
**Trạng thái:** Đã được người dùng duyệt trong hội thoại  
**Phạm vi:** Chuẩn bị design system và ngữ cảnh để Claude Design cải thiện toàn bộ 22 màn hình mobile hiện có

## 1. Mục tiêu

Tạo một gói đầu vào chọn lọc để Claude Design hiểu đúng giao diện Cùng Hát mà không cần đọc toàn bộ
repository Flutter/Supabase.

Claude Design phải:

- Giữ nguyên ngôn ngữ hình ảnh **retro mixtape** hiện có.
- Dùng design system và component hiện có làm nguồn chuẩn.
- Cải thiện bố cục, phân cấp thông tin, khả năng đọc, responsive và accessibility.
- Tạo đủ 22 màn hình tham chiếu.
- Giữ nguyên luồng, tính năng, hành động, nội dung và dữ liệu hiện có.

Claude Design không được:

- Thêm tính năng, loại dữ liệu, màn hình hoặc nhánh điều hướng mới.
- Thay đổi ý nghĩa CTA hoặc thứ tự các bước trong luồng.
- Tự tạo màu, font, component hoặc hiệu ứng nằm ngoài design system.
- Dùng glassmorphism, gradient tùy ý, shadow mờ, emoji làm icon hoặc phong cách template AI chung chung.
- Sửa trực tiếp code ứng dụng trong giai đoạn thiết kế.

## 2. Nguồn chuẩn

Gói bàn giao lấy dữ liệu từ các nguồn hiện có:

- `design-system/MASTER.md`: nguyên tắc và quy tắc tổng thể.
- `lib/core/theme/`: token màu, typography, spacing, shadow, motion và cấu hình Material theme.
- `lib/shared/widgets/`: component dùng chung đã triển khai trong Flutter.
- `docs/redesign-mockups/`: 22 ảnh tham chiếu, đánh số từ `01` đến `22`.
- Các file font trong `google_fonts/`: Oswald và Be Vietnam Pro.

Các nguồn trên tiếp tục là nguồn chuẩn. Gói Claude Design là lớp chuyển đổi phục vụ import, không trở
thành một design system song song.

## 3. Phương án được chọn

Sử dụng **gói bàn giao chọn lọc** thay vì import toàn bộ repository.

Lý do:

- Tập trung ngữ cảnh của Claude vào UI thay vì backend, migration, test và logic nghiệp vụ.
- Giảm rủi ro tải chậm hoặc vượt giới hạn khi import codebase lớn.
- Loại trừ khóa môi trường và dữ liệu không liên quan.
- Cho phép kiểm tra rõ Claude đã nhận đúng token, component và từng màn hình.
- Dễ tái tạo gói mới khi design system trong code thay đổi.

Import toàn bộ repository không được dùng trong lượt thiết lập đầu tiên. Tích hợp Claude Code
`/design-sync` có thể được cân nhắc sau khi gói chọn lọc đã được kiểm chứng.

## 4. Kiến trúc gói bàn giao

Tạo lớp adapter dưới `design-system/claude-design/`:

```text
design-system/claude-design/
├── README.md
├── brand-brief.md
├── design-tokens.json
├── component-catalog.md
├── screen-manifest.md
├── constraints.md
├── upload-checklist.md
└── prompts/
    ├── 00-create-design-system.md
    ├── 01-auth-onboarding.md
    ├── 02-discovery.md
    ├── 03-keo-chat.md
    ├── 04-profile-plan-commerce.md
    └── 05-final-audit.md
```

Thêm script PowerShell tạo artifact cục bộ:

```text
scripts/build_claude_design_bundle.ps1
```

Script tập hợp:

- Tài liệu adapter.
- Token và component Flutter liên quan.
- Font cần thiết.
- 22 mockup tham chiếu.

Artifact được sinh vào thư mục build đã bị Git bỏ qua:

```text
build/claude-design/
├── Cung-Hat-Claude-Design/
└── Cung-Hat-Claude-Design.zip
```

Không sao chép 22 ảnh vào một thư mục được commit. Script chỉ tạo bản sao cục bộ khi cần upload.

## 5. Nội dung adapter

### 5.1 Brand brief

`brand-brief.md` mô tả:

- Sản phẩm gặp gỡ người lạ theo gu âm nhạc để hát karaoke cùng nhau.
- Đối tượng chính tại Việt Nam và tiếng Việt là ngôn ngữ giao diện mặc định.
- Cá tính retro mixtape: giấy kem ấm, ink xanh đậm, cam citrus, lime và teal.
- Cảm giác mong muốn: thân thiện, giàu năng lượng, có chất thủ công nhưng vẫn rõ ràng và an toàn.
- Những đặc điểm bị cấm để ngăn Claude trôi sang phong cách generic.

### 5.2 Design tokens

`design-tokens.json` biểu diễn có cấu trúc:

- Màu và vai trò semantic.
- Typography scale và font weight.
- Spacing scale.
- Radius và kích thước component.
- Viền và hard shadow.
- Motion duration/easing.
- Breakpoint kiểm tra.

Giá trị phải khớp với `lib/core/theme/`. Không đưa vào token giá trị chưa tồn tại trong code.

### 5.3 Component catalog

`component-catalog.md` liệt kê component dùng chung và hợp đồng sử dụng:

- `AppLogo`
- `GradientButton`
- `HardCard`
- `Pressable`
- `OtpInput`
- `EmptyState`
- `Skeleton`, `SkeletonTile`, `SkeletonCard`
- `SectionHeader`
- `TabHeader`, `HeaderActionButton`
- `StampChip`
- `TicketCard`
- `WaveDivider`
- `WaveProgress`
- `ProUpsellSheet`

Mỗi mục ghi mục đích, biến thể hợp lệ, token bắt buộc, trạng thái và anti-pattern. Claude được tái sử
dụng hoặc kết hợp component nhưng không được tự tạo một ngôn ngữ component mới.

### 5.4 Screen manifest

`screen-manifest.md` ánh xạ từng ảnh với mục đích và nhóm luồng:

1. `01-login.png`
2. `02-otp.png`
3. `03-onboarding-dob.png`
4. `04-onboarding-consent.png`
5. `05-onboarding-profile.png`
6. `06-onboarding-music-taste.png`
7. `07-doi-deck.png`
8. `08-doi-profile-detail.png`
9. `09-match-celebration.png`
10. `10-explore-themes.png`
11. `11-keo-board.png`
12. `12-keo-auto-match.png`
13. `13-create-keo.png`
14. `14-keo-detail.png`
15. `15-inbox.png`
16. `16-chat-1to1.png`
17. `17-keo-group-chat.png`
18. `18-profile.png`
19. `19-plan-map.png`
20. `20-booking-payment.png`
21. `21-store.png`
22. `22-settings.png`

Mỗi màn hình ghi:

- Vai trò trong luồng.
- Thành phần chính.
- CTA và điều hướng bắt buộc giữ nguyên.
- Component nên tái sử dụng.
- Các trạng thái loading, empty, error hoặc disabled nếu áp dụng.
- Những điểm được phép cải thiện.

### 5.5 Constraints

`constraints.md` đặt các ràng buộc:

- Mobile portrait là nền tảng chính.
- Thiết kế ở 360px và kiểm tra lại ở 390px, 430px.
- Touch target tối thiểu 44px.
- Body text tối thiểu 13px.
- Contrast text thông thường tối thiểu 4.5:1.
- Tôn trọng font scale lớn và reduced motion.
- Không dùng màu làm tín hiệu duy nhất.
- Loading danh sách dùng skeleton; empty state có hướng hành động rõ.
- Giao diện mặc định là light mode.

## 6. Luồng sử dụng trong Claude Design

### Bước A: Tạo design system

1. Mở tab **Design systems**.
2. Tạo `Cùng Hát — Retro Mixtape`.
3. Import brand brief, token, component catalog, theme Flutter và font.
4. Yêu cầu Claude tạo mẫu kiểm chứng cho Button, Card, Input và Chip.
5. So sánh palette, font, viền và shadow với nguồn chuẩn.

Không bắt đầu 22 màn hình nếu bước kiểm chứng chưa đạt.

### Bước B: Tạo project

1. Tạo project mobile app design mới.
2. Gắn design system `Cùng Hát — Retro Mixtape`.
3. Import `screen-manifest.md`, `constraints.md` và 22 mockup.
4. Gửi prompt theo bốn nhóm trong cùng một project:
   - Màn 01–06: đăng nhập và onboarding.
   - Màn 07–10: khám phá và ghép đôi.
   - Màn 11–17: Kèo và trò chuyện.
   - Màn 18–22: hồ sơ, kế hoạch, thanh toán, cửa hàng và cài đặt.
5. Sau mỗi nhóm, chạy kiểm tra design-system compliance trước khi tiếp tục.

### Bước C: Audit cuối

Prompt cuối phải kiểm tra xuyên suốt 22 màn hình:

- Đủ số lượng và đúng tên.
- Navigation và CTA không đổi.
- Component được tái sử dụng nhất quán.
- Token không bị tự ý mở rộng.
- Khoảng cách, hierarchy và typography nhất quán.
- Responsive và accessibility đạt constraint.
- Nội dung tiếng Việt không bị dịch hoặc viết lại sai nghĩa.

## 7. Xử lý lỗi

- Nếu Claude không nhận font, upload trực tiếp các file TTF và nhắc lại mapping font role.
- Nếu giới hạn upload không cho phép 22 ảnh cùng lúc, dùng bốn thư mục nhóm; tất cả vẫn nằm trong
  cùng một project.
- Nếu Claude tạo màu/component ngoài hệ thống, dùng prompt audit để sửa trên thiết kế hiện tại thay
  vì sinh lại toàn bộ.
- Nếu một màn hình cần dữ liệu không có trong manifest, giữ placeholder được chỉ định và ghi chú;
  không sáng tác dữ liệu hoặc tính năng.
- Nếu import ZIP không được hỗ trợ ở giao diện hiện tại, dùng thư mục đã giải nén trong
  `build/claude-design/Cung-Hat-Claude-Design/`.
- Nếu upload ảnh dung lượng lớn thất bại, giữ nguyên kích thước ảnh gốc làm nguồn chuẩn và tạo bản
  sao tối ưu hóa chỉ trong artifact build.

## 8. Kiểm tra và tiêu chí hoàn thành

### Kiểm tra artifact

- Script chạy thành công từ repository root trên Windows PowerShell.
- Artifact chứa đúng các file adapter, source UI, font và 22 ảnh.
- Artifact không chứa `.env`, `env/dev.json`, Supabase, migration, build ứng dụng hoặc khóa bí mật.
- Danh sách ảnh trong artifact khớp manifest, không thiếu hoặc trùng.
- JSON hợp lệ và giá trị token khớp code.

### Kiểm tra trong Claude Design

- Design system hiển thị đúng màu gốc.
- Oswald dùng cho heading; Be Vietnam Pro dùng cho body.
- Button/Card/Input/Chip mẫu có viền 2px, radius đúng và hard shadow không blur.
- Project gắn đúng design system.
- Có đủ 22 màn hình.
- Không thêm tính năng, route hoặc dữ liệu mới.
- Các màn hình hoạt động ở 360px và giữ cấu trúc ở 390px/430px.
- CTA, trạng thái và nội dung tiếng Việt giữ đúng ý nghĩa.

### Điều kiện chuyển sang code

Chỉ handoff sang Flutter sau khi người dùng duyệt:

- Một mẫu kiểm chứng design system.
- Bốn nhóm màn hình.
- Audit cuối xuyên suốt 22 màn hình.

Việc triển khai thiết kế vào Flutter là một kế hoạch riêng và nằm ngoài phạm vi của gói bàn giao này.

