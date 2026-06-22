// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Genre _$GenreFromJson(Map<String, dynamic> json) => _Genre(
  id: json['id'] as String,
  nameVi: json['name_vi'] as String,
  nameEn: json['name_en'] as String,
);

Map<String, dynamic> _$GenreToJson(_Genre instance) => <String, dynamic>{
  'id': instance.id,
  'name_vi': instance.nameVi,
  'name_en': instance.nameEn,
};

_Artist _$ArtistFromJson(Map<String, dynamic> json) =>
    _Artist(id: json['id'] as String, name: json['name'] as String);

Map<String, dynamic> _$ArtistToJson(_Artist instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};

_Song _$SongFromJson(Map<String, dynamic> json) => _Song(
  id: json['id'] as String,
  title: json['title'] as String,
  artist: json['artist'] as String,
);

Map<String, dynamic> _$SongToJson(_Song instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'artist': instance.artist,
};
