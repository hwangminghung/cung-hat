import '../../photos/data/photo_repository.dart';

/// Mot nguoi da thich minh — du lieu nha hang an toan (KHONG id/ten;
/// anh la ban mosaic server-side, khong bao gio la anh goc).
class LikeTeaser {
  const LikeTeaser({
    this.teaserUrl,
    this.age,
    required this.verified,
    this.sharedGenre,
  });

  final String? teaserUrl;
  final int? age;
  final bool verified;
  final String? sharedGenre;

  factory LikeTeaser.fromJson(Map<String, dynamic> j) => LikeTeaser(
        teaserUrl: j['teaser_url'] as String?,
        age: (j['age'] as num?)?.toInt(),
        verified: j['verified'] == true,
        sharedGenre: j['shared_genre'] as String?,
      );

  /// Doi origin cua [teaserUrl] ve origin storage cua client (fix kong:8000
  /// local — cung ly do voi PhotoRepository.signedUrlsOf).
  LikeTeaser rebase(Uri base) => teaserUrl == null
      ? this
      : LikeTeaser(
          teaserUrl: PhotoRepository.rebaseOrigin(teaserUrl!, base),
          age: age,
          verified: verified,
          sharedGenre: sharedGenre,
        );
}
