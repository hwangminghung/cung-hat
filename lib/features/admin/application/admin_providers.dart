import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/moderation_repository.dart';

final moderationRepositoryProvider = Provider(
  (ref) => ModerationRepository(ref.watch(supabaseClientProvider)),
);

/// [SWEEP 2026-07-26] autoDispose: truoc day la FutureProvider thuong nen mo
/// lai man Kiem duyet replay danh sach da cache — do tren may: bao cao moi
/// KHONG hien, kiem duyet vien phai kill app moi thay. Hang doi bao cao la
/// du lieu thay doi lien tuc, khong duoc cache qua lan xem.
final openReportsProvider = FutureProvider.autoDispose<List<Report>>(
  (ref) => ref.watch(moderationRepositoryProvider).listReports(),
);
