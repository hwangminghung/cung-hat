# Plan: Operator gates (2026-07-26)

Trạng thái repo tại thời điểm viết: master `3d82923f`, analyze 0 · 1039 Flutter ·
256 pgTAP · CI xanh 3 job. **Toàn bộ việc còn lại của dự án đều là gate ngoài** —
không phải code thiếu, mà là credential/tài khoản chưa có nên đường dây chưa
chạy thật lần nào.

Doc này khác `docs/STORE_SUBMISSION.md §10` (bảng liệt kê phẳng) ở chỗ: sắp theo
**đường tới hạn**, tách rõ *ai làm gì*, và mỗi gate có **tiêu chí nghiệm thu chạy
thật** — vì rủi ro lớn nhất không phải quên cắm key mà là cắm xong tưởng chạy.

---

## Kiểm trạng thái nhanh

```bash
bash scripts/check_operator_gates.sh
# hoac doc them secret da cam:
ENV_FILE=supabase/functions/.env bash scripts/check_operator_gates.sh
```

Script trả lời được **"cái gì đã cắm dây, cái gì chưa"** và bắt luôn nhóm lỗi
cấu-hình-sai (`test_otp` còn bật, `applicationId` vẫn là id dev,
`APPLE_ENVIRONMENT=Production` mà thiếu app id). Nó **không** trả lời được
"key có hoạt động không" — cái đó phải chạy phép thử end-to-end ghi ở từng gate
bên dưới.

## Nguyên tắc chung

**1. "Đã cấu hình" ≠ "đã chạy".** Mọi edge function hiện fail-closed khi thiếu
secret (`push-fanout` 503, `send-sms` 503 sau verify chữ ký, `validate-iap` từ
chối). Fail-closed nghĩa là thiếu key thì *im lặng không chạy* chứ không nổ —
nên gate nào cũng phải có một phép thử end-to-end, không được chỉ nhìn env.

**2. Code sau feature flag chưa từng chạy thật.** Hai đường dây đang tắt hoàn
toàn lúc compile:

| Flag | Mặc định | Ảnh hưởng |
| --- | --- | --- |
| `GOOGLE_MAPS_ENABLED` | `false` | `_NativeVenueMap` không bao giờ render; app dùng `_MapFallback` vẽ tay. **Chưa ai từng thấy GoogleMap thật trong app này.** |
| `BOOKING_ENABLED` | `false` | `BookingButton` không được compile vào. Theo QĐ payments-v1 thì đúng ý đồ. |

Bật flag lần đầu = chạy code mới tinh. Phải tính thời gian sửa, đừng bật sát
ngày submit.

**3. MoMo/ZaloPay KHÔNG nằm trên đường tới hạn v1.** Theo
`docs/superpowers/specs/2026-07-10-payments-v1-decision.md`: cọc quán hoãn sang
v1.5, hàng số bắt buộc IAP (MoMo cho hàng số *trong app* là vi phạm Apple 3.1.1 /
Play Payments → nguy cơ gỡ app). Code cổng thanh toán giữ nguyên, dùng lại cho
**web portal ngoài app** sau launch. → Gate này **hoãn**, không chặn submit.

---

## Đường tới hạn

```
[G1 SMS] ──► [G2 Tài khoản store] ──► [G3 IAP] ──► SUBMIT
                    │
                    └──► [G4 FCM] ─┐
                                   ├─ song song, không chặn submit
             [G5 Maps billing] ────┘
             [G6 Deep links] ──────┘

[G7 MoMo/ZaloPay] ── hoãn sau launch (web portal)
```

**G1 là nút cổ chai thật sự**: không có SMS thật thì không ai ngoài máy dev đăng
nhập được — mọi thứ phía sau (IAP sandbox, FCM token, TestFlight) đều cần một tài
khoản đăng nhập được.

---

## G1 — SMS thật cho OTP `[CHẶN MỌI THỨ]`

**Hiện trạng (đã xác minh):** `supabase/config.toml` bật `[auth.sms.twilio]` với
`account_sid = "AC000...0"` (placeholder) và `[auth.sms.test_otp]` hard-code
`84900000001 = "123456"`. Hook `send_sms` `enabled = false` vì test_otp
short-circuit. Nghĩa là **chỉ đúng 1 số điện thoại đăng nhập được**, và chỉ trên
stack local.

