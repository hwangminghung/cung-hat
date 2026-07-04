# Kiểm thử 3 tài khoản / 3 emulator — Ảnh hồ sơ + Carousel + Boost

Ngày: 2026-07-04 · Nhánh: `feat/pro-keo-gating` · Build: debug APK
Người chạy: xác minh end-to-end trên 3 emulator, có driving UI + đối chiếu DB.

> **TL;DR** — Ảnh RENDER NATIVE cross-account sau BUG-1 fix (KHÔNG cần patch edge). Nhưng
> **APK trên đĩa/đã cài ban đầu là bản 15:23 CŨ — chưa có fix**; phải **rebuild + cài lại**
> APK 20:56 (đã chứa 2 commit fix) thì ảnh mới render. Phát hiện **BUG-2 mới**: carousel
> detail chỉ render ảnh #1; ảnh #2 luôn fallback về monogram (dù ảnh #2 servable trên server).

## Ánh xạ tài khoản / emulator / UUID

| Acct | Emulator | Phone | UUID | Tên | Ghi chú |
|------|----------|-------|------|-----|---------|
| A | `emulator-5554` | 84900000001 | `0462e321-daad-4a01-b460-a95647634617` | Minh | đã onboard SG, 2 ảnh (upload từ run trước) |
| B | `emulator-5556` | 84900000002 | `ce33ee2b-41cb-48ba-8a97-bd59d47ce184` | Test B | đã onboard SG; upload 2 ảnh trong run này |
| C | `emulator-5558` | 84900000003 | `7747026a-c662-4f74-a62b-1cbeb21ce39d` | Test C | **ONBOARD MỚI** trong run này (SG); upload 2 ảnh |

App package: `dev.cunghat.cung_hat`. OTP code luôn `123456`.

## P0 — Setup / cleanup

- **Xoá block leftover B→A**: `DELETE 1` (bảng `public.blocks`).
- **Xoá swipe leftover A→B (like)**: `DELETE 1` (bảng `public.swipes`; PK = swiper_id/target_type/target_id).
- **Onboard C**: sinh 1/1/2000 (26t); bật CẢ 5 consent (gồm `photos` → C không bị gate khi upload);
  tên "Test C"; genres Ballad+V-Pop; artist Mỹ Tâm; bài tủ Lạc Trôi.
- **Seed vị trí C** tại SG `POINT(106.7 10.776)` (area_label 'Sài Gòn') — GPS emulator KHÔNG tới app
  (giới hạn env đã biết; giống run 2-account). A và B đã có sẵn `user_locations` tại cùng điểm SG.
  Seed C tồn tại qua các lần khởi động lại (GPS không ghi đè).

## ⚠️ Phát hiện setup lớn: APK đã cài KHÔNG chứa BUG-1 fix (ban đầu)

- 2 commit fix: `40801f6f` (20:33) + `78294039` (20:41).
- APK trên đĩa (`build/app/outputs/flutter-apk/app-debug.apk` **và** `apk/debug/…`) đều timestamp
  **2026-07-04 15:23** — TRƯỚC 2 commit fix. Cài lên 3 máy lúc ~20:40 = **bản CŨ, không có fix**.
- Hệ quả: khi B/C upload ảnh trên APK cũ, thumbnail slot HỎNG với lỗi
  `SocketException: Failed host lookup: 'kong' (OS Error: No address associated with hostname, errno = 7)`
  → ảnh `docs/verify-screenshots-3acct/B-photos-uploaded-BUG-kong.png`, `B-slot-kong-error-zoom.png`.
  (Upload vẫn thành công server-side; chỉ preview client hỏng.)
- **Hành động**: rebuild `flutter build apk --debug --dart-define-from-file=env/dev.emulator.json`
  → APK mới **20:56** (SAU 2 commit fix) → `adb install -r` cả 3 máy (giữ data/session) → relaunch.
- Sau khi cài bản có fix, mọi kiểm thử render ảnh chạy trên bản đúng.

Env emulator: `SUPABASE_URL=http://10.0.2.2:54321` (nên `rebaseOrigin(kong:8000 → 10.0.2.2:54321)` là fix đúng).

## Ma trận kết quả (chạy trên APK ĐÃ CÓ fix, 20:56)

