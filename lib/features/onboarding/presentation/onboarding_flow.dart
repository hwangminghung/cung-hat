import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/analytics/analytics_service.dart';
import '../application/onboarding_controller.dart';
import '../application/reference_providers.dart';
import '../domain/music_ref.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/wave_divider.dart';
import 'consent_step.dart';
import 'dob_step.dart';
import 'profile_step.dart';
import 'taste_step.dart';

/// Index of the consent step in the flow (DOB=0, consent=1).
const _consentStepIndex = 1;

/// [AUDIT O2] So the loai toi thieu phai chon truoc khi hoan tat.
///
/// Gu nhac la du lieu nuoi thuat toan ghep. Truoc day buoc nay khong rang buoc
/// gi: user bam thang qua, ho so vao he thong voi taste rong va moi goi y ve
/// sau gan nhu ngau nhien. Chan o day re hon nhieu so voi sua sau.
///
/// Chan bang SnackBar + quay lai buoc (giong DOB/consent) thay vi disable nut:
/// nut bi disable khong noi duoc VI SAO, va user khong biet phai lam gi.
const _minGenres = 3;

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

  Future<void> _onFinish() async {
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
    if (_genreSel.length < _minGenres) {
      _moveToStep(_lastStep);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.onbTasteMinGenres ??
                'Chọn ít nhất 3 thể loại để chúng tôi ghép bạn với đúng người.',
          ),
        ),
      );
      return;
    }
    await ref
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
    if (!mounted) return;
    // P1-6: profile đã tạo → chủ động sang bước ảnh optional TRƯỚC khi
    // router kịp đá '/onboarding' về home (lỗi submit thì ở lại, listener
    // dưới build đã lo SnackBar).
    if (!ref.read(onboardingControllerProvider).hasError) {
      context.go('/onboarding/photos');
    }
  }

  Widget _tasteSection<T>({
    required Key key,
    required String label,
    required AsyncValue<List<T>> async,
    required String Function(T) labelOf,
    required String Function(T) idOf,
    required Set<String> selected,
  }) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TasteSectionHeader(
          label,
          countLabel: selected.isEmpty
              ? null
              : '${l10n?.onbTasteSelectedLabel ?? 'Đã chọn'} ${selected.length}',
        ),
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
      0 => KeyedSubtree(
        key: const Key('screen_03_onboarding_dob'),
        child: DobStep(
          dob: _dob,
          onPick: (date) => setState(() => _dob = date),
        ),
      ),
      1 => KeyedSubtree(
        key: const Key('screen_04_onboarding_consent'),
        child: ConsentStep(
          values: _consents,
          onChanged: (key, value) => setState(() => _consents[key] = value),
        ),
      ),
      2 => ProfileStep(
        key: const Key('screen_05_onboarding_profile'),
        nameController: _nameCtrl,
        bioController: _bioCtrl,
        brand: l10n?.appTitle ?? 'Cùng Hát',
      ),
      _ => KeyedSubtree(
        key: const Key('screen_06_onboarding_music_taste'),
        child: Column(
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
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n?.onbTasteMinGenres ??
                  'Chọn ít nhất 3 thể loại để chúng tôi ghép bạn với đúng người.',
              key: const Key('taste_min_hint'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _tasteSection<Genre>(
              key: const Key('taste_genres_section'),
              label: l10n?.onbTasteGenres ?? 'Thể loại',
              async: genres,
              labelOf: (genre) => genre.nameVi,
              idOf: (genre) => genre.id,
              selected: _genreSel,
            ),
            _tasteSection<Artist>(
              key: const Key('taste_artists_section'),
              label: l10n?.onbTasteArtists ?? 'Nghệ sĩ',
              async: artists,
              labelOf: (artist) => artist.name,
              idOf: (artist) => artist.id,
              selected: _artistSel,
            ),
            _tasteSection<Song>(
              key: const Key('taste_songs_section'),
              label: l10n?.onbBaitu ?? 'Bài tủ',
              async: songs,
              labelOf: (song) => song.title,
              idOf: (song) => song.id,
              selected: _songSel,
            ),
          ],
        ),
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

class _TasteSectionHeader extends StatelessWidget {
  const _TasteSectionHeader(this.label, {this.countLabel});

  final String label;

  /// null khi chua chon gi — tranh hien "Da chon 0" nhu mot loi.
  final String? countLabel;

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
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (countLabel != null)
            Text(
              countLabel!,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}
