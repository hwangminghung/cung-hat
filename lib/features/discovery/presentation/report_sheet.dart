import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discovery_providers.dart';

/// Lý do report là GIÁ TRỊ GỬI SERVER (reports.reason) — giữ tiếng Việt
/// canonical để moderation console đọc thống nhất, không l10n.
const _reasons = ['spam', 'quấy rối', 'ảnh giả', 'khác'];

class ReportSheet extends ConsumerWidget {
  const ReportSheet({super.key, required this.targetId});
  final String targetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final reason in _reasons)
            ListTile(
              title: Text(l10n?.reportTitle(reason) ?? 'Báo cáo: $reason'),
              onTap: () => _report(context, ref, reason),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block),
            title: Text(l10n?.reportBlockUser ?? 'Chặn người này'),
            onTap: () => _block(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _report(
    BuildContext context,
    WidgetRef ref,
    String reason,
  ) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    try {
      await ref.read(discoveryRepositoryProvider).reportUser(targetId, reason);
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n?.reportSent ?? 'Đã gửi báo cáo.')),
      );
    } catch (_) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n?.reportSendError ?? 'Không gửi được báo cáo.')),
      );
    }
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    try {
      await ref.read(discoveryRepositoryProvider).blockUser(targetId);
      // candidatesProvider giờ là family theo genre — invalidate deck chính.
      // (Deck chủ đề vẫn tự lọc block server-side qua get_discovery_candidates
      // dù cache client chưa refresh ngay.)
      ref.invalidate(candidatesProvider(null));
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n?.reportBlocked ?? 'Đã chặn.')),
      );
    } catch (_) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n?.reportBlockError ?? 'Không chặn được.')),
      );
    }
  }
}
