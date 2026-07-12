import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../onboarding/presentation/consent_step.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentsAsync = ref.watch(myConsentsProvider);
    final consents = consentsAsync.value ?? const <String, bool>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: WaveDivider(),
          ),
          _Section(
            title: 'Quyền riêng tư',
            child: consentsAsync.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      for (final purpose in consentPurposes)
                        SwitchListTile(
                          key: Key('consent_$purpose'),
                          title: Text(consentLabelsVi[purpose] ?? purpose),
                          value: consents[purpose] ?? false,
                          onChanged: (value) =>
                              _handleToggleConsent(context, ref, purpose, value),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Dữ liệu của tôi',
            child: _SettingsTile(
              icon: Icons.download_rounded,
              title: 'Tải dữ liệu của tôi',
              onTap: () => _exportData(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Tài khoản',
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  onTap: () => _signOut(ref),
                ),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Xóa tài khoản',
                  danger: true,
                  onTap: () => _deleteAccount(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Pháp lý',
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Chính sách bảo mật',
                  onTap: () => context.push('/legal/privacy'),
                ),
                _SettingsTile(
                  icon: Icons.description_rounded,
                  title: 'Điều khoản',
                  onTap: () => context.push('/legal/tos'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Lưu 1 consent toggle server-side. Chỉ invalidate provider khi lưu OK;
  /// lỗi (offline/RPC) thì báo SnackBar và giữ nguyên trạng thái cũ — cùng
  /// convention try/catch + mounted như _handleToggleAutoExpand
  /// (doi_deck_screen.dart) — nếu không, RPC lỗi sẽ leak unhandled async
  /// exception và switch tự nhảy lại vị trí cũ mà không có phản hồi gì.
  Future<void> _handleToggleConsent(
    BuildContext context,
    WidgetRef ref,
    String purpose,
    bool value,
  ) async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      if (value) {
        await repo.grantConsent(purpose);
      } else {
        await repo.withdrawConsent(purpose);
      }
      ref.invalidate(myConsentsProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không lưu được cài đặt, thử lại.')));
      }
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref.read(settingsRepositoryProvider).exportMyData();
      await SharePlus.instance.share(ShareParams(text: jsonEncode(data)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tải dữ liệu. Vui lòng thử lại.'),
        ),
      );
    }
  }

  Future<void> _signOut(WidgetRef ref) async {
    // Router redirects to /auth on the resulting auth-state change.
    await ref.read(supabaseClientProvider).auth.signOut();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Hành động này không thể hoàn tác. Tài khoản và dữ liệu của bạn sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(settingsRepositoryProvider).deleteAccount();
    await ref.read(supabaseClientProvider).auth.signOut();
    if (!context.mounted) return;
    context.go('/auth');
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.primaryDark),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primaryDark;
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: danger ? AppColors.errorTint : AppColors.primaryTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: danger ? const TextStyle(color: AppColors.error) : null,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
