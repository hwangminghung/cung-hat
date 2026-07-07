# Spec: Tích hợp thật Google Maps + Thanh toán (Maps + Payments)

**Ngày:** 2026-07-07 · **Nhánh:** `feat/maps-payments` (từ `origin/master` = `251bd7d2`, sau merge filter-radius-perf)
**Tiền đề:** P4 (venues/plan/map surface) + P6 (monetization rails) đã xây khung. Đợt này KHÔNG làm lại — chỉ thay placeholder bằng tích hợp thật, fail-closed khi thiếu credential.

## 1. Mục tiêu & nguyên tắc

1. **Google Maps:** map native chạy thật trong PlanScreen (widget đã có, đang tắt sau cờ `GOOGLE_MAPS_ENABLED`), vẽ thêm **pin midpoint đã tính** + fit camera; wiring key iOS còn thiếu; Places ingestion sẵn sàng chạy ngay khi có billing key.
2. **Thanh toán:** thay MỌI placeholder bảo mật bằng code thật:
   - `validate-iap`: verify receipt thật (Apple + Google) trước khi cấp entitlement.
   - `create-venue-payment`: gọi create-order thật MoMo/ZaloPay (chữ ký HMAC thật), số tiền do **server quyết**.
   - `payments-webhook`: verify chữ ký HMAC thật trước khi ghi `paid`.
3. **Fail-closed:** thiếu env credential → trả 503 `*_not_configured`, KHÔNG BAO GIỜ cho qua. (Học pattern env-check từ nhánh kho `codex/operator-gates-wip` — nhánh đó chỉ có stub 501/503, không có verification thật; ta viết verification thật phía sau gate.)
4. **Store-policy split GIỮ NGUYÊN:** hàng số (boost/Pro/see-likes/filters) → CHỈ IAP; dịch vụ thật (đặt phòng music box) → CHỈ MoMo/ZaloPay. Không trộn.
5. **Riêng tư bản đồ:** map chỉ vẽ pin venue + midpoint đã tính (snap lưới); KHÔNG BAO GIỜ chấm vị trí thật thành viên.

## 2. Hiện trạng đã khảo sát (2026-07-07)

| Mảnh | Trạng thái |
|---|---|
| `google_maps_flutter ^2.17.1` | Đã trong pubspec |
| `VenueMapSurface` (lib/features/plan/presentation/venue_map_surface.dart) | Đã có: GoogleMap native sau cờ compile-time `GOOGLE_MAPS_ENABLED` + fallback pseudo-map painted; dùng trong PlanScreen |
| Android Maps key | Đã wiring: manifest `com.google.android.geo.API_KEY` = `${MAPS_API_KEY}` ← local.properties / gradle property / env (build.gradle.kts) |
| iOS Maps key | **THIẾU** — AppDelegate chưa gọi `GMSServices.provideAPIKey` |
| `nearest_venues_for_keo` | Đã trả lat/lng venue (20260629023800); midpoint tính nội bộ, KHÔNG trả ra |
| `ingest-places-venues` | Code thật, secret-gated, chỉ searchNearby `karaoke`; cần `GOOGLE_PLACES_API_KEY` (billing) |
| `validate-iap` | **Placeholder**: `Boolean(receipt && store_txn_id)` — nhận mọi receipt không rỗng |
| `create-venue-payment` | **Placeholder**: pay_url giả `sandbox.pay.local`; tin `amount_minor` từ client |
| `payments-webhook` | **Placeholder**: `Boolean(gateway_ref)` — nhận mọi IPN |
| `IapController` | Chạy được nhưng `_storeProductIds` hardcode (TODO query bảng products — products có RLS read + đủ cột) |
| `venues` | KHÔNG có cột giá/deposit |
| `codex/operator-gates-wip` | Stub fail-closed 501/503 (không implement); manifest `cunghat://` + Info.plist + harden_rls migration — tham khảo, không merge |

## 3. Ba phương án đã cân

