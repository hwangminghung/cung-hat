# Cùng Hát — Pro gating for creating & joining kèo

Ngày: 2026-06-27
Trạng thái: spec chờ duyệt

## Mục tiêu

Phân quyền theo gói:
- **Pro**: tạo kèo (chọn chế độ join), join không giới hạn, và (vì Pro là superset) mở luôn các tính năng trả phí hiện có.
- **Free**: KHÔNG tạo được kèo; chỉ **xin tham gia**, và bị giới hạn **tối đa 1 kèo đang hoạt động** cùng lúc.

## Quyết định đã chốt

| Hạng mục | Lựa chọn |
|----------|----------|
| Mô hình Pro | Một entitlement **`pro`** (membership) |
| Phạm vi Pro | **Superset** — `pro` mở see_likes + boost + premium_filters + tạo kèo + join không giới hạn |
| Giới hạn Free | **Tối đa 1 kèo "đang hoạt động"** = membership `join_status in ('requested','approved')` AND kèo `status='open'` AND `time_window_end > now()` |
| Kiểm soát join | Mỗi kèo có chế độ **`open`** (tự duyệt) / **`approval`** (host duyệt từng người), host chọn lúc tạo |
| Cách enforce | **Server là nguồn chân lý** (Postgres RPC/helper); client chỉ mirror cho UX |

## Kiến trúc

Tất cả luật ở Postgres (migration mới `supabase/migrations/0024_pro_keo.sql`), theo đúng pattern sẵn có (`app_private.has_entitlement`, `app_private.enforce_rate_limit`, raise `errcode='check_violation'`). Client (Flutter/Riverpod) mirror trạng thái để bật/tắt UI và hiển thị lỗi thân thiện — không bao giờ tin client.

## Phần 1 — Database & RPC (`0024_pro_keo.sql`)

Entitlement `pro` (superset):
- Mở rộng CHECK của `public.entitlements.feature` để nhận `'pro'` (drop + recreate constraint giữ các giá trị cũ: boost, see_likes, premium_filters, pro).
- `app_private.is_pro()` returns boolean: tồn tại entitlement `pro` của `auth.uid()` còn hạn (`expires_at is null or expires_at > now()`).
- Sửa `app_private.has_entitlement(p_feature)` → `is_pro() OR (entitlement p_feature còn hạn)`. ⇒ các RPC khác (who_liked_me…) tự mở cho Pro, không cần sửa.
- Thêm product `pro` vào `public.products` (sku `pro`, type `subscription`, store_product_id `com.cunghat.pro`).

Tạo kèo:
- Thêm cột `public.keo.join_mode text not null default 'approval' check (join_mode in ('open','approval'))`.
- `create_keo(...)` thêm tham số cuối `p_join_mode text default 'approval'`; đầu hàm:
  `if not app_private.is_pro() then raise exception 'pro_required' using errcode='check_violation'; end if;`
  Lưu `join_mode = coalesce(p_join_mode,'approval')`. Giữ rate-limit `create_keo` 10/ngày.
  (Tạo lại hàm với chữ ký mới; cập nhật revoke/grant cho chữ ký mới.)

Xin join:
- `request_join_keo(p_keo)`:
  - Nếu `not is_pro()`: đếm kèo active của user (loại kèo đích) — nếu `>= 1` → `raise exception 'free_join_limit' using errcode='check_violation'`.
  - Giữ check sức chứa (filled < size) và check đã 'declined'.
  - Nếu kèo `join_mode='open'` và còn chỗ → insert/update `join_status='approved'`; ngược lại `'requested'`.
  - Giữ rate-limit `join_keo` 50/ngày.
- `approve_join` / `decline_join` / `leave_keo`: GIỮ NGUYÊN.

Lỗi mới: `pro_required`, `free_join_limit` (đều `check_violation`).

## Phần 2 — Client