**Operator làm:**
1. Chọn nhà cung cấp SMS VN. Twilio gửi về đầu số VN đắt và hay bị chặn brandname —
   cân nhắc eSMS.vn / Speedsms / VNPT SMS Brandname (cần đăng ký brandname, ~1–2
   tuần duyệt, cần giấy phép kinh doanh).
2. Lấy: API key/secret + brandname đã duyệt.
3. Nạp secret vào Supabase project (không phải local): `SMS_API_KEY`,
   `SEND_SMS_HOOK_SECRET` (dạng `v1,whsec_...` do GoTrue sinh).

**Tôi làm:**
- Đổi `config.toml` production: tắt `test_otp`, bật `[auth.hook.send_sms]`, trỏ
  `uri` về `send-sms` đã deploy.
- Ráp provider thật vào `supabase/functions/send-sms` (hiện fail-closed 503 sau
  khi verify chữ ký — phần verify đã có, phần gọi provider là TODO).
- Test pgTAP/deno cho nhánh provider lỗi (rate limit, số không hợp lệ).

**Nghiệm thu:** số điện thoại thật (không phải 84900000001) nhận được SMS trong
<30s, đăng nhập tới deck; thử số sai định dạng → thấy `authError*` thân thiện,
không phải exception thô; thử spam 5 lần → thấy rate limit của GoTrue.

**Rủi ro:** brandname bị từ chối → phải đổi provider, cộng 1–2 tuần. Bắt đầu
sớm nhất có thể, đây là hạng mục có lead time dài nhất trong toàn bộ danh sách.

---

## G2 — Tài khoản store + app record `[CHẶN G3]`

**Hiện trạng:** chưa có app record ở đâu. `applicationId` Android hiện là
`dev.cunghat.cung_hat` — **đây là id dev, phải chốt id thật trước khi tạo app
record vì Play không cho đổi sau khi publish.**

**Operator làm:**
1. Apple Developer Program (99 USD/năm, duyệt 24–48h; nếu đăng ký dạng công ty
   cần D-U-N-S number → có thể mất 1–2 tuần).
2. Google Play Console (25 USD một lần) + **xác minh danh tính/địa chỉ**, hiện
   Google bắt buộc và mất vài ngày.
3. Tạo app record 2 bên với bundle id/package name đã chốt.
4. Điền listing theo `docs/STORE_SUBMISSION.md §2` (copy VI/EN đã viết sẵn).

**Tôi làm:** đổi `applicationId`/bundle id sang id chốt, cập nhật
`ANDROID_PACKAGE_NAME` + `APP_BUNDLE_ID` trong env edge function, chạy lại gate.

**Nghiệm thu:** app record tồn tại 2 bên, `flutter build appbundle --release` ra
file upload được lên internal testing track.

---

## G3 — IAP `[CHẶN SUBMIT]`

**Hiện trạng:** `validate-iap` đã viết đầy đủ và **fail-closed** (thiếu secret →
từ chối cấp entitlement, không cấp nhầm). Store screen đã có đủ phần compliance
đợt BANGIAO: kỳ hạn giá, nút Khôi phục mua hàng, link Điều khoản/Bảo mật, ghi chú
không tự động gia hạn. `IapController.init()` đã được gọi (bug C1 đã fix).
**Chưa có product id nào tồn tại thật.**

**Operator làm:**
1. Tạo 4 product id 2 bên — non-consumable trừ boost:
   `com.cunghat.boost` (consumable) · `com.cunghat.see_likes` ·
   `com.cunghat.filters` · `com.cunghat.pro`
2. Điền giá VND từng gói (khớp `products` table: 49k/79k/99k/199k).
3. Apple: `APPLE_SHARED_SECRET` (App-Specific Shared Secret) + `APPLE_APP_APPLE_ID`
   (id số). Play: service account JSON có quyền xem đơn hàng → `GOOGLE_PLAY_SA_JSON`.
4. **Apple bắt buộc**: điền tax/banking trong App Store Connect, thiếu thì sandbox
   purchase báo lỗi mơ hồ.