- **A. Chỉ fail-closed stub (đường Codex):** an toàn nhưng không tích hợp gì — khi có credential vẫn phải viết code từ đầu. Loại.
- **B. Code thật sau gate env + verify bằng sandbox/self-signed (CHỌN):** crypto + API call viết thật, test được ngay bằng (i) HMAC tự ký với secret dummy đặt trong env local — thuật toán thật, chỉ khóa là dummy; (ii) sandbox công khai MoMo/ZaloPay (creds sandbox công bố trong docs dev của họ) cho create-order end-to-end nếu mạng cho phép. Khi user đưa credential thật → chỉ đổi env, không đổi code.
- **C. Chờ đủ merchant credential mới code:** chặn toàn bộ đợt vì 3 gate đều là thủ tục bên ngoài. Loại.

## 4. Thiết kế — mảng Maps

### M1. Midpoint pin + camera fit
- **DB:** RPC mới `get_keo_midpoint(p_keo uuid)` → `(lat double precision, lng double precision)`; SECURITY DEFINER, `in_keo`-gated; tính `ST_GeometricMedian` trên vị trí thành viên approved+confirmed (đúng công thức `nearest_venues_for_keo` đang dùng nội bộ); **`round(...,3)` (~110m)** trước khi trả — cùng mức snap với `user_locations` lúc ghi, không khuếch đại độ chính xác. Trả NULL khi chưa ai có vị trí.
  - *Caveat riêng tư đã chấp nhận:* kèo 2 người thì midpoint suy ngược được vùng ~trăm mét của người kia — cùng độ thô với `dist_band` hiện hữu; snap giữ ở mức lưới, không lộ toạ độ thật (toạ độ gốc vốn cũng đã snap ~100m lúc ghi).
- **Flutter:** `VenueMapSurface` nhận `midpoint` optional → native: `Marker` màu khác (điểm hẹn giữa nhóm) + `CameraUpdate.newLatLngBounds` bao venues+midpoint; fallback: chấm midpoint trên pseudo-map. PlanScreen watch provider mới `keoMidpointProvider(keoId)`.

### M2. iOS Maps key wiring (code-only, không build được trên Windows)
- `ios/Runner/AppDelegate.swift`: `import GoogleMaps` + `GMSServices.provideAPIKey(key)` đọc từ Info.plist key `GMapsAPIKey`; Info.plist thêm `GMapsAPIKey = $(MAPS_API_KEY)` (xcconfig). Không có key → skip provideAPIKey (map iOS trắng nhưng app không crash, cờ `GOOGLE_MAPS_ENABLED` vẫn tắt native map).

### M3. Env + docs
- Thêm `GOOGLE_MAPS_ENABLED: false` vào cả 4 file `env/dev*.json` (hiện chỉ example có). LAUNCH.md: mục "Bật Google Maps" — checklist đặt `MAPS_API_KEY` (android/local.properties + iOS xcconfig + không commit), lật cờ, rebuild.

### M4. Places ingestion nâng cấp "music box"
- `ingest-places-venues` thêm mode `textQuery` (Places New `places:searchText` với "music box"/"karaoke box"/"phòng hát mini") bên cạnh searchNearby — phục vụ cả ingest venue lẫn đếm mật độ pocket (market research). Giữ secret gate + upsert theo `places_id` như cũ.

### Gate credential Maps (DỪNG hỏi user khi tới)
> Google Maps Platform billing (lưu ý account chính vùng Ấn Độ cần Maps-billing riêng — account `…1412@gmail.com` vùng US ít ma sát hơn) + 2 key: **Places server key** (edge env `GOOGLE_PLACES_API_KEY`) và **Maps SDK key Android/iOS** (`MAPS_API_KEY`). Khi có: lật `GOOGLE_MAPS_ENABLED=true`, rebuild, verify map native trên emulator; chạy `scripts/run_places_ingest.sh` per city.

## 5. Thiết kế — mảng Thanh toán

