import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../application/profile_providers.dart';
import '../domain/karaoke_prompts.dart';
import '../domain/profile.dart';

/// Bottom sheet to manage the current user's karaoke Q&A prompt cards
/// (max [maxPrompts]). Pattern-matched on [PhotoManagerSheet]: reads the
/// existing selection from [myProfileProvider], edits locally, saves via
/// [ProfileRepository.setMyPrompts] on an explicit Save tap, then invalidates
/// [myProfileProvider] and pops.
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

  /// Whether [_answers] has been seeded from [myProfileProvider] yet. Seeding
  /// must happen on first build, not [initState]: `myProfileProvider` is a
  /// [FutureProvider] and is very likely still loading (value == null) the
  /// instant this widget is created, so reading it once in `initState` would
  /// almost always seed an empty map. Seeding in `build` — guarded so it only
  /// runs once — lets it pick up the resolved value on whichever rebuild it
  /// actually lands on, without clobbering answers the user has since edited.
  bool _seeded = false;

  void _seedFrom(Profile? profile) {
    if (_seeded || profile == null) return;
    _seeded = true;
    for (final p in profile.prompts) {
      final id = p['prompt_id'] as String?;
      final answer = p['answer'] as String?;
      if (id != null && answer != null) _answers[id] = answer;
    }
  }

  void _toggleExpand(String id) {
    if (_expandedId == id) {
      setState(() => _expandedId = null);
      return;
    }
    if (!_answers.containsKey(id) && _answers.length >= maxPrompts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa $maxPrompts thẻ')),
      );
      return;
    }
    setState(() => _expandedId = id);
  }

  void _setAnswer(String id, String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _answers.remove(id);
      } else {
        _answers[id] = value;
      }
    });
  }

  void _clear(String id) {
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
          const SnackBar(content: Text('Không lưu được, thử lại.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _seedFrom(ref.watch(myProfileProvider).value);
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
                'Thẻ hỏi-đáp',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chọn tối đa $maxPrompts câu để hồ sơ có chuyện mà bắt.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton(
                  key: const Key('save_prompts_btn'),
                  onPressed: _saving ? null : _save,
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
                decoration: const InputDecoration(
                  hintText: 'Câu trả lời của bạn…',
                  isDense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
