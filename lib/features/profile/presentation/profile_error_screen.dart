import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';

/// Màn khi KHÔNG tải được hồ sơ (mất mạng, server lỗi).
///
/// [AUDIT P1-4] Trước đây lỗi tải bị gộp vào "chưa có hồ sơ" nên user cũ bị
/// ném vào màn tạo hồ sơ lại — vừa sai thông tin vừa dễ khiến họ tưởng mất tài
/// khoản. Ở đây nói đúng bản chất (lỗi tải), cho thử lại, và cho đăng xuất để
/// không kẹt vĩnh viễn nếu tài khoản đó luôn lỗi.
///
/// Router tự rời màn này khi hồ sơ tải lại được (xem [ProfileGate]).
class ProfileErrorScreen extends ConsumerWidget {
  const ProfileErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // Watch để lần tải lại thành công dựng lại cây widget (và router đá về /).
    ref.watch(myProfileProvider);
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: l10n?.profileLoadErrorTitle ?? 'Không tải được hồ sơ',
          subtitle:
              l10n?.profileLoadErrorSub ??
              'Hồ sơ của bạn vẫn còn nguyên. Kiểm tra kết nối rồi thử lại.',
          actionLabel: l10n?.commonRetry ?? 'Thử lại',
          onAction: () => ref.invalidate(myProfileProvider),
          secondaryActionLabel: l10n?.settingsSignOut ?? 'Đăng xuất',
          onSecondaryAction: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ),
    );
  }
}