| Bước | Kết quả quan sát | Screenshot | Trạng thái |
|------|------------------|------------|-----------|
| **1. B & C upload 2 ảnh** | B: cần bật consent `photos` (gate "Bật trong Cài đặt" → Settings → toggle) rồi upload B-Anh1/B-Anh2. C: consent sẵn từ onboarding, upload C-Anh1/C-Anh2. Server: B `photo_paths` 2 path dưới uid B, C 2 path dưới uid C; `storage.objects` bucket profile-photos tăng lên 8 (A2+B2+C2+seed2). **Thumbnail slot RENDER NATIVE** (B xanh lá/cam, C tím/xanh mòng két) — KHÔNG còn lỗi `kong`. | `B-photos-uploaded.png`, `C-photos-uploaded.png` | **PASS** |
| **2. Render ảnh cross-account (bằng chứng BUG-1 fix)** | C thấy A (Minh) với ảnh thật "A-Anh1" + 2 chấm; C thấy B (Test B) với "B-Anh1" + 2 chấm. A thấy B với "B-Anh1". Tất cả NATIVE, KHÔNG patch edge. | `C-sees-A-photo-native-Minh.png`, `C-sees-B-photo-native.png`, `A-sees-B-photo-native.png` | **PASS** |
| **3. Carousel swipe sang ảnh #2** | Mở detail A trên C: slide 1 = "A-Anh1" (chấm 1). Swipe → chấm 2 active NHƯNG slide 2 hiện **monogram "M"** thay vì "A-Anh2". Lặp lại với B trên A (ảnh B mới upload trong session): slide 2 = monogram "T". Ảnh #2 servable qua curl (200 image/jpeg) → **BUG-2**. | `C-carousel-A-photo1.png`, `C-carousel-A-photo2-BUG-monogram.png`, `A-carousel-B-photo2-BUG-monogram.png` | **BUG** (xem BUG-2) |
| **4. Match 3-chiều A↔C** | A like C, rồi C like A → màn **MatchCelebration** "Hợp cạ rồi! Bạn và Minh đã thích nhau" (T ♥ M). `matches` có 1 row (user_a=A, user_b=C, active). | `AC-match.png` | **PASS** |
| **5. Boost xếp hạng (observer trung lập C)** | UI: bấm bolt trên A báo "Bạn đã dùng hết lượt boost hôm nay" (A đã boost trong run trước → limit ngày). Xác minh bằng RPC `get_discovery_candidates` chạy như C: **boost ACTIVE → Minh(A) TRƯỚC Test B(B)**; **bỏ boost → Test B(B) TRƯỚC Minh(A)**. Thứ tự đảo đúng theo term +3.0. UI C (restart, boost active): card top = Minh(A) trên B. | `C-deck-A-boosted-above-B.png`, `A-boost-limit-snackbar.png` | **PASS** (qua RPC + UI; nút UI dính limit ngày) |
| **6. Block pair-scoped** | B mở card A → "…" → "Chặn người này" → SnackBar "Đã chặn", A BIẾN MẤT khỏi deck B (top thành Test C). `blocks` có row B→A. C refresh: **A (Minh) VẪN còn** với ảnh (RPC C vẫn trả Minh). Block chỉ ảnh hưởng cặp B↔A. | `B-blocked-A-gone.png`, `C-still-sees-A.png` | **PASS** |

## Câu hỏi tiêu điểm: Ảnh có render NATIVE cross-account KHÔNG cần patch edge (BUG-1 fix xác nhận)?

**CÓ — sau khi cài đúng APK chứa fix.** Với APK 20:56:
- Slot manager render ảnh thật (B/C), KHÔNG lỗi `kong`.
- Deck cross-account render ảnh thật (C thấy A & B; A thấy B), KHÔNG patch edge-function.
- `rebaseOrigin` (photo_repository.dart) đổi origin `kong:8000` → `10.0.2.2:54321` đúng như thiết kế.

**Cảnh báo**: APK "hiện có" ban đầu (15:23) KHÔNG chứa fix và cho lỗi `kong`. Nếu deploy/CI dùng lại
artifact cũ sẽ tái hiện lỗi. Cần đảm bảo build lại sau 2 commit fix.

## BUG được phát hiện

### BUG-2 (MỚI, đang mở): Carousel detail chỉ render ảnh #1; ảnh #2 luôn fallback monogram
- **Nơi**: `lib/features/photos/presentation/photo_carousel.dart` — `_Pager` dùng
  `Image.network(urls[i], errorBuilder: → _fallback(monogram))`.
