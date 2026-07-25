import '../../../l10n/app_localizations.dart';
import 'profile.dart';

/// Counts of taste selections (thể loại, nghệ sĩ, bài tủ) for the current
/// user, as returned by the `get_my_taste` RPC.
class TasteCounts {
  const TasteCounts(this.genres, this.artists, this.baitu);
  final int genres;
  final int artists;
  final int baitu;
}

class CompletionResult {
  const CompletionResult(this.percent, this.nextSteps);
  final int percent;
  final List<String> nextSteps; // tối đa 2 gợi ý, ưu tiên điểm to nhất
}

/// Trọng số cố định (tổng 100): ảnh≥1=20, ảnh≥3=+10, bio=15,
/// genres≥3=15, artists≥1=10, bài tủ≥3=15, prompts≥2=15.
/// [L10N] Gợi ý là chuỗi UI → nhận [l10n] từ call-site (null = fallback VI,
/// giữ test cũ gọi không l10n nguyên expectation).
CompletionResult profileCompletion(
  Profile p,
  TasteCounts taste, {
  AppLocalizations? l10n,
}) {
  var percent = 0;
  // (weight, suggestion, insertion order) — declaration order below is the
  // intended tiebreak when weights are equal. List.sort is not stable in
  // Dart, so the index is carried through the sort explicitly.
  final missing = <(int, String, int)>[];
  var order = 0;

  void item(bool done, int weight, String suggestion) {
    if (done) {
      percent += weight;
    } else {
      missing.add((weight, suggestion, order++));
    }
  }

  final photos = p.photoPaths.length;
  item(
    photos >= 1,
    20,
    l10n?.completionAddPhoto ?? 'Thêm ảnh đầu tiên → được thấy nhiều hơn hẳn',
  );
  item(
    photos >= 3,
    10,
    l10n?.completionThreePhotos ?? 'Đủ 3 ảnh → x2 lượt được thấy',
  );
  item(
    p.bio?.trim().isNotEmpty == true,
    15,
    l10n?.completionWriteBio ?? 'Viết giới thiệu → +25% ghép đôi',
  );
  item(
    taste.genres >= 3,
    15,
    l10n?.completionPickGenres ?? 'Chọn đủ 3 thể loại → gợi ý chuẩn gu hơn',
  );
  item(
    taste.artists >= 1,
    10,
    l10n?.completionAddArtist ?? 'Thêm nghệ sĩ yêu thích',
  );
  item(
    taste.baitu >= 3,
    15,
    l10n?.completionAddBaitu ?? 'Thêm 3 bài tủ → dễ vào kèo hơn',
  );
  item(
    p.prompts.length >= 2,
    15,
    l10n?.completionAnswerPrompts ?? 'Trả lời 2 thẻ hỏi-đáp → có chuyện mà bắt',
  );

  missing.sort((a, b) {
    final byWeight = b.$1.compareTo(a.$1);
    return byWeight != 0 ? byWeight : a.$3.compareTo(b.$3);
  });
  return CompletionResult(percent, [for (final m in missing.take(2)) m.$2]);
}
