import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cung_hat/l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';
import '../application/reference_providers.dart';
import '../domain/music_ref.dart';
import 'consent_step.dart';
import 'dob_step.dart';
import 'taste_step.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});
  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  DateTime? _dob;
  late final Map<String, bool> _consents = {for (final p in consentPurposes) p: false};
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final Set<String> _genreSel = {};
  final Set<String> _artistSel = {};
  final Set<String> _songSel = {};
  int _step = 0;

  static const _lastStep = 3;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _onFinish() {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (_dob == null || !isAdult(_dob!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.onbUnder18 ?? 'Bạn phải đủ 18 tuổi.')),
      );
      return;
    }
    ref.read(onboardingControllerProvider.notifier).submit(
          displayName: _nameCtrl.text,
          fullName: _nameCtrl.text,
          dob: _dob!,
          bio: _bioCtrl.text,
          consents: _consents,
          genreIds: _genreSel.toList(),
          artistIds: _artistSel.toList(),
          songIds: _songSel.toList(),
        );
  }

  Widget _tasteSection<T>({
    required String label,
    required AsyncValue<List<T>> async,
    required String Function(T) labelOf,
    required String Function(T) idOf,
    required Set<String> selected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          // TODO(T8): localize error message
          error: (err, _) => Text('$err'),
          data: (items) => TasteChips<T>(
            items: items,
            labelOf: labelOf,
            idOf: idOf,
            selected: selected,
            onToggle: (id) => setState(
              () => selected.contains(id) ? selected.remove(id) : selected.add(id),
            ),
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
        // TODO(T8): localize error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${next.error}')),
        );
      }
    });

    final genres = ref.watch(genresProvider);
    final artists = ref.watch(artistsProvider);
    final songs = ref.watch(songsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thiết lập hồ sơ')),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _step,
        onStepContinue: () {
          if (_step < _lastStep) setState(() => _step += 1);
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step -= 1);
        },
        controlsBuilder: (context, details) {
          final isLast = _step == _lastStep;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (!isLast)
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Tiếp tục'),
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
                        : Text(l10n?.onbFinish ?? 'Hoàn tất'),
                  ),
                const SizedBox(width: 8),
                if (_step > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Quay lại'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Ngày sinh'),
            isActive: _step >= 0,
            content: DobStep(
              dob: _dob,
              onPick: (d) => setState(() => _dob = d),
            ),
          ),
          Step(
            title: Text(l10n?.onbConsentTitle ?? 'Quyền riêng tư'),
            isActive: _step >= 1,
            content: ConsentStep(
              values: _consents,
              onChanged: (k, v) => setState(() => _consents[k] = v),
            ),
          ),
          Step(
            title: const Text('Hồ sơ'),
            isActive: _step >= 2,
            content: Column(
              children: [
                TextField(
                  key: const Key('onb_name'),
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                      labelText: l10n?.onbNameLabel ?? 'Tên hiển thị'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('onb_bio'),
                  controller: _bioCtrl,
                  decoration: InputDecoration(
                      labelText: l10n?.onbBioLabel ?? 'Giới thiệu'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Gu nhạc'),
            isActive: _step >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tasteSection<Genre>(
                  label: l10n?.onbTasteGenres ?? 'Thể loại',
                  async: genres,
                  labelOf: (g) => g.nameVi,
                  idOf: (g) => g.id,
                  selected: _genreSel,
                ),
                _tasteSection<Artist>(
                  label: l10n?.onbTasteArtists ?? 'Nghệ sĩ',
                  async: artists,
                  labelOf: (a) => a.name,
                  idOf: (a) => a.id,
                  selected: _artistSel,
                ),
                _tasteSection<Song>(
                  label: l10n?.onbBaitu ?? 'Bài tủ',
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
