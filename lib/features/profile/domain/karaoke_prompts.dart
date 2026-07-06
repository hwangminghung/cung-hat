/// Catalog câu hỏi-đáp karaoke (id ổn định — server lưu id + answer).
/// KHÔNG đổi id đã phát hành; thêm câu mới thì thêm id mới.
class KaraokePrompt {
  const KaraokePrompt(this.id, this.question);
  final String id;
  final String question;
}

const karaokePrompts = <KaraokePrompt>[
  KaraokePrompt('p1', 'Bài mình luôn giành mic là…'),
  KaraokePrompt('p2', 'Thể loại mình hát khi buồn…'),
  KaraokePrompt('p3', 'Đi hát, mình là kiểu người…'),
  KaraokePrompt('p4', 'Combo song ca lý tưởng của mình…'),
  KaraokePrompt('p5', 'Điểm 10 của mình khi cầm mic…'),
  KaraokePrompt('p6', 'Bài "ruột" mà ai nghe cũng bất ngờ…'),
];

String? karaokePromptQuestion(String id) {
  for (final p in karaokePrompts) {
    if (p.id == id) return p.question;
  }
  return null;
}

/// Tối đa số thẻ một hồ sơ được chọn (khớp CHECK server).
const maxPrompts = 3;
