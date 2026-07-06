/// Chủ đề Khám Phá theo gu nhạc. genreId PHẢI khớp seed public.music_genres
/// (0003_music_ref.sql) — server filter theo đúng id này.
class MusicTheme {
  const MusicTheme(this.genreId, this.title, this.subtitle, this.emoji);
  final String genreId;
  final String title;
  final String subtitle;
  final String emoji;
}

const musicThemes = <MusicTheme>[
  MusicTheme('ballad', 'Đêm Ballad', 'Chậm rãi, tình cảm', '🌙'),
  MusicTheme('rap_vn', 'Hội Rap', 'Bắn rap không cần beat', '🔥'),
  MusicTheme('bolero', 'Bolero chill', 'Trữ tình sâu lắng', '🍵'),
  MusicTheme('kpop', 'Đêm K-Pop', 'Quẩy hết mình', '✨'),
  MusicTheme('vpop', 'V-Pop party', 'Hit Việt mọi thế hệ', '🎉'),
];

MusicTheme? musicThemeById(String genreId) {
  for (final t in musicThemes) {
    if (t.genreId == genreId) return t;
  }
  return null;
}
