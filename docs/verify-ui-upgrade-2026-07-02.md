# Verify log — UI upgrade (UI/UX Pro Max), 2026-07-02

## Verdict: PASS (emulator, APK debug thật)

**Scope:** Các thay đổi UI theo design system `design-system/MASTER.md`:
theme (Baloo 2 + amber secondary + brandGradient + AppMotion), widget mới
(`Pressable`, `Skeleton`/`SkeletonTile`/`SkeletonCard`), EmptyState gradient,
KeoCard press feedback, skeleton loading (board Kèo, detail Kèo, inbox, likes,
deck Đôi), candidate card gradient, match celebration redesign.

**Method:** Build `flutter build apk --debug` → cài lên emulator `cunghat_test`
(AVD android-35), Supabase local (Docker), login OTP test `+84900000001`/`123456`,
drive bằng adb input + screencap. Screenshot lưu tại scratchpad phiên làm việc
(s01–s17).

## Steps

1. ✅ Build APK debug → thành công 131s (sau workaround AF_UNIX, xem dưới)
2. ✅ Cài + mở app → màn Đăng nhập render đúng theme mới: heading **Baloo 2**, coral brand, input/button đúng token
3. ✅ Nhập `900000001` (app tự prefix +84) → màn OTP nhận đúng số
4. ✅ Nhập OTP 123456 → server GoTrue xác nhận login 200 (`user_signedup`, `Login`)
5. ⚠️ 🔍 Sau verify thành công UI **đứng yên ở màn OTP** — không tự chuyển màn; phải cold-restart app mới vào home (xem Findings #1)
6. ✅ Home tab Đôi → **EmptyState mới** render chuẩn: vòng tròn 2 lớp gradient coral→amber, icon trắng, title + subtitle + entrance animation
7. ✅ Tab Kèo → board load kèo seed "Keo emulator day top": KeoCard đúng thiết kế (mode chip, meta icons, genre chip coral tint), header **"Tìm nhóm đi hát"** font Baloo 2 rõ nét
8. ✅ Mở kèo → **bắt được SkeletonTile** (3 avatar tròn + line mờ) hiện trong lúc roster load, transition fade mượt
9. ✅ 🔍 Giữ tay 900ms trên KeoCard, chụp giữa chừng → card **co ~0.96** (Pressable scale 0.97) và layout xung quanh không shift
10. ✅ Tab Chat → EmptyState gradient mới ("Chưa có cuộc trò chuyện nào")

**Chưa exercise được trên máy:** match celebration (cần mutual match 2 user),
candidate card gradient + deck skeleton (user test mới, không có candidate quanh),
skeleton board Kèo (data về nhanh hơn 1 frame chụp). Các phần này chỉ được verify
ở mức `flutter analyze` sạch + cùng pattern với phần đã thấy chạy đúng.

## Findings

- ⚠️ **BUG (pre-existing, không thuộc UI changes): verify OTP thành công nhưng router không redirect.** Server trả 200, session được cấp, nhưng màn OTP đứng yên không lỗi. Cold-restart thì vào app bình thường → auth state stream / `GoRouterRefreshStream` không fire sau verify. Người dùng thật sẽ tưởng app treo ngay bước đầu tiên. Đáng fix sớm.
- ⚠️ **Banner "Ghép nhóm cho tôi" thiếu dấu tiếng Việt:** "Tu dong goi y keo hop gu, gan ban" → phải là "Tự động gợi ý kèo hợp gu, gần bạn".
- Badge verified trong keo detail dùng `Icons.verified` màu xanh dương mặc định — lệch palette coral/amber, nên đổi sang token màu brand.
- Web splash mặc định tím `#6750A4` với chữ "CH" — lệch brand coral (chỉ ảnh hưởng bản web).
- 🔍 Nhập `84900000001` (có 84 thừa vì app tự prefix +84) → server trả lỗi Twilio 20003 và app hiện nguyên văn `AuthApiException(...)` — nên map thành thông báo tiếng Việt thân thiện.

## Environment workarounds đã áp (giữ lại cho dev máy này)

| Vấn đề | Fix | File |
|---|---|---|
| Gradle "Unable to establish loopback connection" (bug AF_UNIX của Windows build 26200; `netsh winsock reset` + reboot KHÔNG hết) | Ép JDK fallback TCP pipe: `-Djdk.net.unixdomain.tmpdir=<path >108 ký tự>` | `android/gradle.properties` (daemon); set thêm `JAVA_TOOL_OPTIONS` khi build từ shell |
| `flutter test`/`build web` fail "Building native assets failed" (hook `objective_c` bể vì dấu cách trong `C:\Users\Hwang Ming Hung`) | `dependency_overrides: path_provider_foundation: 2.3.2` | `pubspec.yaml` |
| Bản web kẹt splash: plugin `passkeys_web` crash khi thiếu Corbado SDK | Stub `window.PasskeyAuthenticator` (app dùng OTP, không dùng passkey) | `web/index.html` |
| Emulator cần tới Supabase local | env riêng `SUPABASE_URL=http://10.0.2.2:54321` | `env/dev.emulator.json` |

Marker `print('[boot] ...')` tạm trong `lib/main.dart` — **cần gỡ trước khi commit**.
