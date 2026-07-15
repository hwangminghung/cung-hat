import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../onboarding/presentation/consent_step.dart';
import '../application/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// [AUDIT M1] Chặn double-tap trong lúc RPC xoá tài khoản đang bay.
  bool _deleting = false;

  AppLocalizations? get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  @override
  Widget build(BuildContext context) {
    final consentsAsync = ref.watch(myConsentsProvider);
    final consents = consentsAsync.value ?? const <String, bool>{};

    return Scaffold(
      appBar: AppBar(title: Text(_l10n?.settingsTitle ?? 'Cài đặt')),
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
            title: _l10n?.settingsSectionPrivacy ?? 'Quyền riêng tư',
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
                              _handleToggleConsent(purpose, value),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: _l10n?.settingsLanguage ?? 'Ngôn ngữ',
            child: Column(
              children: [
                _LanguageTile(
                  key: const Key('lang_system'),
                  label: _l10n?.settingsLangSystem ?? 'Theo hệ thống',
                  selected: ref.watch(localeControllerProvider) == null,
                  onTap: () =>
                      ref.read(localeControllerProvider.notifier).set(null),
                ),
                _LanguageTile(
                  key: const Key('lang_vi'),
                  // Tên ngôn ngữ hiển thị bằng chính ngôn ngữ đó — không l10n.
                  label: 'Tiếng Việt',
                  selected:
                      ref.watch(localeControllerProvider) == const Locale('vi'),
                  onTap: () => ref
                      .read(localeControllerProvider.notifier)
                      .set(const Locale('vi')),
                ),
                _LanguageTile(
                  key: const Key('lang_en'),
                  label: 'English',
                  selected:
                      ref.watch(localeControllerProvider) == const Locale('en'),
                  onTap: () => ref
                      .read(localeControllerProvider.notifier)
                      .set(const Locale('en')),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: _l10n?.settingsSectionData ?? 'Dữ liệu của tôi',
            child: _SettingsTile(
              icon: Icons.download_rounded,
              title: _l10n?.exportData ?? 'Tải dữ liệu của tôi',
              onTap: _exportData,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: _l10n?.settingsSectionAccount ?? 'Tài khoản',
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: _l10n?.settingsSignOut ?? 'Đăng xuất',
                  onTap: _signOut,
                ),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: _l10n?.deleteAccount ?? 'Xóa tài khoản',
                  danger: true,
                  onTap: _deleting ? null : _deleteAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: _l10n?.settingsSectionLegal ?? 'Pháp lý',
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  title: _l10n?.privacyTitle ?? 'Chính sách bảo mật',
                  onTap: () => context.push('/legal/privacy'),
                ),
                _SettingsTile(
                  icon: Icons.description_rounded,
                  title: _l10n?.settingsTerms ?? 'Điều khoản',
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
  Future<void> _handleToggleConsent(String purpose, bool value) async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      if (value) {
        await repo.grantConsent(purpose);
      } else {
        await repo.withdrawConsent(purpose);
      }
      ref.invalidate(myConsentsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                _l10n?.commonSaveError ?? 'Không lưu được cài đặt, thử lại.')));
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await ref.read(settingsRepositoryProvider).exportMyData();
      await SharePlus.instance.share(ShareParams(text: jsonEncode(data)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n?.settingsExportError ?? 'Không thể tải dữ liệu. Vui lòng thử lại.',
          ),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    // Router redirects to /auth on the resulting auth-state change.
    await ref.read(supabaseClientProvider).auth.signOut();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${_l10n?.deleteAccount ?? 'Xóa tài khoản'}?'),
        content: Text(
          _l10n?.deleteConfirm ??
              'Hành động này không thể hoàn tác. Tài khoản và dữ liệu của bạn sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l10n?.cancel ?? 'Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_l10n?.commonDelete ?? 'Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _deleting) return;
    setState(() => _deleting = true);
    try {
      await ref.read(settingsRepositoryProvider).deleteAccount();
      await ref.read(supabaseClientProvider).auth.signOut();
      if (mounted) context.go('/auth');
    } catch (_) {
      // [AUDIT M1] offline/RPC lỗi: trước đây exception thoát không bắt —
      // user không biết đã xoá hay chưa.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n?.settingsDeleteError ?? 'Không xoá được tài khoản, thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
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

  /// null = tile disabled (đang có thao tác in-flight).
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primaryDark;
    // Mirror _ProfileTile (home_shell.dart): ListTile vẽ ink trên Material
    // gần nhất — thiếu lớp Material transparency thì assertion "ink splashes
    // may be invisible" nổ trên mọi lần pump màn này trong widget test.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
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
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Mirror _SettingsTile: Material transparency de ink cua ListTile ve dung.
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppColors.primaryDark)
            : null,
        onTap: onTap,
      ),
    );
  }
}
