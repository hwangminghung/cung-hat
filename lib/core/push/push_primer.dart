import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/gradient_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'push_registrar.dart';

/// Pref lựa chọn primer thông báo: 'on' (đã bật) / 'later' (để sau);
/// vắng = chưa từng hỏi.
const kPushPrimerPrefKey = 'push_primer_choice';

/// [UI-AUDIT đợt 4 — món nợ P1-3] Lựa chọn của user ở màn giải thích
/// TRƯỚC khi bật hộp thoại quyền hệ thống. Hộp thoại OS chỉ hỏi được MỘT
/// lần — đốt nó ngay lúc mở app (khi user chưa hiểu vì sao cần) là mất
/// vĩnh viễn kênh push.
class PushPrimerChoice extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(kPushPrimerPrefKey);
    } catch (e) {
      debugPrint('push primer pref load skipped: $e');
      return null;
    }
  }

  Future<void> set(String choice) async {
    state = AsyncData(choice);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPushPrimerPrefKey, choice);
    } catch (e) {
      // State vẫn đổi cho phiên này; chỉ mất persist qua restart.
      debugPrint('push primer pref save skipped: $e');
    }
  }
}

final pushPrimerChoiceProvider =
    AsyncNotifierProvider<PushPrimerChoice, String?>(PushPrimerChoice.new);

/// Sheet giải thích 2 lợi ích push + 2 nút. "Bật thông báo" mới là thứ kích
/// hoạt hộp thoại quyền OS (qua registerForSignedInUser) — đúng ngữ cảnh.
class PushPrimerSheet extends ConsumerWidget {
  const PushPrimerSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PushPrimerSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    Widget benefit(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.tertiaryTint,
              border: Border.all(color: AppColors.ink, width: 2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              boxShadow: <BoxShadow>[AppShadows.hard],
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.pushPrimerTitle ?? 'Đừng lỡ kèo và match mới',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            benefit(
              Icons.mic_external_on_outlined,
              l10n?.pushPrimerBenefitKeo ??
                  'Báo khi kèo của bạn sắp diễn ra hoặc có người xin vào.',
            ),
            benefit(
              Icons.favorite_rounded,
              l10n?.pushPrimerBenefitMatch ??
                  'Báo ngay khi có người ghép đôi với bạn.',
            ),
            const SizedBox(height: AppSpacing.lg),
            GradientButton(
              key: const Key('push_primer_accept'),
              onPressed: () async {
                final nav = Navigator.of(context);
                await ref.read(pushPrimerChoiceProvider.notifier).set('on');
                // Hộp thoại quyền OS bật tại đây — đúng lúc user vừa hiểu
                // vì sao. Các phiên sau tự đăng ký im lặng (pref 'on').
                await ref.read(pushRegistrarProvider).registerForSignedInUser();
                if (nav.mounted) nav.pop();
              },
              child: Text(l10n?.pushPrimerAccept ?? 'Bật thông báo'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                key: const Key('push_primer_later'),
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await ref
                      .read(pushPrimerChoiceProvider.notifier)
                      .set('later');
                  if (nav.mounted) nav.pop();
                },
                child: Text(l10n?.pushPrimerLater ?? 'Để sau'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
