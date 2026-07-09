# Spec: Đợt Audit-Hardening (fix 2 Critical + 9 Important từ audit toàn repo)

**Ngày:** 2026-07-07 · **Nhánh:** `fix/audit-hardening` (từ master `5065ae0d`)
**Nguồn:** audit 4 mảng độc lập (A=DB, B=edge, C=Flutter, D=cross-cutting) chạy trên master sau merge maps-payments. Spec này chốt các quyết định thiết kế; findings gốc tham chiếu theo mã [A/B/C/D-*].

## 1. Phạm vi — 5 gói, 13 task

| Gói | Nội dung | Findings |
|---|---|---|
| G4 Chat (Critical UX) | autoDispose 4 provider chat/kèo + regression test | C-C1 |
| G1 Pháp lý/dữ liệu | FK purge + guard notify_push; deletion bổ sung; export mở rộng | A-C1, A-M1, D-imp |
| G2 Trust & Safety | block cắt match, guard record_swipe, lọc who_liked_me, unmatch RPC+UI, gate roster, midpoint ≥2 | A-I1, A-I2, A-I3, A-M2, A-M3 |
| G3 Edge cũ | sign-photo rate-limit; send-sms webhook-signature + bỏ log OTP; fanout/ingest 503 | B-1, B-2, B-3, B-minors |
| G5 Revenue/UX/CI | store theo catalog; deep-link kèo chiều nhận; CI thêm supabase test db | C-I3+D, C-I2, D-imp |

NGOÀI scope (ghi sổ deferred): storage-bytes GC cho ảnh user đã purge (cần storage-API worker — P7); hard-delete mở rộng khác; lifetime-Pro SKU (thuộc pricing epic riêng); các Minor còn lại của audit.

## 2. Quyết định thiết kế (điểm cần duyệt)

