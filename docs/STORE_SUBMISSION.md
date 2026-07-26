# Cùng Hát — Store Submission Checklist (v1-rc)

Operator checklist for shipping **Cùng Hát** to the **App Store** and **Google Play**.
Everything that needs a real account, billing, or a legal filing is flagged as an
**OPERATOR** step. Nothing here is wired automatically.

App identity (already set in the project):

| Field | Value |
| --- | --- |
| Android `applicationId` / `namespace` | `dev.cunghat.cung_hat` |
| iOS `PRODUCT_BUNDLE_IDENTIFIER` | `dev.cunghat.cungHat` |
| Display name (iOS `CFBundleDisplayName`) | Cùng Hát |
| Version | `1.0.0+1` (bump `version:` in `pubspec.yaml` per release) |
| Launch markets | Hà Nội · Hồ Chí Minh · Thái Nguyên (VN) |

> If you prefer the marketing id `com.cunghat.app`, change `applicationId` (Android),
> `PRODUCT_BUNDLE_IDENTIFIER` (iOS), and **every IAP product id below** before first
> submission — the bundle id cannot be changed after the first Play/App Store upload.

---

## 1. App icon & splash

- Brand placeholder icon: `assets/icon/cung_hat.png` (1024×1024, `#6750A4` violet
  with white "CH"). **OPERATOR:** replace with final brand art (same path, same size),
  then re-run the generators below.
- Generators are configured in `pubspec.yaml` (`flutter_launcher_icons`,
  `flutter_native_splash`). Re-run after swapping the art:
  ```
  flutter pub run flutter_launcher_icons
  flutter pub run flutter_native_splash:create
  ```
- iOS launcher icons are generated with `remove_alpha_ios: true` (the App Store
  rejects icons with an alpha channel).
- **OPERATOR:** provide an App Store **1024×1024** marketing icon (no alpha, no rounded
  corners — Apple rounds it) in App Store Connect; Play wants a **512×512** 32-bit PNG
  hi-res icon and a **1024×500** feature graphic in the Play Console.

---

## 2. Listing copy

### 2.1 Vietnamese (primary)

- **App name:** Cùng Hát
- **Subtitle / short (≤80):** Rủ nhau đi hát — kết bạn qua âm nhạc.
- **Long description:**
  > Cùng Hát giúp bạn rủ nhau đi hát karaoke ngoài đời thật. Tạo **Kèo** (nhóm 2–5
  > người cùng đi hát) hoặc ghép **Đôi** theo gu nhạc và bài tủ của bạn. Chọn quán gần
  > bạn, chốt giờ, và gặp nhau hát thật. Không phải app hẹn hò — đây là nơi kết bạn qua
  > âm nhạc. Có ở Hà Nội, Hồ Chí Minh và Thái Nguyên.
  >
  > • Kèo nhóm: đăng kèo, duyệt người tham gia, chốt quán & giờ.
  > • Ghép đôi theo gu: vuốt theo bài tủ và thể loại nhạc.
  > • Quán gần bạn: gợi ý phòng hát quanh khu vực.
  > • An toàn: xác thực số điện thoại, báo cáo & chặn, kiểm duyệt nội dung.

### 2.2 English

- **App name:** Cùng Hát
- **Subtitle / short (≤80):** Go sing together — make friends through music.
- **Long description:**
  > Cùng Hát is for getting people together to sing karaoke in real life. Post a
  > **Kèo** (a group of 2–5 people heading out to sing) or match one-on-one in **Đôi**
  > by your music taste and signature songs. Pick a nearby venue, lock a time, and meet
  > up to actually sing. It is not a dating app — it is a place to make friends through
  > music. Live in Hà Nội, Hồ Chí Minh and Thái Nguyên.
  >
  > • Group meetups: post a kèo, approve who joins, lock the venue and time.
  > • Taste-based matching: swipe by signature songs and genres.
  > • Venues near you: nearby karaoke rooms suggested automatically.
  > • Safety: phone verification, report & block, content moderation.

- **Keywords (App Store, ≤100 chars):** karaoke,hát,đi hát,kết bạn,âm nhạc,kèo,nhóm,gặp gỡ
- **Category:** Social / Lifestyle.

---

## 3. Age rating — **18+**

- App Store: complete the Age Rating questionnaire → resulting rating **17+/18+**
  (user-generated content + unrestricted social interaction between strangers, real
  meetups).
- Play: IARC questionnaire → **18+ / Mature**. Declare user-generated content and
  user-to-user communication.
- Onboarding already gates on age/consent; the store age gate must match.

