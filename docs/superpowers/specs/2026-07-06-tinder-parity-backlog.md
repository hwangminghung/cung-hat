# Backlog: Tinder-parity cho tab Đôi (+ nudge/monetization)

> Nguồn: 2 buổi test thực chiến 2026-07-05/06 trên CÙNG một điện thoại thật (Realme RMX3372):
> (1) Cùng Hát Đôi bản `feat/pro-keo-gating` (photos+carousel+boost, PR #3) — deck 8 tài khoản seed có ảnh;
> (2) Tinder VN bản thật — walkthrough đầy đủ 11 nhóm màn hình (deck, detail, swipe physics, rewind/boost
> paywall, filters, Hẹn Hò Đôi, Chiêm tinh, Khám Phá, Lượt Thích, Chat inbox, Hồ sơ/Settings).
> Ảnh chụp Tinder chứa người thật nên KHÔNG lưu trong repo; mô tả chi tiết nằm trong backlog này.

## Intel cạnh tranh chốt lại (quan sát trực tiếp)

- **⚠️ Tinder VN có 4 chế độ deck: Dành Cho Bạn / Hẹn Hò Đôi / Chiêm tinh / "Bật nhạc"** — Tinder đã dò
  vào lãnh địa ghép-đôi-qua-nhạc. Cùng Hát phải chạy sâu hơn (bài tủ + Kèo + quán) chứ không chỉ "có nhạc".
- **Giá thật thị trường VN (mỏ neo cho pricing Pro):** Tinder Plus **35.000đ/tuần** (gói 1 tuần, badge
  "Phổ biến"); Boost lẻ **139k/1 · 116k/5 (−17%) · 90.6k/10 (−35%) đ/lượt**; Siêu thích mua thêm theo gói.
  Gate map: Rewind/Passport→Plus · See-likers/Top Picks→Gold · nhắn-trước-match/priority likes→Platinum ·
  Boost/Siêu thích→tiêu hao · 15 bộ lọc nâng cao→khoá premium ("Mở khóa").
- **Paywall theo ngữ cảnh:** bấm tính năng nào → sheet bán ĐÚNG tính năng đó (headline khớp), carousel gói,
  badge "Phổ biến"/"Giá Trị Nhất", fine-print auto-renew. Chuyển đổi tốt hơn upsell chung.
- **Hồ sơ Tinder giàu:** 9 ảnh + chip info XOAY THEO TỪNG ẢNH (bio → khoảng cách → sở thích → cung/lifestyle);
  thẻ hỏi-đáp kiểu Hinge; lifestyle (thú cưng/rượu/thuốc/social); ngôn ngữ tình yêu; mục "Đang tìm kiếm";
  nút **"Trả lời"** trên từng ảnh/từng mục (icebreaker + Platinum).
- **Gamification hồ sơ:** thanh hoàn thiện % + phần thưởng định lượng ("6 ảnh = x2 lượt thích",
  "+25% match khi có bio"); ví Siêu thích/Boost với nút MUA THÊM.
- **Khám Phá:** deck chủ đề kèm SỐ NGƯỜI LIVE ("Mối quan hệ nghiêm túc 2K", "Người yêu 3K"…); trong deck,
  số quota còn lại hiện NGAY TRÊN NÚT hành động.
- **Nudge:** inbox có pill "Đến lượt bạn"; Lượt Thích blur nhưng lộ tuổi+tick+1 sở thích; "Top Tuyển chọn"
  4 người/ngày không blur + đếm ngược "Còn 22 giờ"; hàng "Tương hợp mới" có ô teaser vàng "1 lượt Thích".
- **Filters:** khoảng cách 47km + toggle "MỞ RỘNG KHI HẾT NGƯỜI" (2 toggle riêng cho distance/age);
  15 bộ lọc nâng cao khoá premium (tối thiểu ảnh, có bio, học vấn, gia đình tương lai, ngôn ngữ tình yêu…).
- **Swipe physics:** card nghiêng + dấu ✕/❤ to dần theo tiến độ + NÚT action bar sáng/nở đồng bộ khi kéo.
- **Điểm yếu Tinder quan sát được:** deck VN nhiều hồ sơ ảo/AI; không có "lý do match" trên card;
  lộ khoảng cách khá chính xác ("Cách xa 4 km"); Hẹn Hò Đôi chỉ là chat 4 người (không hoạt động thật).

## Cùng Hát đang thắng — GIỮ VỮNG, không phá

1. **Kèo**: nhóm 2-5 + host duyệt + all-confirm + chọn quán điểm giữa (Tinder Double Date nông hơn hẳn).
2. **Lý do match hiện trên card**: chip "cùng N bài tủ" + #genre — Tinder không có.
3. Riêng tư mặc định: dải khoảng cách, toạ độ server-only (đã đúng, đừng đổi theo Tinder).
4. Tuân thủ VN (PDPL consent, NĐ147 moderation) + MoMo/ZaloPay cho venue.

## BACKLOG ưu tiên (làm theo thứ tự; mỗi mục = 1 task subagent-driven có TDD + 2-stage review)

### 🥇 P0 — chuyển đổi & launch-critical
1. **Paywall theo ngữ cảnh + neo giá VN**: refactor ProUpsellSheet → biến thể theo tính năng
   (boost/rewind/see-likes/keo) với headline đúng tính năng + giá; phối hợp nhánh
   `codex/pro-pricing-keo-boost` (đang định giá) — tham chiếu neo 35k/tuần, boost lẻ 90-140k.
2. **"Mở rộng bán kính khi hết deck"**: toggle trong get_discovery_candidates (tham số bán kính) + UI ở
   màn hết deck ("Mở rộng tìm quanh 100km?") — SỐNG CÒN cho cold-start Thái Nguyên.
3. **Card UX pack** (3 việc nhỏ, 1 task): (a) tap nửa trái/phải card để chuyển ảnh (mở detail dời về
   nút/mũi tên riêng — giải quyết xung đột gesture kiểu Tinder); (b) nút action bar sáng/nở đồng bộ theo
   tiến độ kéo (khớp swipe_overlays hiện có); (c) chip info xoay theo ảnh (ảnh 1 = khoảng cách+bài tủ,
   ảnh 2 = genres, ảnh 3 = bio…).

### 🥈 P1 — độ giàu hồ sơ & khám phá
4. **Thẻ hỏi-đáp karaoke** (prompt Q&A): 5-8 câu cố định ("Bài mình luôn giành mic là…", "Thể loại hát khi
   buồn…"), chọn 2-3 câu khi onboarding/hồ sơ; hiện thành card trong detail sheet.
5. **Thanh hoàn thiện hồ sơ + thưởng định lượng**: % hoàn thiện ở tab Hồ sơ ("thêm 2 ảnh → x2 lượt được
   thấy", "thêm 3 bài tủ → dễ vào kèo hơn").
6. **Deck chủ đề nhạc (mini-Khám Phá)**: board "Đêm Ballad / Hội Rap / Bolero chill" từ taste graph sẵn có
   + số người live mỗi deck; entry từ tab Đôi.
7. **Pill "Đến lượt bạn"** trong inbox/kèo: kèo chờ mình confirm, match chưa nhắn.

### 🥉 P2 — polish & viral
8. **Trả lời theo ảnh/bài tủ** (icebreaker): react 1 chạm vào ảnh/bài tủ của candidate → mở chat với quote.
9. **Teaser "Ai thích bạn"**: blur + lộ tuổi/tick/1 genre (thay vì chỉ đếm) → tăng chuyển đổi see_likes.
10. **Nút chia sẻ hồ sơ/kèo** (deep link sẵn có `cunghat://`).
11. **Tăng trần ảnh 3→6** (migration check >6, UI 6 ô, carousel giữ nguyên).
12. **Fix ô OTP thứ 6 tràn 10px** trên màn hẹp (thấy trên Realme RMX3372 — RIGHT OVERFLOWED BY 10 PIXELS).

### Chèn card Kèo vào deck Đôi (đánh giá riêng)
13. **Interleave "Kèo tối nay gần bạn" mỗi N card** trong deck Đôi (học cách Tinder trộn card Hẹn Hò Đôi)
    — card kiểu "3/5 chỗ · 20h tối nay · quán X · #ballad". Cần design cẩn thận để không phá flow vuốt
    → brainstorm trước khi cam kết.

## Ghi chú thực thi cho session mới
- **Nhánh**: tạo `feat/tinder-parity` TỪ `feat/pro-keo-gating` (đợi PR #3 merge thì rebase sau).
  LÀM TRONG WORKTREE RIÊNG — checkout chính ở thư mục gốc đang là `master` do các agent Codex khác
  làm việc (`ch-media`, `ch-pro-pricing-boost`…), TUYỆT ĐỐI không đổi branch ở thư mục gốc.
- Quy trình: superpowers brainstorming → writing-plans → subagent-driven-development
  (implementer + spec review + code-quality review từng task + final holistic review).
- Gotchas môi trường: xem memory `project-cung-hat` (AF_UNIX build workaround đã nằm trong
  gradle.properties của nhánh; psql qua docker exec; SQL tiếng Việt qua docker cp + psql -f;
  `supabase migration up` không dùng db reset; không đụng `supabase/tests/chat_media_test.sql.pending`;
  test OTP 84900000001-007 = 123456; verify device qua `adb reverse tcp:54321 tcp:54321` + env 127.0.0.1).
- Gates mỗi task: `flutter test` + `flutter analyze` (+ `supabase test db` nếu đụng DB) xanh; cuối đợt
  verify emulator/điện thoại + log docs/verify-*.
