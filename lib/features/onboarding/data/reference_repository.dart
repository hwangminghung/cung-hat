import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/music_ref.dart';

class ReferenceRepository {
  ReferenceRepository(this._client);
  final SupabaseClient _client;

  Future<List<Genre>> genres() async {
    final rows = await _client.from('music_genres').select().order('sort');
    return (rows as List)
        .map((e) => Genre.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Artist>> artists() async {
    final rows = await _client.from('music_artists').select().order('sort');
    return (rows as List)
        .map((e) => Artist.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Song>> songs() async {
    final rows = await _client.from('songs').select();
    return (rows as List)
        .map((e) => Song.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