---

## 4. Privacy — App Store nutrition labels & Play Data Safety

The app collects, **linked to the user's identity**:

| Data | Purpose | Notes |
| --- | --- | --- |
| **Location (approximate / coarse)** | Discovery of nearby people, kèo, venues | Coarse city-area only; not precise GPS tracking, not used for ads. |
| **Account info** (phone number, profile name, age, photos[optional]) | Account, identity, sign-in | Phone OTP auth. Photos are optional. |
| **User content / messages** (kèo posts, chat messages, taste/song lists) | Core app function | Stored on Supabase; subject to moderation. |
| **Device token** (FCM) | Push notifications | `device_tokens` table; purged on retention schedule. |

- **No contacts** access. **No advertising identifiers.** **No third-party ad tracking.**
- **Cross-border transfer:** data is stored in the **Supabase Singapore** region —
  declare cross-border transfer out of Vietnam in both forms and in the privacy policy
  (`assets/legal/privacy_vi.md`).
- App Store: fill the **App Privacy** section (Data Used to Track You = None; Data Linked
  to You = the rows above). Play: complete the **Data Safety** form to match.
- Account/data deletion: ensure the in-app PDPL deletion flow (migration `0019_pdpl`) is
  referenced from the listing — Apple and Play both require an account-deletion path.

---

## 5. In-app purchases (digital goods → store IAP)

Create these as **consumable / non-consumable IAP** with the exact product ids from
migration `0020_monetization.sql` (`products.store_product_id`):

| Feature | iOS product id | Android product id | Price (VND) |
| --- | --- | --- | --- |
| Boost | `com.cunghat.boost` | `boost` | 49,000 |
| See who liked you | `com.cunghat.see_likes` | `see_likes` | 99,000 |
| Premium filters | `com.cunghat.filters` | `filters` | 79,000 |

- **OPERATOR:** create each product in App Store Connect and Play Console with the ids
  above, set the VN price tier, and complete **tax & banking / paid-apps agreements** in
  both consoles (no IAP can go live without these).
- These are **digital goods → must use store IAP** (no external payment for them).

---

## 6. Venue payments (MoMo / ZaloPay) — real-world service, NOT IAP

- Venue booking / commission payments via **MoMo** and **ZaloPay** are payments for a
  **real-world service** (booking a physical karaoke room), so per App Store §3.1.3(e)
  and Play's real-world-goods exemption they **do not** use store IAP and **must not** be
  offered alongside the digital IAP above as an alternative.
- **OPERATOR:** keep the venue-payment flow clearly scoped to physical bookings in the
  listing/review notes so it is not flagged as IAP circumvention. Provision MoMo/ZaloPay
  merchant accounts (see release gates below).

---

## 7. Decree 147 / Vietnam content-moderation compliance

- **OPERATOR:** confirm the operating entity's **content-moderation / cross-border
  social-network** obligations under **Decree 147/2024/NĐ-CP** (and Decree 53 data
  localization) are met before public launch in VN, and that any required registration
  or licensing for a user-content social service is filed.
- A **moderation contact** (named person + email/phone) must be published and reachable
  for takedown requests. The app ships report/block + moderation (`0018_moderation.sql`);
  ensure a human review queue and SLA are operationally staffed.
- Provide the moderation/abuse contact in the store listing support fields.

---

## 8. Screenshots

- **OPERATOR:** produce the required screenshot set:
  - iOS: 6.7" (or 6.9") and 5.5" sets minimum; iPad if iPad is supported.
  - Android: phone + 7"/10" tablet feature screenshots.
- Recommended shots: Kèo board (group meetups), Đôi swipe (taste matching), a kèo detail
  with a nearby venue, chat, and the safety/report screen. Vietnamese UI for the VN
  listing.

---

## 9. Deep links & custom scheme — **OPERATOR (native config required)**

The app resolves share links and `cunghat://plan/{token}` (resolver added in P7,
migrations `0023` + client `app_links`). The **native registration is not yet in the
manifests** and must be added before submission:

### 9.1 Custom scheme `cunghat://`

- **Android** — add to the main `<activity>` in
  `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <intent-filter android:autoVerify="false">
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="cunghat" />
  </intent-filter>
  ```
