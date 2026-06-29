import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/keo_match_suggestion.dart';

class KeoMatchSheet extends StatefulWidget {
  const KeoMatchSheet({
    super.key,
    required this.suggestions,
    required this.onJoin,
    required this.onCreate,
  });

  final List<KeoMatchSuggestion> suggestions;
  final Future<void> Function(KeoMatchSuggestion suggestion) onJoin;
  final Future<void> Function(KeoMatchSuggestion suggestion) onCreate;

  @override
  State<KeoMatchSheet> createState() => _KeoMatchSheetState();
}

class _KeoMatchSheetState extends State<KeoMatchSheet> {
  var _submitting = false;

  Future<void> _submit(
    Future<void> Function(KeoMatchSuggestion suggestion) action,
    KeoMatchSuggestion suggestion,
  ) async {
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await action(suggestion);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Chua tim duoc keo phu hop. Thu lai sau.'),
        ),
      );
    }

    final suggestion = widget.suggestions.first;
    final isExisting = suggestion.suggestionType == 'existing_keo';
    final title = isExisting ? 'Keo hop voi ban' : 'Tao keo moi tu goi y nay?';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Dong',
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                suggestion.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _SuggestionMeta(suggestion: suggestion),
              if (suggestion.reasonLabels.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final reason in suggestion.reasonLabels)
                      _ReasonChip(label: _reasonLabel(reason)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (isExisting)
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  child: FilledButton(
                    key: const Key('keo_match_join_btn'),
                    onPressed: _submitting
                        ? null
                        : () => _submit(widget.onJoin, suggestion),
                    child: _PrimaryButtonChild(
                      submitting: _submitting,
                      label: 'Tham gia',
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppSpacing.buttonHeight,
                        child: OutlinedButton(
                          key: const Key('keo_match_later_btn'),
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          child: const Text('De sau'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: AppSpacing.buttonHeight,
                        child: FilledButton(
                          key: const Key('keo_match_create_btn'),
                          onPressed: _submitting
                              ? null
                              : () => _submit(widget.onCreate, suggestion),
                          child: _PrimaryButtonChild(
                            submitting: _submitting,
                            label: 'Tao keo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _reasonLabel(String reason) {
    return switch (reason) {
      'shared_genres' => 'Hop gu nhac',
      'near_you' => 'Gan ban',
      'evening_slot' => 'Gio dep',
      'open_join' => 'Vao nhanh',
      'available_slots' => 'Con cho',
      'active_host' => 'Chu keo dang online',
      _ => reason,
    };
  }
}

class _SuggestionMeta extends StatelessWidget {
  const _SuggestionMeta({required this.suggestion});

  final KeoMatchSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      '${suggestion.slotsFilled}/${suggestion.sizeTarget} nguoi',
      if (suggestion.distanceBand != null) '${suggestion.distanceBand} km',
      if (suggestion.hostName != null) suggestion.hostName!,
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final detail in details)
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _PrimaryButtonChild extends StatelessWidget {
  const _PrimaryButtonChild({required this.submitting, required this.label});

  final bool submitting;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!submitting) return Text(label);

    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
