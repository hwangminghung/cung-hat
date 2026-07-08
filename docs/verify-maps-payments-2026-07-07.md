# Verify đợt Maps + Payments — 2026-07-07

Nhánh: `feat/maps-payments`. Tài liệu này ghi lại kết quả kiểm chứng cuối đợt
(harness self-signed HMAC + 3 gate) và ranh giới "đã verify được" vs "chưa verify
được vì thiếu credential thật".

---

## 1. Tóm tắt đợt

- **Nhánh:** `feat/maps-payments` (worktree `cung-hat-photos-wt`).
- **Phạm vi:** 12 task (T1–T12) tích hợp Google Maps + thanh toán thật (MoMo/ZaloPay
  cho đặt cọc phòng, Apple/Google IAP cho hàng số), tất cả theo nguyên tắc
  **fail-closed** (thiếu credential → 503, không bao giờ cấp quyền/settle "chay").
- **Commit range:** `251bd7d2..HEAD` = **24 commit**, từ `fdeba80e`
  (`docs(spec): thiet ke tich hop that Google Maps + thanh toan`) đến `25b51477`
  (`feat(venues): loc ban kinh cho searchText (music box) ... locale VN`).
  (24 commit = 2 doc spec/plan + 12 task triển khai + các fix theo review.)

Trục task → commit chính:

| Task | Nội dung | Commit tiêu biểu |
|------|----------|------------------|
| T1 | RPC `get_keo_midpoint` + pgTAP | `d3f17b5f`, `377936e1` |
| T2 | `getKeoMidpoint` repo + provider | `01108580` |
| T3 | Pin midpoint + fit bounds camera | `38848041` |
| T4 | Wiring iOS Maps + `GOOGLE_MAPS_ENABLED` + runbook | `40396b44`, `6a3c7ec2` |
| T5 | Server quyết `booking_deposit_minor`, client bỏ `amount` | `af32d0b9`, `752013c1` |
| T6 | Sheet chọn gateway MoMo/ZaloPay ở BookingButton | `c476deca`, `f52cbfab` |
| T7 | `create-venue-payment` thật (create-order + HMAC) | `dd69eb78`, `f4afe030` |
| T8 | `payments-webhook` verify HMAC thật + reconcile | `3b669b45`, `aaec7164` |
| T9 | `validate-iap` verify Apple JWS/legacy + Google Play | `2ef1daa4`, `29b6aa74`, `4a2162a3`, `a75cf68f` |
| T10 | Catalog IAP từ bảng `products` qua `get_store_products` | `0e54f70e`, `c9415345` |
| T11 | `ingest-places-venues` mode `searchText` (music box) | `3fb77b80`, `25b51477` |
| T12 | Harness verify + doc này + 3 gate | (đợt commit hiện tại) |

---

## 2. Bảng kết quả harness

Script: `scripts/verify_payments_local.sh` (chạy `bash scripts/verify_payments_local.sh`).
Crypto **thật** (HMAC-SHA256 bằng `openssl`, đúng chuỗi ký của gateway) với secret
**dummy** đọc từ `supabase/functions/.env`. Ký IPN/callback ngay trong script rồi bắn
vào edge runtime local, đối chiếu HTTP status + row `venue_bookings`. Chạy lặp lại
được (dùng `gateway_ref` có timestamp + trap cleanup, không để lại row rác).

Kết quả: **20/20 PASS, 0 FAIL** (`PASS=20 FAIL=0`, exit 0, 0 row `verify-%` sót lại;
chạy lặp lại nhiều lần đều xanh).