Providers (`lib/features/billing/application/billing_providers.dart`):
- `isProProvider` = `entitlementsProvider` chứa `'pro'`.
- `hasEntitlementProvider(f)` → true nếu set chứa `f` HOẶC chứa `'pro'` (mirror superset).

Repository (`lib/features/keo/data/keo_repository.dart`):
- `createKeo(...)` thêm `required String joinMode` → truyền `p_join_mode`.
- `requestJoinKeo` giữ chữ ký.
- Helper map lỗi (mới, ví dụ `lib/features/keo/data/keo_errors.dart`): nhận `PostgrestException`/message → `pro_required` / `free_join_limit` để UI hiển thị tiếng Việt.

Gating UI:
- Kèo board FAB "Tạo kèo": nếu `isPro` → mở `create_keo_screen`; nếu Free → bottom-sheet mời nâng cấp (nút → `/store`).
- `create_keo_screen`: thêm chọn chế độ **Mở / Cần duyệt** (SegmentedButton) → truyền `joinMode`.
- Xin tham gia (keo detail/board): gọi `requestJoinKeo`; lỗi `free_join_limit` → dialog ("đang tham gia 1 kèo… Rời kèo cũ / Nâng cấp Pro"); kèo `open` → vào thẳng (trạng thái "Đã tham gia").
- Hiển thị chip chế độ kèo trên card/detail ("Mở · vào là tham gia" / "Cần duyệt").
- `store_screen.dart`: thêm mục "Nâng cấp Pro" (dùng luồng mua stub hiện có → grant `pro`).

## Phần 3 — UX flows

Free: tạo kèo → sheet nâng cấp; xin join (approval→chờ duyệt, open→vào thẳng); đã có 1 kèo active → xin kèo thứ 2 chặn (dialog Rời/Nâng cấp); kèo cũ xong/rời → xin lại được.
Pro: tạo kèo (chọn Mở/Cần duyệt); host duyệt từng người ở kèo 'approval', kèo 'open' tự vào; join không giới hạn.
Nhãn nút theo trạng thái: Xin tham gia → Đang chờ duyệt / Đã tham gia / Đã đầy. Server quyết định; client lỡ cho bấm → server trả lỗi → dialog.

## Phần 4 — Testing

Server (`supabase/tests/`, style như `consent_gate_test.sql`):
- has_entitlement superset; create_keo non-pro→`pro_required`, pro→ok + join_mode lưu đúng; free cap (kèo thứ 2 active → `free_join_limit`; rời/kết thúc → lại được; pro unlimited); join_mode open→approved / approval→requested; giữ check sức chứa/declined/rate-limit.

Flutter (`flutter test`):
- `isProProvider`; `hasEntitlementProvider` superset; helper map lỗi; widget: FAB gating (Free→sheet, Pro→màn tạo), ô chọn chế độ, dialog `free_join_limit` có nút Nâng cấp.
- Giữ mọi `Key` cũ; không sửa logic ngoài phạm vi.

Verify: `flutter analyze` sạch, `flutter test` xanh, chạy SQL test trên Supabase local; tùy chọn verify emulator (grant `pro` qua SQL cho 1 user để so Free/Pro).

## Ngoài phạm vi (non-goals)

- Tích hợp IAP thật (vẫn dùng luồng mua stub TODO(prod) hiện có).
- Định giá/subscription lifecycle (gia hạn, hoàn tiền) — chỉ grant/he kiểm tra `expires_at`.
- Bundling lại UI store ngoài việc thêm mục Pro.
- Thay đổi schema/luồng ngoài kèo + entitlements.

## Rủi ro

- Đổi chữ ký `create_keo` → phải cập nhật mọi caller + grant/revoke; client `createKeo` phải truyền `joinMode`.
- Sửa `has_entitlement` superset ảnh hưởng mọi feature-gate → cần test kỹ (không vô tình mở nhầm cho Free).
- "Kèo active" định nghĩa theo thời gian → đảm bảo dùng `time_window_end > now()` nhất quán giữa cap và list.