- **iOS** — add to `ios/Runner/Info.plist`:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>dev.cunghat.cungHat</string>
      <key>CFBundleURLSchemes</key>
      <array><string>cunghat</string></array>
    </dict>
  </array>
  ```

### 9.2 Universal / App Links (https share URLs) — optional but recommended

- **iOS** `apple-app-site-association` (served at
  `https://<domain>/.well-known/apple-app-site-association`, `Content-Type:
  application/json`, no extension):
  ```json
  { "applinks": { "apps": [], "details": [
    { "appID": "<TEAMID>.dev.cunghat.cungHat", "paths": ["/plan/*"] }
  ] } }
  ```
  Then add the `applinks:<domain>` Associated Domains entitlement in Xcode.
- **Android** `assetlinks.json` (served at
  `https://<domain>/.well-known/assetlinks.json`):
  ```json
  [{ "relation": ["delegate_permission/common.handle_all_urls"],
     "target": { "namespace": "android_app",
       "package_name": "dev.cunghat.cung_hat",
       "sha256_cert_fingerprints": ["<UPLOAD+PLAY-SIGNING SHA256>"] } }]
  ```
  Add a matching `<intent-filter android:autoVerify="true">` with the `https` data host,
  and use the **Play App Signing** cert fingerprint from the Play Console.

---

## 9.3 URL công khai bắt buộc khi nộp — **ĐÃ CÓ**

Cả Play Console lẫn App Store Connect đều **bắt buộc** điền URL chính sách bảo mật
cho app thu thập dữ liệu cá nhân (Cùng Hát thu số điện thoại, vị trí, ảnh, tin
nhắn). Bản nhúng trong app **không thay thế được** — store cần một link mở được
từ trình duyệt.

| Mục | URL |
| --- | --- |
| Chính sách bảo mật | `https://hwangminghung.github.io/cunghat-legal/privacy.html` |
| Điều khoản sử dụng | `https://hwangminghung.github.io/cunghat-legal/terms.html` |

Host: GitHub Pages, repo **public** riêng `hwangminghung/cunghat-legal` (repo app
là private nên Pages không dùng được trực tiếp — Pages trên private repo cần gói
trả phí).

**Nguồn sự thật vẫn là `assets/legal/*.md` trong repo app** — cùng file mà app
đọc. Sửa nội dung thì sửa ở đó rồi đăng lại:

```bash
python scripts/build_legal_site.py /tmp/cunghat-legal
cd /tmp/cunghat-legal && git add -A && git commit -m "cap nhat" && git push
```

Đừng sửa thẳng HTML trong repo public: bản trong app và bản web phải khớp nhau,
reviewer có thể mở cả hai ra so.

> **CÒN NỢ — phải sửa trước khi nộp:** cả hai văn bản ghi liên hệ
> `hotro@cunghat.app`, là email ở tên miền **chưa sở hữu**. Đổi sang một hộp thư
> thật sự nhận được (Gmail cũng được) rồi chạy lại lệnh trên. Reviewer có thể
> thử liên hệ; và theo PDPL thì đây là kênh để người dùng thực hiện quyền của họ.

---

## 10. Production release gates (carried from earlier phases)

None of these are wired with real credentials yet — all are **OPERATOR** prerequisites
before public launch (cross-referenced in `docs/LAUNCH.md`):

| Gate | Where | What's needed |
| --- | --- | --- |
| **FCM push** | `push-fanout` Edge Function | `GOOGLE_FCM_SA_JSON` (Firebase service account), `PUSH_FANOUT_SECRET`. Firebase project + iOS APNs key. |
| **Apple receipt verification** | `validate-iap` | `APPLE_SHARED_SECRET`; App Store server-side receipt validation live. |
| **Google Play receipt verification** | `validate-iap` | `GOOGLE_PLAY_SA_JSON` (Play service account) with purchase verification. |
| **MoMo signature verification** | `create-venue-payment`, `payments-webhook` | `MOMO_PARTNER_CODE`, `MOMO_ACCESS_KEY`, `MOMO_SECRET_KEY`; verified merchant. |
| **ZaloPay signature verification** | `create-venue-payment`, `payments-webhook` | `ZALOPAY_APP_ID`, `ZALOPAY_KEY1`, `ZALOPAY_KEY2`; verified merchant. |
| **Google Maps billing (Places)** | `ingest-places-venues` | `GOOGLE_PLACES_API_KEY` with **billing enabled** (Places API New). |
| **Phone OTP (SMS)** | Supabase Auth + `send-sms` | Twilio/SMS gateway provisioned; production SMS sender. |

---

## 11. Pre-submission gate (run locally)

```
supabase db reset      # applies 0001–0023 clean
supabase test db       # all pgTAP suites pass
flutter analyze        # No issues found!
flutter test           # full suite green
```

All four must be green before tagging a release candidate.