| # | Check | Want | Got | KQ |
|---|-------|------|-----|----|
| 1 | momo ipn signed -> 204 | 204 | 204 | PASS |
| 2 | momo booking -> paid | paid | paid | PASS |
| 3 | momo commission 10% | 20000 | 20000 | PASS |
| 4 | momo ipn replay -> 204 | 204 | 204 | PASS |
| 5 | momo replay state unchanged | paid/20000 | paid/20000 | PASS |
| 6 | momo ipn tampered amount -> 401 | 401 | 401 | PASS |
| 7 | momo tampered state still paid | paid | paid | PASS |
| 8 | momo signed amount-mismatch -> 204 | 204 | 204 | PASS |
| 9 | momo mismatch booking -> failed | failed | failed | PASS |
| 10 | momo mismatch commission stays 0 | 0 | 0 | PASS |
| 11 | zalopay callback signed -> return_code 1 | 1 | 1 | PASS |
| 12 | zalopay booking -> paid | paid | paid | PASS |
| 13 | zalopay bad mac -> return_code -1 | -1 | -1 | PASS |
| 14 | zalopay bad mac row stays initiated | initiated | initiated | PASS |
| 15 | webhook unknown gateway -> 400 | 400 | 400 | PASS |
| 16 | validate-iap no jwt -> 401 | 401 | 401 | PASS |
| 17 | validate-iap jwt+garbage -> 503 | 503 | 503 | PASS |
| 18 | create-venue-payment no jwt -> 401 | 401 | 401 | PASS |
| 19 | create-venue-payment jwt+bogus plan -> 403 | 403 | 403 | PASS |
| 20 | ingest-places anon-jwt no secret -> 403 | 403 | 403 | PASS |

Ý nghĩa từng nhóm:

- **1–3:** IPN MoMo ký đúng → settle `initiated → paid`, hoa hồng 10% (`amount/10`)
  ghi đúng. Chứng minh đường crypto + state machine + tính tiền.
- **4–5:** Replay IPN đã `paid` → idempotent (vẫn 204, state/commission không đổi).
- **6–7:** Sửa `amount` trong body nhưng giữ nguyên chữ ký cũ → server tính lại HMAC
  trên amount mới → **khác chữ ký** → 401, row **không** bị đổi (bảo vệ chống tamper).
- **8–10:** IPN **ký đúng** nhưng amount **lệch** so với booking (đường reconciliation
  trong `settle()`): chữ ký verify OK, server phát hiện `amount_mismatch` → row
  `initiated → failed`, KHÔNG cấp paid, commission giữ 0. HTTP vẫn **204** vì theo
  contract MoMo mismatch là terminal — ack để MoMo ngừng retry (retry cũng không sửa
  được lệch tiền). Khác nhóm 6–7: ở đó chữ ký chết trước khi tới settle().
- **11–12:** ZaloPay callback ký đúng → `return_code 1` + settle paid.
- **13–14:** ZaloPay sai `mac` → `return_code -1`, row giữ `initiated` (fail-closed).
- **15:** gateway không hợp lệ → 400.
- **16–17:** `validate-iap` chặn không JWT (401); có JWT thật + receipt rác nhưng
  **thiếu creds store** → 503 (fail-closed đúng, không cấp entitlement).
- **18–19:** `create-venue-payment` chặn không JWT (401); có JWT thật nhưng plan không
  phải kèo của user → 403 (`not_a_plan_member`, gate authz qua RLS).
- **20:** `ingest-places-venues` chỉ có anon-JWT, thiếu `x-ingest-secret` → 403
  (secret-gated, không lộ cho app).

---

## 3. Gates cuối đợt (số liệu thật)

| Gate | Lệnh | Kết quả |
|------|------|---------|
| Flutter test | `flutter test` | **254 tests, All tests passed!** |
| Flutter analyze | `flutter analyze` | **No issues found!** (ran in 24.3s) |
| pgTAP | `npx supabase test db` | **Files=34, Tests=150, Result: PASS** |

Harness: `bash scripts/verify_payments_local.sh` → **PASS=20 FAIL=0** (exit 0).

---

## 4. Đã verify được gì ngoài harness (từ các task)

- **T8 — smoke MoMo + ZaloPay self-signed end-to-end với DB state:** ký IPN/callback
  bằng chính thuật toán/chuỗi ký của gateway (secret dummy), bắn vào webhook thật,
  quan sát `venue_bookings` chuyển `initiated → paid`, hoa hồng 10%, idempotent replay,
  chống tamper amount, đường reconciliation amount-mismatch (ký đúng, lệch tiền →
  `failed`), sai mac giữ `initiated`. (Chính là các check 1–15 của harness.)
