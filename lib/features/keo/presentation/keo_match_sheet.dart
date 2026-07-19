import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/ticket_card.dart';
import '../../../shared/widgets/wave_divider.dart';
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
        child: KeyedSubtree(
          key: const Key('screen_12_keo_auto_match'),
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
                  Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.keoMatchNoneFound ??
                      'Chưa tìm được kèo phù hợp. Thử lại sau.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final suggestion = widget.suggestions.first;
    final isExisting = suggestion.suggestionType == 'existing_keo';
    final title = isExisting
        ? (l10n?.keoMatchExistingTitle ?? 'Kèo hợp với bạn')
        : (l10n?.keoMatchNewTitle ?? 'Đã tìm thấy nhóm phù hợp');
    final timeWindow = _formatSuggestionTimeWindow(suggestion);

    return SafeArea(
      child: ColoredBox(
        color: AppColors.surface,
        child: KeyedSubtree(
          key: const Key('screen_12_keo_auto_match'),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
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
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          border: Border.all(color: AppColors.ink, width: 2),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusPill,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.ink,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      IconButton.outlined(
                        tooltip: l10n?.commonClose ?? 'Đóng',
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const WaveDivider(),
                  const SizedBox(height: AppSpacing.md),
                  TicketCard(
                    showPerforation: false,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (timeWindow != null) ...[
                          _SuggestionMetaRow(
                            icon: Icons.schedule_rounded,
                            label: timeWindow,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                              ),
                              child: const Icon(
                                Icons.mic_external_on_outlined,
                                color: AppColors.ink,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _displayTitle(suggestion.title),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SuggestionMeta(suggestion: suggestion),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final genre in suggestion.genres)
                              StampChip(label: genre, tone: StampChipTone.teal),
                            _SuggestionJoinModeStamp(
                              joinMode: suggestion.joinMode,
                            ),
                          ],
                        ),
                        if (suggestion.hostName != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _SuggestionMetaRow(
                            icon: Icons.person_outline,
                            label: suggestion.hostName!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (suggestion.reasonLabels.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      key: const Key('keo_match_reason_grid'),
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth =
                              (constraints.maxWidth - AppSpacing.sm) / 2;
                          return Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final reason in suggestion.reasonLabels)
                                SizedBox(
                                  width: itemWidth,
                                  child: _ReasonChip(code: reason),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  if (isExisting)
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        key: const Key('keo_match_join_btn'),
                        onPressed: _submitting
                            ? null
                            : () => _submit(widget.onJoin, suggestion),
                        icon: Icons.login_rounded,
                        child: _PrimaryButtonChild(
                          submitting: _submitting,
                          label: 'Tham gia',
                        ),
                      ),
                    )
                  else
                    _ProposalActions(
                      submitting: _submitting,
                      onLater: _submitting
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      onCreate: _submitting
                          ? null
                          : () => _submit(widget.onCreate, suggestion),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Titles come from the DB with proper diacritics ('Kèo gợi ý tối nay');
  // no display-side rewriting needed.
  String _displayTitle(String raw) => raw;
}

class _SuggestionMeta extends StatelessWidget {
  const _SuggestionMeta({required this.suggestion});

  final KeoMatchSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final details = <_MetaItem>[
      if (suggestion.areaLabel != null)
        _MetaItem(Icons.place_outlined, suggestion.areaLabel!),
      if (suggestion.distanceBand != null)
        _MetaItem(Icons.near_me_outlined, '${suggestion.distanceBand} km'),
      _MetaItem(
        Icons.groups_outlined,
        Localizations.of<AppLocalizations>(
              context,
              AppLocalizations,
            )?.keoCardPeople(suggestion.slotsFilled, suggestion.sizeTarget) ??
            '${suggestion.slotsFilled}/${suggestion.sizeTarget} người',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final detail in details)
          _SuggestionMetaRow(icon: detail.icon, label: detail.label),
      ],
    );
  }
}

class _SuggestionMetaRow extends StatelessWidget {
  const _SuggestionMetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.teal),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionJoinModeStamp extends StatelessWidget {
  const _SuggestionJoinModeStamp({required this.joinMode});

  final String joinMode;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final isOpen = joinMode == 'open';
    final label = isOpen
        ? (l10n?.keoModeOpen ?? 'Mở · vào là tham gia')
        : (l10n?.keoModeApproval ?? 'Cần duyệt');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.secondary : AppColors.teal,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.lock_open_rounded : Icons.verified_user_outlined,
            size: 16,
            color: AppColors.ink,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _formatSuggestionTimeWindow(KeoMatchSuggestion suggestion) {
  final isExisting = suggestion.suggestionType == 'existing_keo';
  final start = isExisting
      ? suggestion.timeWindowStart
      : suggestion.proposedStart;
  final end = isExisting ? suggestion.timeWindowEnd : suggestion.proposedEnd;
  if (start == null || end == null) return null;

  try {
    final startLocal = DateTime.parse(start).toLocal();
    final endLocal = DateTime.parse(end).toLocal();
    final sameDate =
        startLocal.year == endLocal.year &&
        startLocal.month == endLocal.month &&
        startLocal.day == endLocal.day;
    if (sameDate) {
      return '${_suggestionTime(startLocal)} - ${_suggestionTime(endLocal)}';
    }
    return '${_suggestionDateTime(startLocal)} - '
        '${_suggestionDateTime(endLocal)}';
  } on FormatException {
    return '$start - $end';
  }
}

String _suggestionDateTime(DateTime value) {
  return '${_fourDigits(value.year)}-${_twoDigits(value.month)}-'
      '${_twoDigits(value.day)} ${_suggestionTime(value)}';
}

String _suggestionTime(DateTime value) {
  return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}

String _fourDigits(int value) => value.toString().padLeft(4, '0');

String _twoDigits(int value) => value.toString().padLeft(2, '0');

class _MetaItem {
  const _MetaItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.code});

  /// Mã lý do từ server ('shared_genres'…) — label + icon đều suy từ CODE,
  /// không từ chuỗi hiển thị (trước đây icon lookup theo chuỗi VI, l10n xong
  /// sẽ vỡ).
  final String code;

  String _labelFor(AppLocalizations? l10n) => switch (code) {
    'shared_genres' => l10n?.keoMatchReasonSharedGenres ?? 'Hợp gu nhạc',
    'near_you' => l10n?.keoMatchReasonNearYou ?? 'Gần bạn',
    'evening_slot' => l10n?.keoMatchReasonEveningSlot ?? 'Giờ đẹp',
    'open_join' => l10n?.keoMatchReasonOpenJoin ?? 'Vào nhanh',
    'available_slots' => l10n?.keoMatchReasonAvailableSlots ?? 'Còn chỗ',
    'active_host' =>
      l10n?.keoMatchReasonActiveHost ?? 'Chủ kèo đang trực tuyến',
    _ => code,
  };

  @override
  Widget build(BuildContext context) {
    final label = _labelFor(
      Localizations.of<AppLocalizations>(context, AppLocalizations),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeight),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          border: Border.all(color: AppColors.ink, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
          boxShadow: const [AppShadows.hard],
        ),
        child: Row(
          children: [
            Icon(_iconFor(code), color: AppColors.ink, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String value) => switch (value) {
    'shared_genres' => Icons.music_note_rounded,
    'near_you' => Icons.place_outlined,
    'evening_slot' => Icons.schedule_outlined,
    'open_join' => Icons.bolt_rounded,
    'available_slots' => Icons.groups_outlined,
    'active_host' => Icons.person_outline,
    _ => Icons.auto_awesome_outlined,
  };
}

class _ProposalActions extends StatelessWidget {
  const _ProposalActions({
    required this.submitting,
    required this.onLater,
    required this.onCreate,
  });

  final bool submitting;
  final VoidCallback? onLater;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final laterButton = OutlinedButton(
      key: const Key('keo_match_later_btn'),
      onPressed: onLater,
      child: Text(l10n?.upsellLater ?? 'Để sau'),
    );
    final createButton = GradientButton(
      key: const Key('keo_match_create_btn'),
      onPressed: onCreate,
      icon: Icons.group_add_outlined,
      child: _PrimaryButtonChild(
        submitting: submitting,
        label: l10n?.keoCreateCta ?? 'Tạo kèo',
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final stack = constraints.maxWidth < 320 || textScale > 1.35;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              laterButton,
              const SizedBox(height: AppSpacing.sm),
              createButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: laterButton),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: createButton),
          ],
        );
      },
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