### I1. `validate-iap` — verify receipt thật
- **Google (android):** tạo OAuth2 JWT (RS256) từ service account `GOOGLE_PLAY_SA_JSON` (env) → `androidpublisher.googleapis.com purchases.products.get(ANDROID_PACKAGE_NAME, productId, purchaseToken=receipt)` → chỉ nhận `purchaseState==0`; acknowledge nếu `acknowledgementState==0`. Sai/thiếu → 400 `invalid_receipt`.
- **Apple (ios):** nhận cả 2 định dạng từ `in_app_purchase`: (a) receipt **JWS StoreKit2** (3 đoạn `.`) → verify chuỗi x5c về **Apple Root CA G3 ghim sẵn** + khớp `bundleId` (env `APP_BUNDLE_ID`) + `transactionId`/`productId` khớp body; (b) receipt base64 legacy → POST `verifyReceipt` với `APPLE_SHARED_SECRET` (thử prod trước, 21007 → sandbox), tìm đúng transaction trong `latest_receipt_info`.
- **Fail-closed:** thiếu env cho platform tương ứng → 503 `iap_verifier_not_configured`. Giữ nguyên logic cấp quyền hiện có (products lookup → purchases upsert → entitlements upsert, boost=24h).
- Validate input đủ trường + platform hợp lệ (nhận pattern từ stub Codex).

### I2. `IapController` query catalog từ bảng `products`
- Bỏ `_storeProductIds` hardcode → đọc `products` (RLS read sẵn) lọc theo platform hiện tại, map `type → store_product_id`. Đóng deferred P6.

### P1. Server quyết số tiền đặt cọc
- Migration: `venues.booking_deposit_minor int not null default 200000` (VND — không có đơn vị lẻ, minor = đồng).
- `create-venue-payment` **bỏ hẳn** `amount_minor` từ client — đọc từ row venue. `BookingButton`/`PlanRepository.startVenuePayment` bỏ tham số amount. Đóng lỗ "client tự ra giá".

### P2. `create-venue-payment` — create-order thật
- **MoMo:** POST `{MOMO_ENDPOINT}/v2/gateway/api/create` (env; sandbox `test-payment.momo.vn`, prod `payment.momo.vn`), `requestType=captureWallet`, chữ ký HMAC-SHA256 trên chuỗi param thứ tự alphabet với `MOMO_ACCESS_KEY`/`MOMO_SECRET_KEY`/`MOMO_PARTNER_CODE`; `redirectUrl`/`ipnUrl` từ env (`PAYMENTS_REDIRECT_URL`, `PAYMENTS_WEBHOOK_URL`); trả `payUrl` thật của gateway.
- **ZaloPay:** POST `{ZALOPAY_ENDPOINT}/v2/create` (sandbox `sb-openapi.zalopay.vn`), `app_trans_id = yymmdd_<ref>`, `mac = HMAC-SHA256(app_id|app_trans_id|app_user|amount|app_time|embed_data|item, ZALOPAY_KEY1)`, `callback_url` từ env; trả `order_url`.
- Booking row ghi TRƯỚC khi gọi gateway (state `initiated`, `gateway_ref` = mã đối chiếu — MoMo `orderId`, ZaloPay `app_trans_id`); gateway lỗi → booking `failed` + trả lỗi.
- **Fail-closed:** thiếu bộ env gateway tương ứng → 503 `payment_gateway_not_configured`.
- **UI:** BookingButton mở sheet chọn **MoMo / ZaloPay** (2 nút, ZaloPay hết hardcode).

### P3. `payments-webhook` — verify chữ ký thật + idempotent
- Phân biệt gateway bằng query `?gateway=momo|zalopay` (đặt trong ipnUrl/callback_url do ta tự cấu hình).
- **MoMo IPN v2:** dựng lại raw signature string theo thứ tự alphabet field chuẩn MoMo (`accessKey`, `amount`, … `transId`) → HMAC-SHA256 với `MOMO_SECRET_KEY` → so `signature`; lệch → 401, không đụng DB. `resultCode==0` → paid. Response 204.
- **ZaloPay callback:** `mac == HMAC-SHA256(data, ZALOPAY_KEY2)`; lệch → trả `return_code:-1`. Parse `data` JSON → `app_trans_id` → booking. `status==1`/success → paid. Response JSON `{return_code:1}` đúng spec để ZaloPay ngừng retry.
- **Idempotent + đối chiếu:** chỉ chuyển `initiated → paid|failed`; booking đã `paid` thì bỏ qua (200); **so khớp amount** IPN với `venue_bookings.amount_minor`, lệch → log + `failed`. Commission 10% giữ nguyên khi paid.
- **Fail-closed:** thiếu env secret gateway → 503.

