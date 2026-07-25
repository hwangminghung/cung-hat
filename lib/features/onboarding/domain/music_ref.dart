import 'package:freezed_annotation/freezed_annotation.dart';
part 'music_ref.freezed.dart';
part 'music_ref.g.dart';

@freezed
abstract class Genre with _$Genre {
  const factory Genre({
    required String id,
    @JsonKey(name: 'name_vi') required String nameVi,
    @JsonKey(name: 'name_en') required String nameEn,
  }) = _Genre;
  factory Genre.fromJson(Map<String, dynamic> j) => _$GenreFromJson(j);
}

@freezed
abstract class Artist with _$Artist {
  const factory Artist({required String id, required String name}) = _Artist;
  factory Artist.fromJson(Map<String, dynamic> j) => _$ArtistFromJson(j);
}

@freezed
abstract class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
  }) = _Song;
  factory Song.fromJson(Map<String, dynamic> j) => _$SongFromJson(j);
}