- **T9 — boot + 503 fail-closed với JWT thật:** `validate-iap` với JWT thật (GoTrue OTP)
  + receipt rác, khi thiếu creds store (`GOOGLE_PLAY_SA_JSON`/`ANDROID_PACKAGE_NAME`
  hoặc `APP_BUNDLE_ID`) → 503, không bao giờ cấp entitlement (không có short-circuit
  "verify ok" giả). Product `boost/android` có thật trong bảng `products` nên request
  đi qua được bước tra product rồi mới dừng ở gate creds → chứng minh fail-closed đúng chỗ.
- **T7 — 401/403 authz:** `create-venue-payment` không JWT → 401; JWT thật nhưng không
  phải thành viên kèo → 403 (RLS `plans_member_read`). Số tiền do server quyết từ
  `venues.booking_deposit_minor`, client không gửi `amount` (T5).
- **Edge runtime env-loading finding (QUAN TRỌNG):** `docker restart
  supabase_edge_runtime_cung-hat` **KHÔNG** nạp lại `supabase/functions/.env` — chỉ nạp
  lại CODE đã mount. Muốn nạp ENV mới phải `npx supabase stop && npx supabase start`.
  Harness có preflight: bắn webhook body rỗng, nếu trả **503** nghĩa là secret chưa vào
  container → in hướng dẫn stop/start và dừng (exit 2) thay vì báo FAIL nhầm.

---

## 5. CHƯA verify được vì thiếu credential (và lệnh sẽ chạy khi có)

| Hạng mục | Thiếu gì | Lệnh / cách verify khi có creds |
|----------|----------|--------------------------------|
| Map native hiển thị | `MAPS_API_KEY` (iOS/Android) + `GOOGLE_MAPS_ENABLED=true` | Rebuild app với key + flag, mở PlanScreen xem pin midpoint + camera fit trên map thật (hiện chỉ verify được logic RPC/midpoint qua pgTAP + widget test). |
| Places ingest thật | `GOOGLE_PLACES_API_KEY` + `PLACES_INGEST_SECRET` | `scripts/run_places_ingest.sh` hoặc `curl -H "x-ingest-secret: <secret>" -d '{"city":"...","lat":..,"lng":..,"text_query":"music box"}' <fn-url>/ingest-places-venues` → kỳ vọng `{found, kept, upserted}` > 0. |
| IAP mua thật | Store accounts (Google license tester / Apple sandbox tester) + `GOOGLE_PLAY_SA_JSON` + `ANDROID_PACKAGE_NAME` / `APP_BUNDLE_ID` + `APPLE_SHARED_SECRET` | Mua sandbox từ app → `validate-iap` với receipt/token thật → kỳ vọng 200 `{ok:true, feature}` + row `purchases`/`entitlements`. |
| MoMo/ZaloPay create-order sandbox/prod | Merchant creds (`MOMO_PARTNER_CODE/ENDPOINT`, `ZALOPAY_APP_ID/KEY1/ENDPOINT`) + `PAYMENTS_WEBHOOK_URL` + `PAYMENTS_REDIRECT_URL` public | Gọi `create-venue-payment` với plan thật → kỳ vọng 200 `{pay_url, gateway_ref}`, mở pay_url thanh toán sandbox → gateway gọi lại webhook → settle paid. |
| iOS build | macOS (Xcode) | `flutter build ios` trên macOS với Maps.xcconfig + key. |

---

## 6. Sổ deferred (minor, không chặn — từ review các task)

- **plan_repository.dart:** check `status >= 400` là dead code (functions_client tự
  throw `FunctionException`) — dọn khi thuận tiện; cùng pattern ở
  `billing_repository.deliverPurchase`.
- **VenueMapSurface native:** camera không refit khi midpoint đến SAU khi map tạo (cần
  StatefulWidget/`didUpdateWidget` khi có Maps key để test); `animateCamera` lúc
  cold-start có thể dính size-race (thêm try/catch hoặc `addPostFrameCallback`); hoist
  min/max reduce trong fallback.
- **Booking sheet:** chưa có test SnackBar generic-failure; chưa có drag-handle/nút huỷ
  (cosmetic).
- **create-venue-payment:** quét dọn row `initiated` cũ >24h (ops/cron); UUID
  case-compare nit; venues query error trả `unknown_venue` (mislabel nhưng fail-closed).