- **Repro**: mở detail sheet của 1 user có ĐÚNG 2 ảnh (A hoặc B); swipe sang slide 2.
  Số chấm = 2 (nên `signedUrlsProvider` trả 2 URL), slide 1 render OK, **slide 2 luôn ra monogram**.
- **Loại trừ**: (a) ảnh #2 của cả A và B đều **servable** qua signed URL (curl → HTTP 200, image/jpeg,
  ~8KB); (b) tái hiện với B (ảnh upload MỚI trong session) → không phải dữ liệu cũ của A;
  (c) mở detail mới + swipe ngay (trong <60s) vẫn hỏng → **không phải token hết hạn** (edge ký expiry 60s);
  (d) logcat không có lỗi HTTP nổi lên (Image.network nuốt vào errorBuilder).
- **Triệu chứng**: `Image.network(urls[1])` fail load trong app dù URL #2 reachable. Cần điều tra sâu
  (khả năng: cách rebase/parse URL thứ 2, hoặc hành vi PageView.builder lazy). **Chưa fix** (theo yêu cầu exploratory).
- **Bằng chứng**: `C-carousel-A-photo2-BUG-monogram.png`, `A-carousel-B-photo2-BUG-monogram.png`.

### Quan sát phụ (không chặn, có thể cùng gốc với BUG-2 hoặc cache provider)
- Trên deck A, card của C có lúc render **toàn monogram "T"** (cả ảnh #1 cũng không lên, có blob trang trí
  = nhánh `urls.isEmpty`) dù C đã upload 2 ảnh. Nghi do `signedUrlsProvider(C)` bị cache RỖNG từ lúc C
  chưa có ảnh (C từng xuất hiện monogram trước khi upload) và refresh không invalidate cache đó. Ngược lại
  C thấy A/B và A thấy B đều render ảnh #1 bình thường. Cần xem lại invalidation của `signedUrlsProvider`
  khi target vừa thêm ảnh.

### BUG-1 (đã fix trong source, KHÔNG có trong APK cũ) — chỉ để lưu vết
- APK 15:23 render slot/deck với lỗi `SocketException: Failed host lookup: 'kong'`. Fix `rebaseOrigin`
  đã có trong source (HEAD 78294039) và xác nhận hoạt động trên APK 20:56. Bằng chứng lỗi cũ:
  `B-photos-uploaded-BUG-kong.png`, `B-slot-kong-error-zoom.png`.

## Không kiểm được / lý do
- **Nút boost qua UI**: A đã dùng hết lượt boost trong ngày (SnackBar limit) → không tạo được `boosts` row
  qua UI. Đã kiểm bản chất xếp hạng bằng INSERT boost trực tiếp + RPC `get_discovery_candidates` (đảo thứ
  tự A/B đúng theo term +3.0) và UI deck C (A lên top khi boost active). Kết luận boost PASS ở tầng
  ranking/RPC; chỉ đường-nút-UI bị chặn bởi limit ngày.
- **GPS→user_locations tự động**: emulator không đẩy GPS vào app (giới hạn env) → seed SQL cho C.

## Cleanup đã làm
- Xoá entitlement `pro`/`promo` của A (`DELETE 1`).
- Xoá `boosts` row của A (`DELETE 1`).
- **Giữ lại** (theo yêu cầu): ảnh đã upload của A/B/C, tài khoản C, block cuối B→A (`blocks` còn 1 row B→A).
- KHÔNG `supabase db reset`; KHÔNG đụng `supabase/tests/chat_media_test.sql.pending`, `supabase/config.toml`.

## Screenshots
Thư mục: `docs/verify-screenshots-3acct/`
`B-photos-uploaded.png`, `C-photos-uploaded.png`, `B-photos-uploaded-BUG-kong.png`, `B-slot-kong-error-zoom.png`,
`C-sees-A-photo-native-Minh.png`, `C-sees-B-photo-native.png`, `A-sees-B-photo-native.png`,
`C-carousel-A-photo1.png`, `C-carousel-A-photo2-BUG-monogram.png`, `A-carousel-B-photo2-BUG-monogram.png`,
`AC-match.png`, `C-deck-A-boosted-above-B.png`, `A-boost-limit-snackbar.png`,
`B-blocked-A-gone.png`, `C-still-sees-A.png`.
