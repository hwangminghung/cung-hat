# Verify — Đợt Audit-Hardening (2026-07-09)

Tài liệu chứng thực (verify) cho đợt hardening sửa các finding từ audit toàn repo. Ghi lại **4 gate cuối chạy thật**, **spot-check emulator các fix chạm người dùng**, và **sổ deferred**.

---

## 1. Tóm tắt đợt

- **Nhánh:** `fix/audit-hardening`, tách từ master `5065ae0d` (sau khi merge maps-payments).
- **Nguồn:** audit 4 mảng độc lập ngày 2026-07-07 (A=DB, B=edge, C=Flutter, D=cross-cutting) — fix 2 Critical + 9 Important.
- **Phạm vi:** 5 gói / **12 task** (T1..T12); spec `docs/superpowers/specs/2026-07-07-audit-hardening-design.md`, plan `docs/superpowers/plans/2026-07-07-audit-hardening.md`.
- **Commit range:** `git log --oneline 5065ae0d..HEAD` = **24 commit** (chưa tính commit doc verify này), từ **`ccf7fe79`** (docs spec) → **`ec0014ef`** (CI job db). Gồm 2 commit docs (spec+plan) + các cặp fix/test theo từng task.

---

## 2. Findings gốc → fix → bằng chứng

| Finding | Mô tả lỗi (trên master) | Task | Fix (commit) | Bằng chứng |
|---|---|---|---|---|
| **C-C1** (Critical) | Chat mất tin nhắn vừa gửi khi rời rồi mở lại thread (4 provider chat/kèo không `autoDispose`, giữ state cũ + leak channel) | T1 | `4a7bf6e3` autoDispose 4 provider | Flutter test `79872ae5` (pin autoDispose 2 stream provider + `container.pump`); **VER-A1** |
| **A-C1** (Critical) | `purge_expired_deletions` bị FK `moderation_audit.actor` chặn → không xoá được user | T2 | `b970639b` actor nullable + `on delete set null` | pgTAP `purge_cascade_test.sql`, `502e2edc` guard `pg_constraint` chống re-wedge |
| **A-M1** | `notify_push` (`net.http_post`) lỗi làm abort insert message/join/plan | T2 | `b970639b` bọc `begin/exception when others then null` | migration guard + pgTAP purge suite |
| **D** (deletion) | `request_account_deletion` bỏ sót `device_tokens`, `profile_prompts`, `photo_paths` | T3 | `5f82e94c` | pgTAP `pdpl_refresh_test.sql` (assert thu hồi) |
| **D** (export) | `export_my_data` thiếu nhiều bảng mới | T3 | `5f82e94c` mở rộng jsonb đủ bảng | pgTAP `pdpl_refresh_test.sql` |
| **A-I1 / A-I2** | Block không cắt match (chat vẫn sống); `record_swipe` không chặn cặp đã block | T4 | `e899c86f` block cắt match + guard swipe | pgTAP `moderation_test.sql` |
| **A-M2** | `who_liked_me` lộ người đã block 2 chiều | T4 | `e899c86f` lọc block khỏi who_liked_me | pgTAP `moderation_test.sql` |
| **A-I1** | Thiếu "huỷ ghép" (unmatch không cần block/xoá tài khoản) | T5 | `e876cfdd` RPC `unmatch` + menu ⋮ ChatScreen | pgTAP `unmatch_test.sql`; **VER-A2** |
| **A-I3** | `get_keo_roster` lộ hàng `requested` cho người ngoài host | T6 | `46f2ddec` roster ẩn requested với non-host | pgTAP `roster_gate_test.sql` |
| **A-M3** | `get_keo_midpoint` lộ midpoint khi <2 vị trí | T6 | `46f2ddec` yêu cầu ≥2 vị trí | pgTAP `keo_midpoint_test.sql` |
| **B-1** | `sign-photo` bị scrape (không rate-limit, không validate) | T7 | `d3432345` rate-limit 300/ngày + validate uuid + json catch | pgTAP `photos_test.sql` (`b526e03c` assert service_role grant + body 400). *Không nằm trong harness payments.* |
| **B-2 / B-3** | `send-sms` không verify webhook signature + log OTP/phone | T8 | `e5ba4ff8` verify Standard Webhooks + bỏ log OTP | harness: `send-sms unsigned→401`, `signed→503`, `tampered→401` |
| **B-minors** | `push-fanout` / `ingest-places` secret thiếu không fail-closed | T8 | `e5ba4ff8` 503 fail-closed | harness: `push-fanout→503`, `ingest anon-jwt no secret→403` |
| **C-I3 + D** | Store hardcode giá + tile "Pro trọn đời" trùng SKU | T9 | `c19a94a7` store lấy giá từ catalog + bỏ tile trùng | pgTAP `store_products_rpc_test.sql`; Flutter billing `a02e459b` (pin thứ tự tile + giá); **VER-A3** |
| **C-I2** | Deep-link `cunghat://keo/shared/<token>` không nhận được | T10 | `a4ee877b` tách helper `deepLinkLocation` | Flutter unit test 2 shape (`plan`+`keo`) + shape lạ→null |
| **D** | CI không chạy pgTAP (invariant DB không được gác trên CI) | T11 | `57ed13fb` job `db` + `ec0014ef` de-risk | `ci.yml` job `db` (verify-on-push — xem §5) |