1. **sign-photo [B-1]: GIỮ visibility model hiện tại** (ảnh hiện pre-match trong deck — gate theo "đang trong deck" là bất khả thi vì deck phù du, còn recompute eligibility thì đắt và sẽ lệch logic deck). Fix chống scrape = **rate-limit server-side: tối đa 300 lượt sign cho target khác mình/ngày/caller** (đếm qua bảng `rate_limits` sẵn có, ghi bằng service-role trong function) + validate `target_id` là uuid + bọc `req.json().catch`. Vượt limit → 429.
2. **Block semantics [A-I1/I2]:** `block_user` giờ đồng thời **unmatch cặp** (status='unmatched', unmatched_at=now()) — chat chết ngay vì `in_match` đòi status='active'. KHÔNG ẩn message cũ (đúng hành vi unmatch thường; message ẩn chỉ khi xoá tài khoản như hiện tại). `record_swipe` chặn cặp đã block 2 chiều (raise `blocked_pair`/check_violation trước khi ghi swipe). `who_liked_me` lọc block 2 chiều [A-M2].
3. **Unmatch RPC + UI [A-I1]:** RPC mới `unmatch(p_match uuid)` — membership-gated, set unmatched (idempotent). UI: menu trong ChatScreen AppBar (icon ⋮) mục "Huỷ ghép" + dialog xác nhận → gọi RPC → pop về inbox + invalidate inbox.
4. **get_keo_roster [A-I3]:** ai cũng gọi được NHƯNG: hàng `requested` chỉ trả cho **host**; non-member/member thường chỉ thấy `approved`. (Giữ preview roster trên detail cho người xem kèo — đúng sản phẩm.)
5. **get_keo_midpoint ≥2 [A-M3]:** yêu cầu ≥2 thành viên approved+confirmed CÓ vị trí; ngược lại trả 0 hàng (client đã xử lý null).
6. **export_my_data [D]:** mở rộng thành 1 jsonb document gồm thêm: `prompts`, `messages_sent` (thread_type/thread_id/body/created_at), `swipes_made`, `matches` (id/status/created_at), `keo_hosted` (title/time/status), `keo_joined` (keo_id/join_status/confirmed), `purchases`, `entitlements`, `venue_bookings`, `boosts`, `checkins`, `device_tokens`, `blocks_made`, `share_links`. Vẫn strip `report_risk`.
7. **request_account_deletion [D]:** thêm `delete from device_tokens`, `delete from profile_prompts`, `update profiles set photo_paths='{}'`. Bytes ảnh trong bucket → orphan tới khi có storage-GC (P7) — chấp nhận, ghi sổ.
8. **Purge FK [A-C1]:** `moderation_audit.actor` → nullable + `on delete set null` (giữ audit row, mất danh tính actor đã rời — chấp nhận cho audit nội bộ). pgTAP purge-cascade test seed user có row ở TẤT CẢ bảng mới (purchases/entitlements/boosts/device_tokens/venue_bookings/moderation_audit-actor) + 1 user 31 ngày, chạy purge, assert sạch + user khác còn nguyên.
9. **notify_push [A-M1]:** bọc `net.http_post` trong `begin/exception when others then null end` (khớp pattern `broadcast_message`) — pg_net lỗi không được phép abort insert message/join/plan.
10. **Chat providers [C-C1]:** cả 4 (`messageHistoryProvider`, `liveMessagesProvider`, `keoMessageHistoryProvider`, `keoLiveMessagesProvider`) thành `.autoDispose.family`. ChatScreen/KeoChatScreen đang rebuild history khi vào màn → an toàn. Regression test: rewatch history provider sau dispose → repo.history được gọi lần 2 (không trả cache).
11. **send-sms [B-2/B-3]:** verify **Standard Webhooks signature** thủ công (~20 dòng): headers `webhook-id`/`webhook-timestamp`/`webhook-signature`; expected = base64(HMAC-SHA256(`${id}.${timestamp}.${rawBody}`, base64decode(secret sau `whsec_`))); so khớp mọi entry `v1,<sig>` (space-separated); lệch/thiếu → 401. Thiếu env `SEND_SMS_HOOK_SECRET` → 503 fail-closed. Timestamp lệch >5 phút → 401 (chống replay). XOÁ log OTP/phone. `config.toml` thêm `[functions.send-sms] verify_jwt = false`. Verify local bằng payload tự ký (harness bổ sung check).
12. **push-fanout/ingest [B-minors]:** secret env thiếu/rỗng → 503 `*_not_configured` (đồng bộ pattern payment); push-fanout bỏ log `title`/`data` (giữ đếm user_ids).
13. **Store [C-I3+D]:** `get_store_products` mở rộng trả `(sku, type, store_product_id, price_minor)`; StoreScreen build tiles từ catalog provider (copy/icon giữ theo map type→copy cứng trong UI), **bỏ tile "Pro trọn đời 699k"** (lifetime SKU = pricing epic riêng), giá hiển thị format từ `price_minor` (199000 → "199k"). `buy(feature)` giữ nguyên (1 SKU/feature sau khi bỏ tile trùng). Test: tile giá khớp catalog mock.
14. **Deep-link kèo [C-I2]:** tách helper pure `String? deepLinkLocation(Uri)` (nhận cả `cunghat://plan/<token>` → `/plan/shared/<token>` lẫn `cunghat://keo/shared/<token>` → `/keo/shared/<token>`); `_handleUri` dùng helper; unit test helper cho cả 2 shape + shape lạ → null.
15. **CI [D]:** job mới `db` trong ci.yml: `supabase/setup-cli@v1` → `supabase db start` → `supabase test db`. Không chạy được local trên Windows — verify = YAML đúng + CI chạy khi push (chấp nhận verify-on-push, ghi rõ trong verify doc).

## 3. Ràng buộc giữ nguyên
- Store-policy split, privacy toạ độ (mọi thay đổi G2 chỉ SIẾT thêm), fail-closed.
- Gates mỗi task: flutter test + analyze + supabase test db (khi đụng DB) 100%; commit ASCII subject + Co-Authored-By.
- Migration mới đánh số timestamp nối sau `20260707220000`.
- Quy trình: subagent-driven-development (implementer + spec review + quality review mỗi task) → final review → verify (harness mở rộng + emulator spot-check chat/block/unmatch) → DỪNG chờ user quyết merge.

## 4. Thứ tự task
T1 (G4 chat) → T2 purge-FK+notify_push+pgTAP → T3 deletion+export+pgTAP → T4 block-sever+swipe-guard+who_liked_me+pgTAP → T5 unmatch RPC+UI+test → T6 roster gate+midpoint≥2+pgTAP → T7 sign-photo → T8 send-sms+fanout/ingest+harness checks → T9 store catalog → T10 deep-link kèo → T11 CI → T12 final gates+verify doc+final review.