**Tôi làm:** nạp secret, `APPLE_ENVIRONMENT=Sandbox` khi test rồi `Production` khi
submit (code đã bắt buộc `APPLE_APP_APPLE_ID` khi Production), verify
`localizedPrices()` lấy giá từ store thay vì bảng `products`.

**Nghiệm thu (phải chạy trên máy thật, không phải emulator):**
- Sandbox mua `pro` → `entitlements` có row → app hiện Pro không cần restart.
- **Khôi phục mua hàng** trên máy thứ 2 cùng Apple ID → Pro về (Apple 3.1.1 bắt
  buộc, reviewer sẽ bấm thử).
- Huỷ giữa chừng → `IapEvent.canceled`, không cấp entitlement, không kẹt spinner.
- Giá hiển thị = giá store (đổi giá trên console → app đổi theo).

---

## G4 — FCM push `[không chặn submit]`

**Hiện trạng:** `android/app/google-services.json` và
`ios/Runner/GoogleService-Info.plist` **đều chưa có** (đã kiểm). `push-fanout` đã
implement FCM HTTP v1 thật (OAuth JWT RS256, cache token 1h, dọn token chết
404/400) nhưng chạy **dry-run đếm-và-log** khi thiếu `GOOGLE_FCM_SA_JSON`. 2
pg_cron đã cài: kèo-tối-nay 17:00 VN, người-mới-hợp-gu 12:00 T2.
`AnalyticsService` cũng no-op cho tới khi có Firebase config → **cùng một gate**.

**Operator làm:** tạo Firebase project → thêm app Android + iOS → tải
`google-services.json` + `GoogleService-Info.plist` → iOS cần **APNs Auth Key
(.p8)** upload lên Firebase → tạo service account có quyền
`cloudmessaging.messages.create` → JSON vào `GOOGLE_FCM_SA_JSON`. Đặt
`PUSH_FANOUT_SECRET` + GUC `app.fanout_url` / `app.fanout_secret` trên DB prod.

**Tôi làm:** đặt file config vào chỗ, verify `Firebase.initializeApp()` không còn
no-op, chạy tay 2 hàm cron trên staging.

**Nghiệm thu:** 2 máy thật, A nhắn B khi B đóng app → B nhận push trong <10s và
**không thấy nội dung tin nhắn** trong payload (chỉ key copy VI — quyết định
riêng tư đã chốt); gọi `notify_keo_tonight()` tay → đúng người trong kèo nhận;
gỡ app rồi gửi tiếp → token chết bị xoá khỏi `device_tokens`.

---

## G5 — Google Maps billing `[không chặn submit]`

**Hiện trạng:** wiring native **đã xong** (`MAPS_API_KEY` đọc từ
local.properties → gradle property → env, đổ vào manifest placeholder). Thiếu
đúng 2 thứ: key có billing, và `--dart-define=GOOGLE_MAPS_ENABLED=true`.
`ingest-places-venues` cần `GOOGLE_PLACES_API_KEY` riêng (Places API New).

**Operator làm:** GCP project → bật billing → bật **Maps SDK for Android**, **Maps
SDK for iOS**, **Places API (New)** → tạo key, **giới hạn key theo package name +
SHA-1** (không giới hạn = ai lấy được key cũng tiêu tiền của mình) → đặt ngân sách
cảnh báo.

**Tôi làm:** cắm key, build với `GOOGLE_MAPS_ENABLED=true`, chạy
`scripts/run_places_ingest.sh` kéo quán thật cho 3 thành phố launch.

**Nghiệm thu:** map thật render trên màn Kế hoạch, marker quán + marker tím điểm
giữa nhóm đúng vị trí, `animateCamera` fit hết marker; bấm marker → mở sheet chọn
lịch (đường dây `onVenueSelected` của native map **chưa chạy thật lần nào** —
mới chỉ test trên fallback); ingest ra ≥20 quán/quận launch với toạ độ hợp lệ.

**Lưu ý chi phí:** Maps SDK tính theo lượt tải map. Deck + board không dùng map,
chỉ màn Kế hoạch — lưu lượng thấp. Places ingest là one-off theo đợt, không phải
mỗi lần user mở app.

---

## G6 — Deep links `cunghat://` `[không chặn submit, nhưng share đang gãy]`