---

## 3. Gate cuối (số thật, chạy 2026-07-09)

| Gate | Lệnh | Kết quả | Trạng thái |
|---|---|---|---|
| Flutter test | `flutter test` | **All tests passed! — +269** | PASS |
| Flutter analyze | `flutter analyze` | **No issues found! (ran in 27.8s)** | PASS |
| pgTAP | `npx supabase test db` | **Files=40, Tests=200 — Result: PASS** | PASS |
| Harness payments/edge | `bash scripts/verify_payments_local.sh` | **PASS=24 FAIL=0** | PASS |

### Emulator spot-check (cunghat_test3, 1080×2400, đăng nhập Minh)

| # | Fix | Kịch bản | Kết quả | Screenshot |
|---|---|---|---|---|
| **VER-A1** | C-C1 chat autoDispose | Mở thread QA Phúc Rock → gửi `VERA1persist123` → back inbox → mở lại CHÍNH thread đó | **PASS** — tin nhắn VẪN HIỂN THỊ sau khi mở lại (pre-fix: biến mất tới khi restart app). DB xác nhận đã persist. | `A1b`→`A1f` |
| **VER-A2** | A-I1 unmatch | Trong chat: ⋮ → "Huỷ ghép" → dialog xác nhận → "Huỷ ghép" | **PASS** — quay về inbox, thread QA Phúc Rock BIẾN MẤT khỏi inbox (còn 2 thread). DB: `status=unmatched`, `unmatched_at` set. | `A2a`→`A2c` |
| **VER-A3** | C-I3+D store catalog | Hồ sơ → Nâng cấp | **PASS** — đúng 4 tile với giá **199k / 49k / 99k / 79k** (Nâng cấp Pro, Đẩy kèo lên top, Xem ai đã thích bạn, Bộ lọc nâng cao); **KHÔNG có tile "Pro trọn đời"**. | `A3`, `A3-store-scrolled` |
| **VER-A4** | Regression sanity | Đôi deck + Kèo board tải | **PASS** — Đôi deck (card QA An KPop) và Kèo board ("Kèo quanh bạn", empty-state) tải bình thường, không crash. | `A4a`, `A4b` |

Toàn bộ ảnh: `docs/verify-screenshots-audit-hardening/`.

---

## 4. Fix phát sinh trong review (đáng ghi)

Các subagent spec-review / quality-review bắt thêm và đã vá trong đợt:

