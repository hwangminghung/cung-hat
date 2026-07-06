import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../application/reference_providers.dart';
import '../domain/music_ref.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import 'consent_step.dart';
import 'dob_step.dart';
import 'taste_step.dart';

/// Index of the consent step in the [Stepper] (DOB=0, consent=1).
const _consentStepIndex = 1;

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow>
    with RestorationMixin {
  final _dob = RestorableDateTimeN(null);
  late final Map<String, RestorableBool> _consents = {
    for (final p in consentPurposes) p: RestorableBool(false),
  };
  final _nameCtrl = RestorableTextEditingController();
  final _bioCtrl = RestorableTextEditingController();
  final _genreSel = RestorableString('');
  final _artistSel = RestorableString('');
  final _songSel = RestorableString('');
  final _step = RestorableInt(0);

  static const _lastStep = 3;

  @override
  String? get restorationId => 'onboarding_flow';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_dob, 'dob');
    registerForRestoration(_step, 'step');
    registerForRestoration(_nameCtrl, 'name');
    registerForRestoration(_bioCtrl, 'bio');
    registerForRestoration(_genreSel, 'genres');
    registerForRestoration(_artistSel, 'artists');
    registerForRestoration(_songSel, 'songs');
    for (final entry in _consents.entries) {
      registerForRestoration(entry.value, 'consent_${entry.key}');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _dob.dispose();
    _step.dispose();
    _genreSel.dispose();
    _artistSel.dispose();
    _songSel.dispose();
    for (final consent in _consents.values) {
      consent.dispose();
    }
    super.dispose();
  }

  Map<String, bool> get _consentValues => {
    for (final entry in _consents.entries) entry.key: entry.value.value,
  };

  Set<String> _decodeSelection(RestorableString source) {
    if (source.value.isEmpty) return <String>{};
    return source.value.split(',').where((id) => id.isNotEmpty).toSet();
  }

  void _toggleSelection(RestorableString source, String id) {
    final selected = _decodeSelection(source);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    source.value = (selected.toList()..sort()).join(',');
  }

  void _onFinish() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final dob = _dob.value;
    if (dob == null || !isAdult(dob)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.onbUnder18 ?? 'You must be 18+.')),
      );
      return;
    }
    final missing = missingRequiredConsents(_consentValues);
    if (missing.isNotEmpty) {
      setState(() => _step.value = _consentStepIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.onbConsentRequired ??
                'Please agree to the required permissions.',
          ),
        ),
      );
      return;
    }
    ref
        .read(onboardingControllerProvider.notifier)
        .submit(
          displayName: _nameCtrl.value.text,
          fullName: _nameCtrl.value.text,
          dob: dob,
          bio: _bioCtrl.value.text,
          consents: _consentValues,
          genreIds: _decodeSelection(_genreSel).toList(),
          artistIds: _decodeSelection(_artistSel).toList(),
          songIds: _decodeSelection(_songSel).toList(),
          language: Localizations.localeOf(context).languageCode,
        );
  }

  Widget _tasteSection<T>({
    required String label,
    required AsyncValue<List<T>> async,
    required String Function(T) labelOf,
    required String Function(T) idOf,
    required RestorableString selected,
  }) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final selectedIds = _decodeSelection(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) {
            debugPrint('onboarding: reference load error: $err');
            return EmptyState(
              icon: Icons.wifi_off,
              title: l10n?.onbLoadError ?? 'Could not load data.',
              subtitle: 'Try again later.',
            );
          },
          data: (items) => TasteChips<T>(
            items: items,
            labelOf: labelOf,
            idOf: idOf,
            selected: selectedIds,
            onToggle: (id) => setState(() => _toggleSelection(selected, id)),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
              l10n?.onbSubmitError ?? 'Something went wrong. Please try again.',
            ),
          ),
        );
      }
    });

    final genres = ref.watch(genresProvider);
    final artists = ref.watch(artistsProvider);
    final songs = ref.watch(songsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.onbSetupTitle ?? 'Set up profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bước ${_step.value + 1}/4',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _step.value,
        onStepContinue: () {
          if (_step.value < _lastStep) {
            setState(() => _step.value += 1);
          }
        },
        onStepCancel: () {
          if (_step.value > 0) {
            setState(() => _step.value -= 1);
          }
        },
        controlsBuilder: (context, details) {
          final isLast = _step.value == _lastStep;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (!isLast)
                  FilledButton(
                    key: details.isActive
                        ? const Key('onb_continue_btn')
                        : null,
                    onPressed: details.onStepContinue,
                    child: Text(l10n?.onbContinue ?? 'Continue'),
                  ),
                if (isLast)
                  FilledButton(
                    key: const Key('onb_finish'),
                    onPressed: loading ? null : _onFinish,
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n?.onbFinish ?? 'Finish'),
                  ),
                const SizedBox(width: 8),
                if (_step.value > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(l10n?.onbBack ?? 'Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(l10n?.onbStepDob ?? 'Date of birth'),
            isActive: _step.value >= 0,
            content: DobStep(
              dob: _dob.value,
              onPick: (d) => setState(() => _dob.value = d),
            ),
          ),
          Step(
            title: Text(l10n?.onbConsentTitle ?? 'Privacy'),
            isActive: _step.value >= 1,
            content: ConsentStep(
              values: _consentValues,
              onChanged: (k, v) {
                final consent = _consents[k];
                if (consent == null) return;
                setState(() => consent.value = v);
              },
            ),
          ),
          Step(
            title: Text(l10n?.onbStepProfile ?? 'Profile'),
            isActive: _step.value >= 2,
            content: Column(
              children: [
                TextField(
                  key: const Key('onb_name'),
                  controller: _nameCtrl.value,
                  decoration: InputDecoration(
                    labelText: l10n?.onbNameLabel ?? 'Display name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('onb_bio'),
                  controller: _bioCtrl.value,
                  decoration: InputDecoration(
                    labelText: l10n?.onbBioLabel ?? 'Bio',
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: Text(l10n?.onbStepTaste ?? 'Music taste'),
            isActive: _step.value >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tasteSection<Genre>(
                  label: l10n?.onbTasteGenres ?? 'Genres',
                  async: genres,
                  labelOf: (g) => g.nameVi,
                  idOf: (g) => g.id,
                  selected: _genreSel,
                ),
                _tasteSection<Artist>(
                  label: l10n?.onbTasteArtists ?? 'Artists',
                  async: artists,
                  labelOf: (a) => a.name,
                  idOf: (a) => a.id,
                  selected: _artistSel,
                ),
                _tasteSection<Song>(
                  label: l10n?.onbBaitu ?? 'Signature songs',
                  async: songs,
                  labelOf: (s) => s.title,
                  idOf: (s) => s.id,
                  selected: _songSel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
