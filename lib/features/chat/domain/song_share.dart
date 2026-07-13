/// Quy ước share bài tủ v1 (mockup 16): body text thuần với prefix '♪ ' —
/// client cũ / preview inbox degrade thành text thường, KHÔNG cần đổi schema
/// messages. Đợt chat-media sau có thể thay bằng cột type riêng; tin nhắn cũ
/// theo quy ước này vẫn render card như thường.
const songSharePrefix = '♪ ';

String encodeSongShare(String title, String artist) =>
    '$songSharePrefix$title · $artist';

bool isSongShare(String body) => body.startsWith(songSharePrefix);

/// Phần hiển thị sau prefix ('Ước Gì · Mỹ Tâm').
String songShareLabel(String body) => body.substring(songSharePrefix.length);
