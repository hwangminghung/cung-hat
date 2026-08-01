# Quyết định: Thanh toán v1 (2026-07-10)

Bối cảnh: chưa liên hệ được quán để đặt cọc giữ chỗ; redesign mockup màn 20 đang vẽ "Đặt phòng & giữ chỗ" + sheet MoMo/ZaloPay. User chốt hướng v1.

## QĐ1 — Màn Kế hoạch v1: KHÔNG có thanh toán

- "Chốt quán" chỉ là chọn địa điểm → hiện **Chỉ đường · Gọi quán · Lưu lịch**. Không có chữ "Đặt phòng" ở bất kỳ đâu khi chưa có hợp đồng quán (tránh user hiểu nhầm quán đã giữ chỗ).
- Chống no-show bằng cơ chế phi tiền tệ đã có sẵn: all-confirm + check-in bằng ảnh (sign-photo) + điểm uy tín kèo.
- Toàn bộ flow cọc (create-venue-payment, webhook, BookingButton) **giữ nguyên code, giấu sau feature flag** — KHÔNG xóa.
  - Việc cần làm: `BookingButton` đang render vô điều kiện tại `lib/features/plan/presentation/plan_screen.dart:166` → thêm flag (dart-define `BOOKING_ENABLED`, mặc định false) để ẩn.
- v1.5 (cọc app-side 10–20k hoàn khi check-in, không cần quán) = HOÃN, chỉ mở lại khi có merchant MoMo/ZaloPay + chính sách hoàn/mất cọc trong T&C.
- v2 (booking thật với quán) = chỉ sau khi có số liệu kèo đổ về quán cụ thể để đàm phán.

## QĐ2 — Kênh bán Pro/boost/see-likes/filters (hàng số)

Giữ nguyên store-policy split của spec maps-payments (2026-07-07): **hàng số trong app → CHỈ IAP**. MoMo/ZaloPay/chuyển khoản cho hàng số **trong app là vi phạm** Apple 3.1.1 / Google Play Payments policy → nguy cơ bị từ chối/gỡ app.

Cách dùng MoMo/ZaloPay/CK ngân hàng **hợp lệ**: bán qua **web portal ngoài app** (web mua → server cấp entitlement vào tài khoản → app tự thấy Pro). Ràng buộc anti-steering: trong app KHÔNG được đặt nút/link/text dẫn sang web mua; quảng bá web portal qua kênh ngoài (TikTok, fanpage, Zalo OA) thì thoải mái.

Lộ trình:
1. **Launch: IAP-only** (validate-iap fail-closed đã build; gate còn thiếu = tài khoản App Store Connect + Play Console, 4 product id `com.cunghat.boost/see_likes/filters/pro`).
2. **Sau launch: web portal** tái dùng nguyên create-order/webhook MoMo/ZaloPay đã viết (đổi mục đích từ cọc quán → mua gói trên web). Thêm CK ngân hàng bằng VietQR + đối soát tự động (Casso/SePay) — 0% phí gateway.

## Ảnh hưởng lên redesign mockups (docs/redesign-mockups)

- Màn 20 (booking-payment): vẽ lại theo QĐ1 — bỏ sheet cổng thanh toán, thay bằng khối "Đã chốt quán" + 3 hành động Chỉ đường/Gọi quán/Lưu lịch.
- Màn 21 (store): giữ nguyên UI, mọi nút Mua đi qua IAP; không hiển thị logo MoMo/ZaloPay ở store trong app.