### P4. Harness verify local (không fake)
- `scripts/verify_payments_local.sh` (Git Bash + openssl + curl): nạp secret **dummy documented** vào `supabase/functions/.env` → `supabase functions serve` → (1) tự ký payload IPN MoMo/ZaloPay bằng đúng thuật toán + secret dummy → webhook phải NHẬN; (2) sửa 1 byte → phải TỪ CHỐI 401; (3) thiếu env → 503; (4) validate-iap thiếu env → 503, receipt rác → 400. Crypto là thật — chỉ khóa là dummy.
- **(Tùy mạng)** create-order chạy thử bằng **sandbox creds công khai** của MoMo/ZaloPay (in trong docs dev chính hãng) → nhận `payUrl` thật từ sandbox. Không được thì dừng ở mức unit self-signed — vẫn đạt "không fake verify".
- Kết quả ghi `docs/verify-maps-payments-<date>.md`.

### Gate credential Thanh toán (DỪNG hỏi user khi tới)
> 1. **IAP:** tài khoản App Store Connect + Play Console, tạo 4 product id (`com.cunghat.boost/see_likes/filters/pro`), cấp `APPLE_SHARED_SECRET` (hoặc App Store Server API key), `GOOGLE_PLAY_SA_JSON` + package name. Test mua thật cần build store + sandbox tester (emulator google_apis KHÔNG có Play Store — không test mua trên emulator được).
> 2. **MoMo/ZaloPay merchant:** partnerCode/appId + khóa HMAC thật, endpoint prod, và **IPN URL public** (chỉ có khi deploy Supabase cloud — local không nhận IPN từ ngoài).

## 6. Ngoài scope đợt này (nói rõ để khỏi lẫn)
- Catalog giá + boost kèo (`codex/pro-pricing-keo-boost` lưu kho — sẽ redo riêng).
- Migration `harden_rls_advisors` của Codex (việc riêng, không dính Maps/Payments).
- Đăng ký scheme `cunghat://` native (operator gate P7 riêng).
- FCM/send-sms provider thật (gate riêng, không thuộc đợt này — send-sms giữ nguyên).
- Per-venue pricing thương lượng (deposit mặc định 200k là v1; giá theo venue = việc BD sau).

## 7. Kiểm thử & gates mỗi task
- **DB:** pgTAP cho `get_keo_midpoint` (gate non-member, snap 3 số lẻ, NULL khi không vị trí) + `booking_deposit_minor`.
- **Flutter:** widget test VenueMapSurface (fallback + midpoint pin), BookingButton sheet 2 gateway, PlanRepository signature mới, IapController catalog map từ products (mock rpc/select).
- **Edge:** harness P4 ở trên (self-signed accept/tamper-reject/503).
- **Gates:** `flutter test` + `flutter analyze` + `supabase test db` (khi đụng DB) xanh 100% mỗi task; commit ASCII subject + `Co-Authored-By: Claude`.
- **Verify cuối đợt:** emulator cunghat_test3 — map fallback + flow đặt phòng đến màn gateway-not-configured (khi chưa có creds thì UX phải báo lỗi tử tế, không crash); log `docs/verify-maps-payments-*.md`.

## 8. Quyết định thiết kế cần user xác nhận ở gate duyệt plan
1. **Làm cả 2 gateway server-side ngay** (MoMo + ZaloPay), UI sheet 2 nút — thay vì MoMo-first.
2. **Dùng sandbox creds công khai** của MoMo/ZaloPay cho verify local (dev-only, không dính merchant thật).
3. **Server-derive deposit 200k VND mặc định** qua cột `venues.booking_deposit_minor`, client hết quyền gửi amount.
4. Midpoint pin snap ~110m với caveat kèo-2-người như mục M1.