- **`c3fdf533`** — `export_my_data` rò `commission_minor` + cờ moderation → strip khỏi export + negative test.
- **`196c6072`** — chặn **ghost-match** tái sinh sau unblock + **TOCTOU** block-vs-swipe → serialize trên pair-lock.
- **`eda2797c`** — roster: chặn **requester tự thấy row của mình** (leak ngoài host) + pin biến midpoint 2 người.
- **`cd7984ec`** — deep-link: **escape token** chống **route injection `%2F`**.
- **`ab6ad0ef`** — **double-pop guard** khi huỷ ghép (tránh pop 2 lần) + sửa comment permanence.
- **`b526e03c`** — sign-photo: **assert service_role grant** trong pgTAP + chuẩn hoá body 400.
- **`d6b2dfdb`** — harness: strip prefix `v1`, thêm **branch fanout check** + preflight `xxd`.

---

## 5. Verify-on-push (CI job `db`)

Job `db` mới trong `.github/workflows/ci.yml` KHÔNG chạy được local trên Windows nên **verify = chứng thực ở lần push đầu tiên**:

```yaml
db:
  runs-on: ubuntu-latest
  timeout-minutes: 15                 # tránh treo runner
  steps:
    - uses: actions/checkout@v4
    - uses: supabase/setup-cli@v1
      with: { version: 2.109.1 }      # pin CLI (khớp bản local đã PASS 200 test — npx resolve 2.109.1)
    - run: supabase db start
    - run: supabase test db
```

De-risk lần chạy đầu: `supabase/seed.sql` để **rỗng** (80 byte, 0 dòng lệnh — chỉ comment) để `db start` không lệ thuộc seed. **Việc còn lại: xem run CI đầu tiên khi push nhánh này lên** (kỳ vọng `db` job xanh, Files=40 Tests=200).

---

## 6. Sổ deferred (mới + còn lại)

| Mục | Trạng thái | Ghi chú |
|---|---|---|
| `dob NOT NULL` | ĐÃ XỬ LÝ trong đợt | không còn treo |
| Storage-bytes GC cho ảnh user đã purge | **P7** | `photo_paths` đã clear nhưng bytes trong bucket orphan tới khi có storage-API worker — chấp nhận |
| Lifetime-Pro SKU ("Pro trọn đời") | **pricing epic riêng** | tile đã bỏ; đã đặt guard comment "1 row/type" ở test billing |
| `nearest_venues` 1-member | chấp nhận (band-only) | midpoint gate ≥2 đã siết; nearest_venues chỉ trả band, không lộ vị trí thành viên |
| Constant-time compare cho HMAC | chấp nhận | so sánh chữ ký hiện dùng `===`; rủi ro timing-attack thấp trên webhook nội bộ |
| HTTPS universal link | **TODO(P7)** | deep-link mới xử lý scheme `cunghat://`; universal/App Links để P7 |
| Stale-`initiated` payment sweep | **ops** | đơn payment kẹt `initiated` cần cron dọn — việc vận hành |
| `formatPriceK` ≥ 1.000.000đ | cosmetic | hiển thị "1000k" thay vì "1M" — không sai số, để sau |
| **[Quan sát mới]** thứ tự tin nhắn chat khi live-append | cosmetic, NGOÀI scope | Tin vừa gửi hiện ở đáy list (live), nhưng khi mở lại thread re-sort newest-first (khác vị trí). Persistence đúng (VER-A1); chỉ là chênh thứ tự hiển thị giữa live vs reload — không thuộc phạm vi batch autoDispose |

---

## 7. Trạng thái môi trường để lại

- **Emulator:** `cunghat_test3` (emulator-5554) đang chạy; app `dev.cunghat.cung_hat` đã cài (APK debug build mới hôm nay); đang ở tab Chat/inbox của Minh.
- **DB (local):** đã dọn sạch dữ liệu seed cho spot-check (match `aaaaaaaa-…` + messages, gồm cả tin gửi qua UI). **Minh khôi phục về 2 match active gốc** (QA Linh Ballad `…0002`, QA Hân VPop `…0007`), messages gốc nguyên vẹn.
- **Docker:** 9 container Supabase healthy + `supabase_edge_runtime_cung-hat` UP (đã `docker start` để chạy harness).
- **Nhánh:** `fix/audit-hardening` — sau commit doc này sẵn sàng để user quyết merge.
