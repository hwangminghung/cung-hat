# Fix 3 lỗi UI trước merge feat/ui-retro (so khớp mockup 2026-07-13)

> Executed inline (3 fix nhỏ, context sẵn). Gates mỗi commit: analyze 0 + full test + pgTAP (`supabase test db`) khi đụng migration.

**F1 — Match sheet giờ raw UTC (mockup 12).** `keo_match_sheet.dart _formatTimeWindow`: đổi `toUtc()` → `toLocal()`, bỏ hậu tố " UTC", cùng ngày local thì chỉ hiện `HH:mm - HH:mm`. Test `keo_match_sheet_test.dart` đổi 2 assertion sang expected TÍNH ĐỘNG từ `DateTime.parse(...).toLocal()` (không hardcode — CI khác TZ).

**F2 — Nút "Đồng ý tham gia" không đổi trạng thái (mockup 14).** Migration mới `20260713120000_roster_confirmed_keo_header.sql`: drop `get_keo_roster`, `alter type keo_member_row add attribute confirmed boolean`, recreate hàm select thêm `m.confirmed` (giữ nguyên gating A-I3), re-revoke/grant. Dart: `KeoMember` + `@Default(false) bool confirmed` (regen freezed). UI: roster chip hiện "Đã xác nhận" khi approved+confirmed; `_ActionPanel` nhận `isConfirmed`, nút confirm chỉ hiện khi `isApproved && !isHost && !isConfirmed`. pgTAP: assert cột confirmed trả đúng. Widget test: member confirmed → không còn `confirm_keo_btn`, có chip "Đã xác nhận".

**F3 — Ticket detail thiếu giờ + khu vực (mockup 14).** Cùng migration: RPC mới `get_keo_header(p_keo)` returns table (id/title/status/join_mode/time_window_start/time_window_end/area_label/`group_size_target as size_target`) — alias khớp JsonKey của model `Keo` để KHÔNG cần model mới; gate: `status='open'` OR host OR có row keo_members approved/requested; bỏ qua soft_deleted. Dart: `KeoRepository.header()` (null nếu rỗng), `keoHeaderProvider` FutureProvider.family, `_Header` nhận `Keo? info` → 2 hàng icon giờ (format local như keo_card) + khu vực; provider lỗi/null → giữ layout cũ (test cũ không stub header vẫn pass nhờ AsyncError → valueOrNull null). pgTAP: host/member/requester thấy header kèo planning, outsider bị chặn khi planning nhưng thấy khi open.

Bẫy đã tính: không đụng Key hiện có; mocktail unstubbed → MissingStubError bị FutureProvider nuốt thành AsyncError (fallback OK); pgTAP cũ chỉ count(*) nên thêm cột không vỡ.
