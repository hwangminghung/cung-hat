import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/supabase_providers.dart';
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
        children: [
          const _SectionHeader('Quyền riêng tư'),
          if (consentsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (final p in consentPurposes)
              SwitchListTile(
                key: Key('consent_$p'),
                title: Text(consentLabelsVi[p] ?? p),
                value: consents[p] ?? false,
                onChanged: (v) async {
                  final repo = ref.read(settingsRepositoryProvider);
                  if (v) {
                    await repo.grantConsent(p);
                  } else {
                    await repo.withdrawConsent(p);
                  }
                  ref.invalidate(myConsentsProvider);
                },
              ),
          const Divider(),
          const _SectionHeader('Dữ liệu của tôi'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Tải dữ liệu của tôi'),
            onTap: () => _exportData(context, ref),
          ),
          const Divider(),
          const _SectionHeader('Tài khoản'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              'Xoá tài khoản',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () => _deleteAccount(context, ref),
          ),
          const Divider(),
          const _SectionHeader('Pháp lý'),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Chính sách bảo mật'),
            onTap: () => context.push('/legal/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Điều khoản'),
            onTap: () => context.push('/legal/tos'),
          ),
        ],
      ),
    );
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

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá tài khoản?'),
        content: const Text(
          'Hành động này không thể hoàn tác. Tài khoản và dữ liệu của bạn sẽ bị xoá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
