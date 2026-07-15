import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../application/profile_providers.dart';
import '../domain/karaoke_prompts.dart';
import '../domain/profile.dart';

/// Bottom sheet to manage the current user's karaoke Q&A prompt cards
/// (max [maxPrompts]). Pattern-matched on [PhotoManagerSheet]: seeds the
/// existing selection from [myProfileProvider] exactly once, on the first
/// build after the provider resolves — until then the rows and the Save
/// button are inert (dimmed, taps no-op), so early input can never race the
/// seed. After that the user edits locally and saves via
/// [ProfileRepository.setMyPrompts] on an explicit Save tap, which
/// invalidates [myProfileProvider] and pops.
class PromptEditorSheet extends ConsumerStatefulWidget {
  const PromptEditorSheet({super.key});

  @override
  ConsumerState<PromptEditorSheet> createState() => _PromptEditorSheetState();
}

class _PromptEditorSheetState extends ConsumerState<PromptEditorSheet> {
  /// Ordered map preserving selection order — iteration order of a
  /// [LinkedHashMap] (the default [Map] literal) is insertion order, and
  /// re-inserting an existing key does NOT move it, so the order in which the
  /// user first answered each prompt is what gets saved.
  final Map<String, String> _answers = {};

  /// The prompt id whose TextField is currently expanded, or null.
  String? _expandedId;

  bool _saving = false;

  /// Whether [_answers] has been seeded from [myProfileProvider]. The trigger
  /// is the provider RESOLVING (first build where it is no longer loading —
  /// data, empty prompts or error alike), never a user interaction. Seeding
  /// can't run in [initState]: the [FutureProvider] is almost always still
  /// loading at that instant. And while it IS loading, every prompt row and
  /// the Save button are inert (no-op guards + dimmed): otherwise a rebuild
  /// caused by early typing would run the first seed mid-edit and overwrite
  /// colliding [_answers] entries, and an early Save would ship the unseeded
  /// (empty) set and wipe the server rows. After the one-time seed the user
  /// owns [_answers]; later rebuilds never re-seed.
  bool _seeded = false;

  void _seedFrom(AsyncValue<Profile?> profile) {
    if (_seeded || profile.isLoading) return;
    // Resolved: data (possibly a null profile / empty prompts) or error.
    // On error there is nothing to seed — unlock editing rather than leaving
    // the sheet permanently dead; saving then simply replaces the set.
    _seeded = true;
    final prompts = profile.value?.prompts ?? const <Map<String, dynamic>>[];
    for (final p in prompts) {
      final id = p['prompt_id'] as String?;
      final answer = p['answer'] as String?;
      if (id != null && answer != null) _answers[id] = answer;
    }
  }

  void _toggleExpand(String id) {
    if (!_seeded) return; // profile still loading — rows are inert
    if (_expandedId == id) {
      setState(() => _expandedId = null);
      return;
    }
    if (!_answers.containsKey(id) && _answers.length >= maxPrompts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.of<AppLocalizations>(context, AppLocalizations)
                    ?.promptMax(maxPrompts) ??
                'Tối đa $maxPrompts thẻ',
          ),
        ),
      );
      return;
    }
    setState(() => _expandedId = id);
  }

  void _setAnswer(String id, String value) {
    if (!_seeded) return; // unreachable while inert; defensive
    setState(() {
      if (value.trim().isEmpty) {
        _answers.remove(id);
      } else {
        _answers[id] = value;
      }
    });
  }

  void _clear(String id) {
    if (!_seeded) return; // unreachable while inert; defensive
    setState(() {
      _answers.remove(id);
      if (_expandedId == id) _expandedId = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ordered = [
        for (final entry in _answers.entries)
          {'prompt_id': entry.key, 'answer': entry.value},
      ];
      await ref.read(profileRepositoryProvider).setMyPrompts(ordered);
      ref.invalidate(myProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.of<AppLocalizations>(context, AppLocalizations)
                      ?.filterSaveError ??
                  'Không lưu được, thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _seedFrom(ref.watch(myProfileProvider));
    return SafeArea(
      child: SingleChildScrollView(
        // 6 prompt rows + header + Save button routinely exceed the modal
        // sheet's viewport (isScrollControlled sizes to content, it does not
        // itself scroll) — scrollable content avoids a RenderFlex overflow on
        // smaller screens, mirroring how DraggableScrollableSheet-based sheets
        // in this app (e.g. CandidateDetailSheet) handle long content.
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
                Localizations.of<AppLocalizations>(context, AppLocalizations)
                        ?.shellTilePrompts ??
                    'Thẻ hỏi-đáp',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                Localizations.of<AppLocalizations>(context, AppLocalizations)
                        ?.promptSubMax(maxPrompts) ??
                    'Chọn tối đa $maxPrompts câu để hồ sơ có chuyện mà bắt.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Dimmed while the profile hasn't resolved — paired with the
              // no-op guards in _toggleExpand/_setAnswer/_clear so the rows
              // are visibly and functionally inert during the load window.
              Opacity(
                opacity: _seeded ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in karaokePrompts)
                      _PromptRow(
                        key: Key('prompt_row_${p.id}'),
                        prompt: p,
                        answer: _answers[p.id],
                        expanded: _expandedId == p.id,
                        onTap: () => _toggleExpand(p.id),
                        onChanged: (v) => _setAnswer(p.id, v),
                        onClear: () => _clear(p.id),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  key: const Key('save_prompts_btn'),
                  // Also gated on _seeded: saving before the seed would send
                  // the empty local set and delete the user's server prompts.
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
                      : const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptRow extends StatefulWidget {
  const _PromptRow({
    super.key,
    required this.prompt,
    required this.answer,
    required this.expanded,
    required this.onTap,
    required this.onChanged,
    required this.onClear,
  });

  final KaraokePrompt prompt;
  final String? answer;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_PromptRow> createState() => _PromptRowState();
}

class _PromptRowState extends State<_PromptRow> {
  // Owned locally (not recreated on parent setState) so typing a keystroke —
  // which bubbles up to the sheet's setState — doesn't stomp the cursor
  // position by rebuilding a fresh TextEditingController every frame.
  late final TextEditingController _controller = TextEditingController(
    text: widget.answer ?? '',
  );

  @override
  void didUpdateWidget(_PromptRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The "xoá" (clear) button removes the answer without touching the
    // TextField directly. In practice `_controller` is created lazily (it's
    // `late final`, first read when the field actually builds), so a clear
    // that happens while collapsed is moot — the controller doesn't exist yet
    // and picks up the (already-null) answer whenever it's first built. But if
    // the row is cleared WHILE expanded (the field is live), the controller
    // already holds the old text and this keeps it in sync.
    if (oldWidget.answer != null && widget.answer == null) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    final answer = widget.answer;
    final expanded = widget.expanded;
    final onTap = widget.onTap;
    final onChanged = widget.onChanged;
    final onClear = widget.onClear;
    final hasAnswer = answer != null && answer.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hasAnswer ? AppColors.primaryTint : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    prompt.question,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasAnswer
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasAnswer)
                  IconButton(
                    key: Key('clear_prompt_${prompt.id}'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: onClear,
                  )
                else
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textHint,
                  ),
              ],
            ),
          ),
          if (hasAnswer && !expanded)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                answer,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: TextField(
                key: Key('answer_field_${prompt.id}'),
                controller: _controller,
                autofocus: true,
                maxLength: 120,
                maxLines: 2,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: Localizations.of<AppLocalizations>(
                              context, AppLocalizations)
                          ?.promptAnswerHint ??
                      'Câu trả lời của bạn…',
                  isDense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
