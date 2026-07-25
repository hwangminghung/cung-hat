import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/application/inbox_providers.dart';
import '../application/discovery_providers.dart';

/// Lý do report là GIÁ TRỊ GỬI SERVER (reports.reason) — giữ tiếng Việt
/// canonical để moderation console đọc thống nhất, không l10n.
const _reasons = ['spam', 'quấy rối', 'ảnh giả', 'khác'];

class ReportSheet extends ConsumerWidget {
  const ReportSheet({super.key, required this.targetId, this.onBlocked});
  final String targetId;

  /// [AUDIT SAFETY] Man hinh 1-1 truyen callback nay de tu roi khoi thread sau
  /// khi chan — user khong duoc ngoi lai trong cuoc tro chuyen cua nguoi vua
  /// bi chan. Man nhom (keo / ke hoach) de null vi con nhung thanh vien khac.
  final VoidCallback? onBlocked;

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
        SnackBar(
          content: Text(l10n?.reportSendError ?? 'Không gửi được báo cáo.'),
        ),
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
      // [AUDIT SAFETY] Chan xong ma inbox con cache cu thi thread cua nguoi
      // vua chan van nam nguyen trong danh sach tin nhan — invalidate de
      // get_my_matches chay lai.
      ref.invalidate(inboxProvider);
      nav.pop();
      // [AUDIT SAFETY] Dong sheet thoi la chua du: neu sheet mo tu thread 1-1
      // thi phai roi luon thread do (man goi truyen onBlocked).
      onBlocked?.call();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.safetyBlockedRemoved ??
                'Đã chặn. Hai người sẽ không còn thấy nhau.',
          ),
        ),
      );
    } catch (_) {
      nav.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n?.reportBlockError ?? 'Không chặn được.')),
      );
    }
  }
}
