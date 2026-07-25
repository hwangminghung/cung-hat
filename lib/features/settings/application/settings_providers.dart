import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(supabaseClientProvider)),
);
final myConsentsProvider = FutureProvider<Map<String, bool>>(
  (ref) => ref.watch(settingsRepositoryProvider).myConsents(),
);

/// Gate tile "Khu quản trị" trong Cai dat. false khi chua tra loi xong —
/// tile hien muon con hon hien nham cho user thuong.
final isAdminProvider = FutureProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).isAdmin(),
);

/// autoDispose: mo lai man "Da chan" phai fetch tuoi — bo chan o phien truoc
/// khong duoc de danh sach cu quay lai tu cache.
final myBlocksProvider = FutureProvider.autoDispose<List<BlockedUser>>(
  (ref) => ref.watch(settingsRepositoryProvider).myBlocks(),
);
