import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xxxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.primaryDark,
                  size: 30,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Chưa tìm được kèo phù hợp. Thử lại sau.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final suggestion = widget.suggestions.first;
    final isExisting = suggestion.suggestionType == 'existing_keo';
    final title = isExisting ? 'Kèo hợp với bạn' : 'Đã tìm thấy nhóm phù hợp';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.xxxl,
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayTitle(suggestion.title),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SuggestionMeta(suggestion: suggestion),
                    if (suggestion.genres.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final genre in suggestion.genres)
                            _SoftChip(label: genre),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (suggestion.reasonLabels.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
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
                  child: FilledButton.icon(
                    key: const Key('keo_match_join_btn'),
                    onPressed: _submitting
                        ? null
                        : () => _submit(widget.onJoin, suggestion),
                    icon: const Icon(Icons.login_rounded),
                    label: _PrimaryButtonChild(
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
                          child: const Text('Để sau'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: AppSpacing.buttonHeight,
                        child: FilledButton.icon(
                          key: const Key('keo_match_create_btn'),
                          onPressed: _submitting
                              ? null
                              : () => _submit(widget.onCreate, suggestion),
                          icon: const Icon(Icons.group_add_rounded),
                          label: _PrimaryButtonChild(
                            submitting: _submitting,
                            label: 'Tạo kèo',
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

  // Titles come from the DB with proper diacritics ('Kèo gợi ý tối nay');
  // no display-side rewriting needed.
  String _displayTitle(String raw) => raw;

  String _reasonLabel(String reason) {
    return switch (reason) {
      'shared_genres' => 'Hợp gu nhạc',
      'near_you' => 'Gần bạn',
      'evening_slot' => 'Giờ đẹp',
      'open_join' => 'Vào nhanh',
      'available_slots' => 'Còn chỗ',
      'active_host' => 'Chủ kèo đang online',
      _ => reason,
    };
  }
}

class _SuggestionMeta extends StatelessWidget {
  const _SuggestionMeta({required this.suggestion});

  final KeoMatchSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final timeWindow = _formatTimeWindow(suggestion);
    final details = <_MetaItem>[
      _MetaItem(
        Icons.groups_rounded,
        '${suggestion.slotsFilled}/${suggestion.sizeTarget} người',
      ),
      if (timeWindow != null) _MetaItem(Icons.schedule_rounded, timeWindow),
      if (suggestion.distanceBand != null)
        _MetaItem(Icons.place_rounded, '${suggestion.distanceBand} km'),
      if (suggestion.areaLabel != null)
        _MetaItem(Icons.map_rounded, suggestion.areaLabel!),
      if (suggestion.hostName != null)
        _MetaItem(Icons.person_rounded, suggestion.hostName!),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final detail in details)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(detail.icon, size: 16, color: AppColors.textHint),
              const SizedBox(width: AppSpacing.xs),
              Text(
                detail.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String? _formatTimeWindow(KeoMatchSuggestion suggestion) {
    final isExisting = suggestion.suggestionType == 'existing_keo';
    final start = isExisting
        ? suggestion.timeWindowStart
        : suggestion.proposedStart;
    final end = isExisting ? suggestion.timeWindowEnd : suggestion.proposedEnd;
    if (start == null || end == null) return null;

    try {
      final startUtc = DateTime.parse(start).toUtc();
      final endUtc = DateTime.parse(end).toUtc();
      final sameDate =
          startUtc.year == endUtc.year &&
          startUtc.month == endUtc.month &&
          startUtc.day == endUtc.day;
      final endText = sameDate ? _time(endUtc) : _dateTime(endUtc);
      return '${_dateTime(startUtc)} - $endText UTC';
    } on FormatException {
      return '$start - $end';
    }
  }

  String _dateTime(DateTime value) {
    return '${_fourDigits(value.year)}-${_twoDigits(value.month)}-${_twoDigits(value.day)} '
        '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

  String _time(DateTime value) {
    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

  String _fourDigits(int value) => value.toString().padLeft(4, '0');

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _MetaItem {
  const _MetaItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.secondaryDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.tertiaryTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.tertiary,
          fontWeight: FontWeight.w800,
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
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.onPrimary,
      ),
    );
  }
}
