import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Overridden in main() after Supabase.initialize(); never read before that.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  throw UnimplementedError('supabaseClientProvider must be overridden in main()');
});
