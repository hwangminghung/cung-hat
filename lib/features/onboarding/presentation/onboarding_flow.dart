import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/analytics/analytics_service.dart';
import '../application/onboarding_controller.dart';
import '../application/reference_providers.dart';
import '../domain/music_ref.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/wave_divider.dart';
import 'consent_step.dart';
import 'dob_step.dart';
import 'taste_step.dart';

/// Index of the consent step in the flow (DOB=0, consent=1).
const _consentStepIndex = 1;

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  DateTime? _dob;
  late final Map<String, bool> _consents = {
    for (final p in consentPurposes) p: false,
  };
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _genreSel = {};
  final Set<String> _artistSel = {};
  final Set<String> _songSel = {};
  int _step = 0;

  static const _lastStep = 3;

  @override
  void initState() {
    super.initState();
    // P0-3: mount = vào bước 1 của funnel.
    unawaited(ref.read(analyticsProvider).logOnboardingStep(1));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _moveToStep(int nextStep, {bool grantRequired = false}) {
    // P0-3: funnel chỉ đếm CHIỀU TIẾN (quay lại không phải tiến độ mới).
    if (nextStep > _step) {
      unawaited(ref.read(analyticsProvider).logOnboardingStep(nextStep + 1));
    }
    setState(() {
      if (grantRequired) grantRequiredConsents(_consents);
      _step = nextStep;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _onFinish() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (_dob == null || !isAdult(_dob!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.onbUnder18 ?? 'Bạn phải đủ 18 tuổi.')),
      );
      return;
    }
    final missing = missingRequiredConsents(_consents);
    if (missing.isNotEmpty) {
      _moveToStep(_consentStepIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.onbConsentRequired ??
                'Vui lòng đồng ý các quyền bắt buộc để tiếp tục.',
          ),
        ),
      );
      return;
    }
    ref
        .read(onboardingControllerProvider.notifier)
        .submit(
          displayName: _nameCtrl.text,
          fullName: _nameCtrl.text,
          dob: _dob!,
          bio: _bioCtrl.text,
          consents: _consents,
          genreIds: _genreSel.toList(),
          artistIds: _artistSel.toList(),
          songIds: _songSel.toList(),
          language: Localizations.localeOf(context).languageCode,
        );
  }

  Widget _tasteSection<T>({
    required String label,
    required AsyncValue<List<T>> async,
    required String Function(T) labelOf,
    required String Function(T) idOf,
    required Set<String> selected,
  }) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TasteSectionHeader(label),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) {
            debugPrint('onboarding: reference load error: $err');
            return EmptyState(
              icon: Icons.wifi_off,
              title: l10n?.onbLoadError ?? 'Không tải được dữ liệu.',
              subtitle: l10n?.onbLoadRetrySub ?? 'Thử lại sau ít phút.',
            );
          },
          data: (items) => TasteChips<T>(
            items: items,
            labelOf: labelOf,
            idOf: idOf,
            selected: selected,
            onToggle: (id) => setState(
              () => selected.contains(id)
                  ? selected.remove(id)
                  : selected.add(id),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _currentStep({
    required AppLocalizations? l10n,
    required AsyncValue<List<Genre>> genres,
    required AsyncValue<List<Artist>> artists,
    required AsyncValue<List<Song>> songs,
  }) {
    return switch (_step) {
      0 => DobStep(dob: _dob, onPick: (date) => setState(() => _dob = date)),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.onbConsentTitle ?? 'Quyền riêng tư',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ConsentStep(
            values: _consents,
            onChanged: (key, value) => setState(() => _consents[key] = value),
          ),
        ],
      ),
      2 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.onbStepProfile ?? 'Thiết lập hồ sơ',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfilePreview(
            key: const Key('onb_profile_preview'),
            controller: _nameCtrl,
            brand: l10n?.appTitle ?? 'Cùng Hát',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n?.onbProfileQuestion ?? 'Bạn muốn mọi người gọi mình là gì?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('onb_name'),
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: l10n?.onbNameLabel ?? 'Tên hiển thị',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('onb_bio'),
            controller: _bioCtrl,
            minLines: 3,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n?.onbBioLabel ?? 'Giới thiệu',
            ),
          ),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.onbStepTaste ?? 'Gu nhạc',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n?.onbTasteSubtitle ?? 'Chọn vài thứ bạn hay nghe',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          _tasteSection<Genre>(
            label: l10n?.onbTasteGenres ?? 'Thể loại',
            async: genres,
            labelOf: (genre) => genre.nameVi,
            idOf: (genre) => genre.id,
            selected: _genreSel,
          ),
          _tasteSection<Artist>(
            label: l10n?.onbTasteArtists ?? 'Nghệ sĩ',
            async: artists,
            labelOf: (artist) => artist.name,
            idOf: (artist) => artist.id,
            selected: _artistSel,
          ),
          _tasteSection<Song>(
            label: l10n?.onbBaitu ?? 'Bài tủ',
            async: songs,
            labelOf: (song) => song.title,
            idOf: (song) => song.id,
            selected: _songSel,
          ),
        ],
      ),
    };
  }

  Widget _bottomControls({
    required AppLocalizations? l10n,
    required bool loading,
  }) {
    final isLast = _step == _lastStep;
    final isConsent = _step == _consentStepIndex;
    final primaryControl = GradientButton(
      key: isLast ? const Key('onb_finish') : const Key('onb_continue'),
      onPressed: loading
          ? null
          : isLast
          ? _onFinish
          : () => _moveToStep(_step + 1, grantRequired: isConsent),
      child: loading && isLast
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: AppColors.onPrimary,
                strokeWidth: 2,
              ),
            )
          : Text(
              isLast
                  ? l10n?.onbFinish ?? 'Hoàn tất'
                  : isConsent
                  ? l10n?.onbConsentContinue ?? 'Đồng ý & tiếp tục'
                  : l10n?.onbContinue ?? 'Tiếp tục',
            ),
    );
    final backControl = _step > 0
        ? TextButton.icon(
            key: const Key('onb_back'),
            onPressed: () => _moveToStep(_step - 1),
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n?.onbBack ?? 'Quay lại'),
          )
        : null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack =
                  backControl != null &&
                  (constraints.maxWidth < 320 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3);
              if (shouldStack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    backControl,
                    const SizedBox(height: AppSpacing.xs),
                    primaryControl,
                  ],
                );
              }
              return Row(
                children: [
                  if (backControl != null) ...[
                    backControl,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(child: primaryControl),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final controllerState = ref.watch(onboardingControllerProvider);
    final loading = controllerState.isLoading;

    ref.listen(onboardingControllerProvider, (prev, next) {
      if (next is AsyncError) {
        debugPrint('onboarding: submit error: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.onbSubmitError ?? 'Có lỗi xảy ra, vui lòng thử lại.',
            ),
          ),
        );
      }
    });

    final genres = ref.watch(genresProvider);
    final artists = ref.watch(artistsProvider);
    final songs = ref.watch(songsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n?.onbSetupTitle ?? 'Thiết lập hồ sơ')),
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingProgress(
              currentStep: _step,
              label: l10n?.onbProgress(_step + 1) ?? 'Bước ${_step + 1}/4',
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('onboarding_scroll'),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: _currentStep(
                  l10n: l10n,
                  genres: genres,
                  artists: artists,
                  songs: songs,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomControls(l10n: l10n, loading: loading),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({required this.currentStep, required this.label});

  final int currentStep;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('onb_progress_semantics'),
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  for (var index = 0; index < 4; index++) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: WaveDivider(
                        key: Key('onb_progress_segment_$index'),
                        height: AppSpacing.xxl,
                        strokeWidth: 2,
                        color: index < currentStep
                            ? AppColors.ink
                            : index == currentStep
                            ? AppColors.primary
                            : AppColors.secondaryTint,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                key: const Key('onb_progress_label'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({
    super.key,
    required this.controller,
    required this.brand,
  });

  final TextEditingController controller;
  final String brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        boxShadow: const [AppShadows.hard],
      ),
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final trimmed = value.text.trim();
                final monogram = trimmed.isEmpty
                    ? 'M'
                    : String.fromCharCode(trimmed.runes.first).toUpperCase();
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      monogram,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.ink,
                        fontSize: 82,
                        height: 1,
                      ),
                    ),
                    const Positioned(
                      left: AppSpacing.xl,
                      top: AppSpacing.xs,
                      child: Icon(
                        Icons.auto_awesome,
                        color: AppColors.secondaryDark,
                        size: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: WaveDivider(
                  height: AppSpacing.xxl,
                  color: AppColors.ink,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              const Icon(Icons.language, color: AppColors.ink, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Text(
                brand,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.ink),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TasteSectionHeader extends StatelessWidget {
  const _TasteSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