- **payments-webhook:** so sánh chữ ký non-constant-time (đã đánh giá: rủi ro không
  đáng kể).
- **validate-iap:** bundle Apple root certs làm hằng số (tránh phụ thuộc apple.com lúc
  cold start); map lỗi transient → 503 thay vì 400 + generic reason cho client;
  normalize `APPLE_ENVIRONMENT` case + trim `APPLE_APP_APPLE_ID`; Google acknowledge
  fail đang bị bỏ qua (rủi ro refund 3 ngày); legacy `verifyReceipt` chưa check
  bundle_id; `store_txn_id` từ client giờ là dead input trên nhánh Google.
- **IAP catalog:** decode style `.cast` vs `Map.from` (consistency); catalog rỗng bị
  cache cả session (chấp nhận).
- **ingest-places:** chưa phân trang `pageToken` (cap 20/query — quận dày sẽ bị cắt).
- **Migration booking_deposit:** inline constraint không tách DO-block như convention
  (chỉ style).

---

## 7. Ba credential gate (khoá mở gì)

| Gate | Cần gì | Mở khoá gì |
|------|--------|-----------|
| **Maps** | `MAPS_API_KEY` (iOS + Android) + `GOOGLE_MAPS_ENABLED=true` + rebuild | Bản đồ native hiển thị pin midpoint kèo + venue; camera fit bounds trên map thật. |
| **Places** | `GOOGLE_PLACES_API_KEY` + `PLACES_INGEST_SECRET` | Ingest venue thật theo thành phố (searchNearby + searchText "music box"); populate bảng `venues`. |
| **Payments/IAP** | MoMo/ZaloPay merchant creds + `PAYMENTS_WEBHOOK_URL`/`PAYMENTS_REDIRECT_URL` public; Apple/Google IAP creds + sandbox testers | Đặt cọc phòng thật qua MoMo/ZaloPay (create-order → pay_url → IPN settle); mua hàng số thật qua Apple/Google IAP (verify receipt → cấp entitlement). |

Tất cả gate trên đều **fail-closed** khi thiếu creds (đã chứng minh qua harness check
17 & 20 và smoke T7/T9): không có creds → 503/403, tuyệt đối không settle/cấp quyền chay.

---

## 8. Verify emulator UI (2026-07-07)

Chạy app THẬT trên emulator Android `cunghat_test3` (pixel 1080x2400), build debug
`flutter build apk --debug --dart-define-from-file=env/dev.emulator.json`
(`GOOGLE_MAPS_ENABLED=false`, `SUPABASE_URL=http://10.0.2.2:54321`), install lên
emulator, đăng nhập sẵn user **Minh** (phone 900000001). Mục tiêu: chứng minh các UI
surface của đợt hoạt động trong app thật, không chỉ test/harness.

Ảnh chụp: `docs/verify-screenshots-maps-payments/`.

| Mã | Kiểm chứng | KQ | Bằng chứng | Ghi chú |
|----|-----------|----|-----------|---------|
| VER-E1 | Pseudo-map fallback + venue markers + **pin midpoint** (vòng tròn nhỏ + icon nhóm, key `midpoint_marker`), native GoogleMap OFF | **PASS** | `04-plan-map-midpoint.png` | PlanScreen "Kế hoạch": pseudo-map (gradient + lưới đường), nhiều venue pin hình giọt nước (orange) + 1 pin midpoint tròn có icon 2-người bên phải — phân biệt rõ với venue pin. RPC `get_keo_midpoint` trả `21.005/105.871` (median 2 thành viên); `nearest_venues_for_keo` trả 5 quán. |
| VER-E2 | Plan `confirmed` → nút "Đặt phòng & giữ chỗ" mở bottom sheet header **"Chọn cổng thanh toán"** + 2 tile MoMo/ZaloPay | **PASS** | `05-booking-gateway-sheet.png` | Plan card "Kpop Karaoke", "Trạng thái: Đã chốt". Sheet đúng header + tile "MoMo" (icon ví) + "ZaloPay" (icon thẻ). |
| VER-E3 | Tap MoMo → `create-venue-payment` trả **503 `payment_gateway_not_configured`** → SnackBar **"Cổng thanh toán chưa được cấu hình"** (KHÔNG phải message generic, KHÔNG crash) | **PASS** | `06-failclosed-snackbar.png` | SnackBar hiện đúng chuỗi fail-closed → chứng minh đường string-match `contains('not_configured')` sống end-to-end. Pre-check HTTP trực tiếp (JWT thật qua OTP): cả `momo` và `zalopay` đều `HTTP 503 {"error":"payment_gateway_not_configured"}`. Edge log xác nhận `serving ... create-venue-payment`. |
| VER-E4 | Mở lại sheet → tap ra ngoài (scrim) → sheet đóng, không fire gì, app ổn định | **PASS** | `07-sheet-dismissed.png` | Sheet reopen OK rồi dismiss sạch về PlanScreen, không SnackBar, không crash. |
| VER-E5 | Regression: deck Đôi load; board Kèo liệt kê kèo (không crash do đợt) | **PASS** | `01-doi-deck.png`, `02-keo-board.png` | Tab Đôi render card ("QA An KPop, 26"); board Kèo "Kèo quanh bạn" liệt kê các kèo bình thường. |

