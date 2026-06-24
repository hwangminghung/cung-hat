import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_providers.dart';
import '../data/keo_repository.dart';
import '../domain/keo.dart';
import '../domain/keo_member.dart';

final keoRepositoryProvider =
    Provider((ref) => KeoRepository(ref.watch(supabaseClientProvider)));

final openKeosProvider = FutureProvider<List<Keo>>(
    (ref) => ref.watch(keoRepositoryProvider).listOpenKeos());

final keoRosterProvider = FutureProvider.family<List<KeoMember>, String>(
    (ref, keoId) => ref.watch(keoRepositoryProvider).roster(keoId));
