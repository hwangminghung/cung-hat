import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../../shared/widgets/ticket_card.dart';
import '../domain/keo.dart';

class KeoCard extends StatelessWidget {
  const KeoCard({super.key, required this.keo, this.onTap});

  final Keo keo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final time = _formatTime(keo.timeWindowStart, keo.timeWindowEnd);
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final stackTime = textScale > 1.35;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Pressable(
        onTap: onTap,
        child: TicketCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          showPerforation: time != null && !stackTime,
          perforationPosition: 0.25,
          child: time != null && !stackTime
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 58, child: _TimeStub(time: time)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _KeoDetails(keo: keo, text: text),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (time != null) ...[
                      _CompactTime(time: time),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _KeoDetails(keo: keo, text: text),
                  ],
                ),
        ),
      ),
    );
  }

  ({String start, String end})? _formatTime(String? start, String? end) {
    if (start == null || end == null) return null;
    final startAt = DateTime.tryParse(start);
    final endAt = DateTime.tryParse(end);
    if (startAt == null || endAt == null) return null;

    final localStart = startAt.toLocal();
    final localEnd = endAt.toLocal();
    return (
      start: '${_two(localStart.hour)}:${_two(localStart.minute)}',
      end: '${_two(localEnd.hour)}:${_two(localEnd.minute)}',
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _TimeStub extends StatelessWidget {
  const _TimeStub({required this.time});

  final ({String start, String end}) time;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule_outlined, color: AppColors.ink, size: 26),
        const SizedBox(height: AppSpacing.sm),
        Text(time.start, style: Theme.of(context).textTheme.titleMedium),
        Text('—', style: Theme.of(context).textTheme.titleSmall),
        Text(time.end, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _CompactTime extends StatelessWidget {
  const _CompactTime({required this.time});

  final ({String start, String end}) time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.schedule_outlined, color: AppColors.ink),
        const SizedBox(width: AppSpacing.sm),
        Text(time.start, style: Theme.of(context).textTheme.titleMedium),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('—'),
        ),
        Text(time.end, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _KeoDetails extends StatelessWidget {
  const _KeoDetails({required this.keo, required this.text});

  final Keo keo;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                keo.title,
                style: text.titleLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StampChip(
              label: keo.joinMode == 'open'
                  ? 'Mở · vào là tham gia'
                  : 'Cần duyệt',
              tone: keo.joinMode == 'open'
                  ? StampChipTone.lime
                  : StampChipTone.teal,
              leadingIcon: keo.joinMode == 'open'
                  ? Icons.lock_open_rounded
                  : Icons.verified_user_outlined,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            if (keo.areaLabel != null)
              _Meta(Icons.place_outlined, keo.areaLabel!),
            if (keo.distanceBand != null)
              _Meta(Icons.near_me_outlined, 'cách ${keo.distanceBand} km'),
            _Meta(
              Icons.groups_outlined,
              '${keo.slotsFilled}/${keo.sizeTarget} người',
            ),
            if (keo.hostName != null)
              _Meta(Icons.person_outline, keo.hostName!),
          ],
        ),
        if (keo.genres.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final genre in keo.genres)
                StampChip(label: genre, tone: StampChipTone.teal),
            ],
          ),
        ],
        if (keo.memberNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _MemberStrip(
            names: keo.memberNames,
            sizeTarget: keo.sizeTarget,
          ),
        ],
      ],
    );
  }
}

/// Dải avatar thành viên (mockup 11): monogram tròn cho người đã vào +
/// vòng "+" nhạt cho chỗ trống còn lại (tối đa 5 vòng tổng).
class _MemberStrip extends StatelessWidget {
  const _MemberStrip({required this.names, required this.sizeTarget});

  final List<String> names;
  final int sizeTarget;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(5).toList();
    final empty = (sizeTarget - names.length).clamp(0, 5 - shown.length);
    return Row(
      key: const Key('keo_member_strip'),
      children: [
        for (final name in shown)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: Text(
                name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        for (var i = 0; i < empty; i++)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textHint, width: 1.5),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.textHint,
              ),
            ),
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.teal),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
