import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../billing/application/billing_providers.dart';
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
  /// Hai đầu slider tuổi. Chạm biên = KHÔNG lọc phía đó (18 = không sàn,
  /// 60 = không trần) — map về null trước khi gửi server.
  static const _ageFloor = 18;
  static const _ageCeil = 60;

  int _km = 50;
  bool _autoExpand = false;
  bool _seeded = false;
  bool _saving = false;
  RangeValues _age = const RangeValues(18, 60);
  bool _activeOnly = false;

  void _seedFrom(AsyncValue<({bool autoExpand, int radiusKm})> prefs) {
    if (_seeded || prefs.isLoading) return;
    _seeded = true;
    final value = prefs.value;
    if (value != null) {
      _km = value.radiusKm;
      _autoExpand = value.autoExpand;
    }
    // Bộ lọc nâng cao là trạng thái phiên — seed từ provider, không từ server.
    final premium = ref.read(premiumFiltersProvider);
    _age = RangeValues(
      (premium.minAge ?? _ageFloor).toDouble(),
      (premium.maxAge ?? _ageCeil).toDouble(),
    );
    _activeOnly = premium.activeOnly;
  }

  Future<void> _save() async {
    if (_saving || !_seeded) return;
    setState(() => _saving = true);
    try {
      await ref.read(discoveryRepositoryProvider).setDiscoveryRadius(_km);
      await ref.read(discoveryRepositoryProvider).setAutoExpand(_autoExpand);
      // Bộ lọc nâng cao: chạm biên slider = không lọc phía đó. Chỉ ghi khi
      // user CÓ entitlement — người free không nhìn thấy control, và server
      // vẫn tự chặn nếu state lọt qua bằng đường khác.
      if (ref.read(hasEntitlementProvider('premium_filters'))) {
        ref.read(premiumFiltersProvider.notifier).state = (
          minAge: _age.start.round() <= _ageFloor ? null : _age.start.round(),
          maxAge: _age.end.round() >= _ageCeil ? null : _age.end.round(),
          activeOnly: _activeOnly,
        );
      }
      ref.invalidate(discoveryPrefsProvider);
      // Bỏ override phiên: lưu bộ lọc mới thay thế one-shot "mở rộng 100km"
      // trước đó — nếu không, candidatesProvider vẫn ưu tiên override cũ
      // thay vì bán kính vừa lưu.
      ref.read(deckRadiusProvider.notifier).state = null;
      ref.invalidate(candidatesProvider(null));
      if (mounted) {
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.filterApplied ?? 'Đã áp dụng bộ lọc.')),
        );
      }
    } catch (_) {
      if (mounted) {
        final l10n = Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.filterSaveError ?? 'Không lưu được, thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Section bộ lọc nâng cao (premium_filters 79k, Pro là superset).
  /// Free: ô khoá dẫn sang Cửa hàng — server vẫn là hàng rào thật
  /// (entitlement_required) nếu ai đó gọi RPC thẳng.
  Widget _premiumSection(AppLocalizations? l10n) {
    final unlocked = ref.watch(hasEntitlementProvider('premium_filters'));
    if (!unlocked) {
      return ListTile(
        key: const Key('filter_premium_locked'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.lock_rounded, color: AppColors.tertiary),
        title: Text(l10n?.filterPremiumLocked ?? 'Mở khoá Bộ lọc nâng cao'),
        subtitle: Text(
          l10n?.filterPremiumLockedSub ??
              'Lọc theo độ tuổi và người đang hoạt động — có trong Cửa hàng.',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push('/store'),
      );
    }
    final noCap = _age.end.round() >= _ageCeil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.filterPremiumSection ?? 'Bộ lọc nâng cao',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${l10n?.filterAgeRange ?? 'Khoảng tuổi'}: '
          '${_age.start.round()}–${_age.end.round()}${noCap ? '+' : ''}',
          key: const Key('filter_age_value'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        RangeSlider(
          key: const Key('filter_age_slider'),
          min: _ageFloor.toDouble(),
          max: _ageCeil.toDouble(),
          divisions: _ageCeil - _ageFloor,
          labels: RangeLabels(
            '${_age.start.round()}',
            '${_age.end.round()}${noCap ? '+' : ''}',
          ),
          values: _age,
          onChanged: !_seeded ? null : (v) => setState(() => _age = v),
        ),
        SwitchListTile(
          key: const Key('filter_active_only_switch'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n?.filterActiveOnly ?? 'Chỉ người hoạt động hôm nay'),
          value: _activeOnly,
          onChanged: !_seeded ? null : (v) => setState(() => _activeOnly = v),
        ),
      ],
    );
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
              Text(
                l10n?.filterTitle ?? 'Bộ lọc',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n?.filterRadius ?? 'Bán kính tìm quanh',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$_km km',
                key: const Key('filter_radius_value'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
                title: Text(
                  l10n?.deckAutoExpandTitle ?? 'Tự mở rộng khi hết người',
                ),
                subtitle: Text(
                  l10n?.filterAutoExpandSub ??
                      'Tự tìm quanh 100 km khi hết gợi ý',
                ),
                value: _autoExpand,
                onChanged: !_seeded
                    ? null
                    : (v) => setState(() => _autoExpand = v),
              ),
              const Divider(height: AppSpacing.xl),
              _premiumSection(l10n),
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
