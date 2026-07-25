# Bàn giao: đợt sửa 6 lỗ hổng sản phẩm

Dán file này vào thư mục gốc repo (hoặc dán nội dung làm prompt đầu tiên cho Claude Code).

## Việc cần làm ngay

```bash
flutter gen-l10n     # không bắt buộc: file sinh đã được đồng bộ tay, lệnh này chỉ để xác nhận
dart format lib test # chưa chạy được ở phiên trước
flutter analyze
flutter test
```

Đợt sửa trước **không chạy được test** (máy ảo không có Flutter). Mới chỉ kiểm bằng script:
cân bằng ngoặc, thứ tự tham số vị trí/tên, và toàn vẹn khóa l10n trên cả 5 file.
Nên coi như code **chưa được biên dịch lần nào**.

## Hai chỗ dễ vỡ nhất

1. **`chat_screen.dart`** — AppBar giờ có 4 action. Ở 360dp × textScale 1.4 ước tính
   còn dư ~30dp. Nếu tràn: bỏ nút "Lập kèo" khỏi AppBar, đưa vào overflow menu.
2. **`keo_match_sheet.dart`** — sheet cao thêm ~87dp. Test nào tap nút "Tham gia"
   có thể trượt nếu nút bị đẩy khỏi vùng hiển thị.

## Đã thay đổi những gì

### l10n (5 file, 36 khóa mới + 2 khóa đổi giá trị)
`lib/l10n/app_en.arb`, `app_vi.arb`, `app_localizations.dart`,
`app_localizations_en.dart`, `app_localizations_vi.dart`

Hai khóa **đổi giá trị** (không phải thêm mới):
- `bookVenue`: "Đặt phòng & giữ chỗ" → "Thanh toán tại quán qua MoMo/ZaloPay"
- `consentCrossBorder`: bỏ phần gộp Điều khoản + Bảo mật, chỉ còn nói về việc lưu
  dữ liệu tại Singapore

### Paywall — nguy cơ bị store từ chối
- `billing/application/iap_controller.dart`
  - thêm `restore()` (Apple 3.1.1 bắt buộc với non-consumable; trước đây không tồn tại)
  - xử lý `pending` / `error` / `canceled` — trước đây giao dịch lỗi không bao giờ
    `completePurchase()` nên store phát lại mỗi lần mở app
  - `localizedPrices()` + `storePricesProvider`: lấy giá từ store thay vì giá server
  - `iapEventProvider` để UI phản hồi kết quả thanh toán
- `billing/presentation/store_screen.dart`
  - kỳ hạn giá ("Mua một lần · vĩnh viễn" / "· hiệu lực 24 giờ")
  - nút Khôi phục mua hàng, link Điều khoản + Bảo mật, ghi chú không tự động gia hạn
  - trạng thái "Đã sở hữu" (non-consumable), SnackBar theo `iapEventProvider`
  - **giữ nguyên** `formatPriceK` làm fallback để 4 assertion `'199k'` trong
    `store_screen_test.dart` không vỡ

### Consent (chọn phương án vá tối thiểu, giữ UI gộp)
- `onboarding/presentation/consent_step.dart`
  - nhãn `cross_border` chỉ còn nói về lưu dữ liệu tại Singapore
  - nút gộp chỉ bật `requiredConsents`, **không** đụng marketing
  - thêm dòng `consent_tos_notice` nêu riêng Điều khoản + Bảo mật
- `test/features/onboarding/consent_step_test.dart` — cập nhật test P2-b (đang khoá
  hành vi cũ) + thêm 2 test khoá hành vi mới

### An toàn
- `discovery/presentation/report_sheet.dart` — thêm `onBlocked`, invalidate inbox
- `discovery/presentation/candidate_detail_sheet.dart` — nút báo cáo lên header
  (giữ nguyên nút cuối trang)
- `chat/presentation/chat_screen.dart` — nút an toàn trong AppBar, vẫn dùng được
  khi không tải được hồ sơ đối phương
- `keo/presentation/keo_chat_screen.dart` — nút an toàn + bước chọn thành viên
- `plan/presentation/plan_screen.dart` — nút an toàn + chọn thành viên

### Ghép nhóm & khác
- `keo/presentation/keo_match_sheet.dart` — `_index` duyệt cả danh sách gợi ý
  (trước chỉ dùng `.first`), nút "Xem gợi ý khác", nút xem chi tiết kèo không cần join
- `keo/presentation/keo_board_screen.dart` — truyền `onViewDetail`
- `discovery/presentation/theme_board_screen.dart` — `counts.when()` thay `counts.value`,
  loading hiện Skeleton, `'—'` chỉ còn dành cho lỗi
- `onboarding/presentation/onboarding_flow.dart` — chặn hoàn tất khi chưa chọn đủ
  3 thể loại (bằng SnackBar, **không** khoá nút), bộ đếm "Đã chọn n", câu nhắc
- `plan/presentation/booking_button.dart` — đổi nhãn, đổi icon, báo lỗi khi
  `canLaunchUrl` false (trước đây im lặng hoàn toàn), thêm ghi chú không giữ chỗ

## Chưa làm

- **`/admin` là route mồ côi** — không có lối vào nào từ UI. Cần thêm tile có kiểm
  quyền trong Cài đặt, hoặc bỏ route.
- **Màn kế hoạch** thiếu: huỷ/sửa kế hoạch (`plan_repository` chỉ có
  propose/confirm/checkin/share — "sửa" hiện tạo bản ghi mới, bản cũ mồ côi),
  danh sách ai đã xác nhận, thêm vào lịch, nhắc trước giờ hẹn.
  `SafetyToolkit` chỉ hiện khi `status == 'confirmed'` — giai đoạn đang cân nhắc
  gặp người lạ thì không có gì.
- **Khóa `keoMatchMembersLabel` đã thêm nhưng chưa dùng**: model `KeoMatchSuggestion`
  không có dữ liệu thành viên, roster nằm ở `KeoRepository.roster(keoId)`.
- **Toàn app không có `RefreshIndicator`** — không màn nào kéo-để-làm-mới.
- **Danh sách "Đã chặn"** trong Cài đặt chưa có.

## Ba cáo buộc đã bị bác bỏ (đừng sửa lại)

1. "Thiếu trạng thái rỗng/lỗi/offline" — đủ ở 4/5 màn; có `location_error_state`
   phân 4 nguyên nhân, `keo_errors` map 12 mã, `discovery_errors` map 6 mã.
2. "Onboarding thiếu bước ảnh" — có, nằm trong luồng, tự đẩy tới sau submit
   (`onboarding_flow.dart` → `/onboarding/photos`), có nhắc lại ở Hồ sơ.
3. "Store không có đường vào" — có 3: `profile_screen`, `keo_board_screen`,
   `pro_upsell_sheet`.