**Kết luận:** VER-E1..E5 = **5/5 PASS**. Không phát hiện bug hồi quy nào từ đợt maps-payments.

### Những gì phải điều chỉnh so với recipe (report trung thực)

- **Docker Desktop DOWN lúc bắt đầu** (2 WSL distro Stopped) dù recipe nói stack UP. Đã
  khởi động Docker Desktop; stack Supabase tự lên. Container **`supabase_edge_runtime_cung-hat`
  Exited (255)** sau khi Docker tắt — `docker start` container này lại là đủ (code+env vẫn
  mount), không cần stop/start toàn stack vì `.env` không đổi.
- **Seed schema khác recipe:** SQL mẫu trong task dùng cột không tồn tại
  (`city`/`location`/`starts_at`/`ends_at`/`capacity`/`join_mode` cho `keo`). Schema thật
  (`0012_keo.sql`): `title, area_label, area_geo(geography NOT NULL), time_window_start/end,
  group_size_target(2-5), status, genres`. Đã seed lại đúng cột; `keo_members` có `role`
  (`host`/`member`). Plan seed khớp cột thật (`keo_id, venue_id, scheduled_at, status`).
- **Board chỉ hiện kèo `status='open'`:** `list_open_keos` lọc `where k.status='open'`, nên
  kèo seed `planning` KHÔNG lên board. Đã đổi seed sang `status='open'` để tap vào được
  KeoDetailScreen (không ảnh hưởng midpoint/plan/booking — các hàm này không check keo
  status). Đã xoá toàn bộ row seed lúc cleanup.
- **Nút host là "Chốt quán"** (key `host_pick_venue_btn`), không phải "Xem kế hoạch"
  ("Xem kế hoạch"/`view_plan_btn` là của member non-host).
- **Emulator `cunghat_test3` bất ổn — segfault (exit 139) lặp lại**, cả windowed lẫn
  headless, cả `-gpu swiftshader_indirect` lẫn `-gpu guest`; tuổi thọ ~2 phút/lần boot
  (nguyên nhân ở tầng đồ hoạ host: SwiftShader/llvmpipe Vulkan; boot 1 chết ở
  `UpdateLayeredWindowIndirect`). **Cách ổn định hoá đã dùng:** tạo
  `~/.android/advancedFeatures.ini` với `Vulkan = off` + `GLDirectMem = on`, và tắt animation
  (`settings put global {window,transition,animator}_*_scale 0`), rồi chạy toàn bộ flow
  trong một mạch nhanh (không dừng lâu giữa bước — thời gian "suy nghĩ" giữa các lệnh làm
  emulator hết tuổi thọ). Sau khi tắt Vulkan + animation, emulator sống đủ lâu để hoàn tất
  E1→E4 liên tục. **Lưu ý để lại:** file `advancedFeatures.ini` (Vulkan=off) vẫn còn — nên
  giữ vì giúp emulator ổn định cho lần sau; xoá nếu muốn về mặc định.
