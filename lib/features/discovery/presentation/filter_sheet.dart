import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../application/discovery_providers.dart';

/// Bộ lọc bán kính kiểu Tinder — slider 5-100km lưu server + toggle tự mở
/// rộng khi hết deck. Seed pattern như [PromptEditorSheet]: đọc giá trị hiện
/// tại từ [discoveryPrefsProvider] đúng MỘT lần, ở lần build đầu tiên sau khi
/// provider resolve; trong lúc đó slider/switch vẫn hiện (mặc định 50/false)
/// nhưng nút Áp dụng bị khoá để tránh ghi đè server bằng giá trị mặc định
/// chưa kịp seed.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  int _km = 50;
  bool _autoExpand = false;
  bool _seeded = false;
  bool _saving = false;

  void _seedFrom(AsyncValue<({bool autoExpand, int radiusKm})> prefs) {
    if (_seeded || prefs.isLoading) return;
    _seeded = true;
    final value = prefs.value;
    if (value != null) {
      _km = value.radiusKm;
      _autoExpand = value.autoExpand;
    }
  }

  Future<void> _save() async {
    if (_saving || !_seeded) return;
    setState(() => _saving = true);
    try {
      await ref.read(discoveryRepositoryProvider).setDiscoveryRadius(_km);
      await ref.read(discoveryRepositoryProvider).setAutoExpand(_autoExpand);
      ref.invalidate(discoveryPrefsProvider);
      // Bỏ override phiên: lưu bộ lọc mới thay thế one-shot "mở rộng 100km"
      // trước đó — nếu không, candidatesProvider vẫn ưu tiên override cũ
      // thay vì bán kính vừa lưu.
      ref.read(deckRadiusProvider.notifier).state = null;
      ref.invalidate(candidatesProvider(null));
      if (mounted) {
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.filterApplied ?? 'Đã áp dụng bộ lọc.')),
        );
      }
    } catch (_) {
      if (mounted) {
        final l10n =
            Localizations.of<AppLocalizations>(context, AppLocalizations);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.filterSaveError ?? 'Không lưu được, thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    _seedFrom(ref.watch(discoveryPrefsProvider));
    return SafeArea(
      child: SingleChildScrollView(
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n?.filterTitle ?? 'Bộ lọc',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n?.filterRadius ?? 'Bán kính tìm quanh',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$_km km',
                key: const Key('filter_radius_value'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              Slider(
                key: const Key('filter_radius_slider'),
                min: 5,
                max: 100,
                divisions: 19,
                value: _km.toDouble(),
                label: '$_km km',
                onChanged: !_seeded
                    ? null
                    : (v) => setState(() => _km = v.round()),
              ),
              const Divider(height: AppSpacing.xl),
              SwitchListTile(
                key: const Key('filter_auto_expand_switch'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.deckAutoExpandTitle ?? 'Tự mở rộng khi hết người'),
                subtitle:
                    Text(l10n?.filterAutoExpandSub ?? 'Tự tìm quanh 100 km khi hết gợi ý'),
                value: _autoExpand,
                onChanged: !_seeded
                    ? null
                    : (v) => setState(() => _autoExpand = v),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  key: const Key('filter_save_btn'),
                  onPressed: (_saving || !_seeded) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Text(l10n?.filterApply ?? 'Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
