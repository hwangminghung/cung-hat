import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final stackTime = availableWidth < 420 || textScale > 1;

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
              // UI review: đặt đường đục lỗ theo dp (giữa cột giờ 58dp và nội
              // dung) — fraction theo bề rộng màn làm nó cắt xuyên chữ/chip/avatar
              // ở màn hẹp.
              perforationOffset: AppSpacing.md + 58 + AppSpacing.lg / 2,
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
      },
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
        Icon(Icons.schedule_outlined, color: AppColors.ink, size: 26),
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
        Icon(Icons.schedule_outlined, color: AppColors.ink),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(time.start, style: Theme.of(context).textTheme.titleMedium),
              Text('—', style: Theme.of(context).textTheme.titleSmall),
              Text(time.end, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
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
              // UI review: tiêu đề tối đa 2 dòng, cỡ vừa (titleMedium đậm) —
              // không tranh chỗ với badge/metadata, không va mũi tên.
              child: Text(
                keo.title,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.arrow_forward_rounded, color: AppColors.ink, size: 20),
          ],
        ),
        if (keo.areaLabel != null || keo.distanceBand != null) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (keo.areaLabel != null)
                _Meta(Icons.place_outlined, keo.areaLabel!),
              if (keo.distanceBand != null)
                _Meta(
                  Icons.near_me_outlined,
                  Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.keoCardDistance(keo.distanceBand!) ??
                      'cách ${keo.distanceBand} km',
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _Meta(
              Icons.groups_outlined,
              Localizations.of<AppLocalizations>(
                    context,
                    AppLocalizations,
                  )?.keoCardPeople(keo.slotsFilled, keo.sizeTarget) ??
                  '${keo.slotsFilled}/${keo.sizeTarget} người',
            ),
          ],
        ),
        if (keo.memberNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _MemberStrip(names: keo.memberNames, sizeTarget: keo.sizeTarget),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final genre in keo.genres)
              StampChip(label: genre, tone: StampChipTone.teal),
            if (keo.joinMode == 'open')
              _OpenJoinModeStamp(
                label:
                    Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    )?.keoModeOpen ??
                    'Mở · vào là tham gia',
              )
            else
              StampChip(
                label:
                    Localizations.of<AppLocalizations>(
                      context,
                      AppLocalizations,
                    )?.keoModeApproval ??
                    'Cần duyệt',
                tone: StampChipTone.teal,
                leadingIcon: Icons.verified_user_outlined,
              ),
          ],
        ),
        if (keo.hostName != null) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(children: [_Meta(Icons.person_outline, keo.hostName!)]),
        ],
      ],
    );
  }
}

class _OpenJoinModeStamp extends StatelessWidget {
  const _OpenJoinModeStamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open_rounded, size: 16, color: AppColors.ink),
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
              child: Icon(
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
        // Flexible + ellipsis: nhãn dài (địa danh/tên chủ kèo) co lại thay vì
        // tràn phải 16px ở màn hẹp (probe 393dp, UI review 2026-07-16).
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