**Hiện trạng (đã kiểm hôm nay):** `AndroidManifest.xml` **chỉ có
MAIN/LAUNCHER** — không có intent-filter nào. Nghĩa là mọi link chia sẻ kèo/kế
hoạch (`/keo/shared/:token`, `/plan/shared/:token`) hiện **không mở được app**,
dù router và màn hình đã làm xong. Theo memory, phần wiring này nằm ở nhánh
`codex/operator-gates-wip` chưa merge.

**Tôi làm (không cần operator):** thêm intent-filter `cunghat://` vào manifest +
`CFBundleURLTypes` vào `Info.plist`, test bằng `adb shell am start -a
VIEW -d "cunghat://keo/shared/<token>"`. Việc này **làm được ngay**, nên tách khỏi
nhóm gate ngoài.

**Cần operator (chỉ cho App Links https):** domain + hosting
`/.well-known/assetlinks.json` (Android) và `apple-app-site-association` (iOS).
Không bắt buộc cho v1 — custom scheme đủ để share hoạt động.

**Nghiệm thu:** nhận link trong Zalo/Messenger → bấm → mở đúng màn kèo/kế hoạch,
kể cả khi app đang đóng (cold start).

---

## G7 — MoMo / ZaloPay `[HOÃN — không nằm trong v1]`

Theo QĐ payments-v1: hàng số trong app **chỉ IAP**, cọc quán hoãn sang v1.5. Code
`create-venue-payment` + `payments-webhook` đã viết, verify chữ ký fail-closed,
giữ nguyên để dùng lại cho **web portal ngoài app** sau launch (mua trên web →
server cấp entitlement → app tự thấy Pro; ràng buộc anti-steering: trong app
không được có nút/link/text dẫn sang web).

**Không làm gì ở đợt này.** Khi mở lại: cần merchant đã xác minh (yêu cầu giấy
phép kinh doanh + tài khoản ngân hàng doanh nghiệp, lead time vài tuần) và chính
sách hoàn/mất cọc viết vào T&C trước.

---

## Thứ tự đề xuất

| Tuần | Việc | Ghi chú |
| --- | --- | --- |
| Ngay | **G1 khởi động đăng ký brandname SMS**, **G2 đăng ký 2 tài khoản store** | Cả hai đều có thời gian duyệt — nộp trước, làm việc khác trong lúc chờ |
| Ngay | **G6 phần manifest** (tôi làm, không chờ ai) | Gỡ được một mảng chức năng đang gãy |
| Chờ duyệt | G5 Maps + G4 Firebase (tự phục vụ, xong trong ngày) | Không phụ thuộc gate nào |
| Sau G2 | G3 tạo product IAP + nghiệm thu trên máy thật | Cần app record trước |
| Trước submit | Chạy lại `docs/STORE_SUBMISSION.md §11` | 4 lệnh gate phải xanh |
| Sau launch | G7 web portal | Cần merchant |

## Việc không chờ credential — ĐÃ XONG (2026-07-26)

1. ~~**G6 manifest + Info.plist**~~ — đã đăng ký `cunghat://` 2 nền tảng. Trong lúc
   test lộ thêm một lỗi thứ hai: go_router **cũng** tự nghe kênh route của
   platform nên khi app đang chạy nó nuốt URI thô trước `app_links` → user thấy
   `GoException: no routes for location`. Cold start không dính (vì
   `getInitialLink()` chạy trước) → **chỉ test cold start sẽ tưởng đã xong**.
   Đã thêm `normalizeDeepLinkLocation()` vào redirect của router.
2. ~~**Khung gọi provider SMS**~~ — `_shared/sms.ts`: chọn provider qua
   `SMS_PROVIDER` (`esms` | `twilio`), timeout 10s tự ngắt, fail-closed khi
   thiếu/lạ, không bao giờ đưa phone/OTP vào message lỗi. Bẫy riêng của eSMS đã
   xử: họ trả **HTTP 200 kể cả khi gửi hỏng**, chỉ `CodeResult == "100"` mới là
   thành công. 8 deno test + `deno test` đã nối vào CI (trước chỉ có `deno check`).
   Còn lại đúng việc cắm key.
3. ~~**Tự động hoá checklist**~~ — `scripts/check_operator_gates.sh` (xem đầu doc).
