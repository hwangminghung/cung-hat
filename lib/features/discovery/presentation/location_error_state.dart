import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/location_service.dart';

/// Trạng thái lỗi vị trí đúng nguyên nhân (P0-1) cho deck Đôi + board Kèo —
/// thay cho empty state "hết người/kèo" gây hiểu lầm khi thật ra app chưa có
/// vị trí của user. 3 nhóm: thiếu quyền → mở cài đặt app; GPS tắt → mở cài
/// đặt định vị; không fix/đẩy lỗi → thử lại.
class LocationErrorState extends StatelessWidget {
  const LocationErrorState({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });

  /// Nguyên nhân khác [LocationCaptureStatus.success].
  final LocationCaptureStatus status;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final retryLabel = l10n?.commonRetry ?? 'Thử lại';
    return switch (status) {
      LocationCaptureStatus.permissionDenied => EmptyState(
        icon: Icons.location_off_rounded,
        title: l10n?.locationPermissionTitle ?? 'Cần quyền vị trí',
        subtitle:
            l10n?.locationPermissionSub ??
            'Cho phép truy cập vị trí để tìm bạn hát và kèo quanh bạn.',
        actionLabel: l10n?.locationOpenSettings ?? 'Mở cài đặt',
        onAction: onOpenSettings,
        secondaryActionLabel: retryLabel,
        onSecondaryAction: onRetry,
      ),
      LocationCaptureStatus.serviceDisabled => EmptyState(
        icon: Icons.location_disabled_rounded,
        title: l10n?.locationServiceOffTitle ?? 'Định vị đang tắt',
        subtitle:
            l10n?.locationServiceOffSub ?? 'Bật định vị (GPS) rồi thử lại.',
        actionLabel: l10n?.locationOpenSettings ?? 'Mở cài đặt',
        onAction: onOpenSettings,
        secondaryActionLabel: retryLabel,
        onSecondaryAction: onRetry,
      ),
      LocationCaptureStatus.noFix => EmptyState(
        icon: Icons.gps_off_rounded,
        title: l10n?.locationNoFixTitle ?? 'Không lấy được vị trí',
        subtitle:
            l10n?.locationNoFixSub ??
            'Không bắt được tín hiệu định vị — thử lại sau giây lát.',
        actionLabel: retryLabel,
        onAction: onRetry,
      ),
      LocationCaptureStatus.pushFailed => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: l10n?.locationPushFailedTitle ?? 'Không gửi được vị trí',
        subtitle:
            l10n?.commonCheckConnection ?? 'Kiểm tra kết nối rồi thử lại.',
        actionLabel: retryLabel,
        onAction: onRetry,
      ),
      // Không render gì cho success — caller chỉ nên dựng widget này khi lỗi.
      LocationCaptureStatus.success => const SizedBox.shrink(),
    };
  }
}
