import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../onboarding/application/reference_providers.dart';
import '../application/keo_providers.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../data/keo_errors.dart';

class CreateKeoScreen extends ConsumerStatefulWidget {
  const CreateKeoScreen({super.key});

  @override
  ConsumerState<CreateKeoScreen> createState() => _CreateKeoScreenState();
}

class _CreateKeoScreenState extends ConsumerState<CreateKeoScreen> {
  final _titleCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  int _size = 4;
  String _joinMode = 'approval';
  final Set<String> _genreIds = {};
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  AppLocalizations? get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return _l10n?.keoCreatePick ?? 'Chọn';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final areaText = _areaCtrl.text.trim();
    if (title.isEmpty) {
      _snack(_l10n?.keoCreateNameMissing ?? 'Nhập tên kèo');
      return;
    }
    if (_start == null || _end == null) {
      _snack(_l10n?.keoCreateTimeMissing ?? 'Chọn giờ bắt đầu và kết thúc');
      return;
    }
    if (!_end!.isAfter(_start!)) {
      _snack(_l10n?.keoCreateTimeOrder ?? 'Giờ kết thúc phải sau giờ bắt đầu');
      return;
    }

    setState(() => _submitting = true);
    try {
      final pos = await ref.read(locationServiceProvider).currentPosition();
      if (!mounted) return;
      if (pos == null) {
        _snack(
          _l10n?.keoCreateNoLocation ??
              'Không lấy được vị trí. Bật vị trí trên máy rồi thử lại.',
        );
        return;
      }
      final id = await ref
          .read(keoRepositoryProvider)
          .createKeo(
            title: title,
            lat: pos.latitude,
            lng: pos.longitude,
            area: areaText.isEmpty ? null : areaText,
            start: _start!,
            end: _end!,
            size: _size,
            genres: _genreIds.toList(),
            joinMode: _joinMode,
          );
      if (!mounted) return;
      context.go('/keo/$id');
    } catch (e) {
      if (!mounted) return;
      // P1-5: free đã giữ 1 kèo active → mở upsell Pro thay vì snack khô.
      if (keoErrorCode(e) == 'free_host_limit') {
        ProUpsellSheet.show(context, variant: ProUpsellVariant.keoCreate);
      } else {
        _snack(keoErrorMessage(e, _l10n));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);
    return Scaffold(
      appBar: AppBar(title: Text(_l10n?.keoCreateCta ?? 'Tạo kèo')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: GradientButton(
              key: const Key('create_keo_btn'),
              onPressed: _submitting ? null : _submit,
              icon: _submitting ? null : Icons.add_box_outlined,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(_l10n?.keoCreateCta ?? 'Tạo kèo'),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    border: Border.all(color: AppColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppColors.ink,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _l10n?.keoCreateHeadline ?? 'Rủ một nhóm đi hát',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _l10n?.keoCreateSubtitle ??
                            'Chọn thời gian, gu nhạc và cách duyệt thành viên.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const WaveDivider(),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              children: [
                TextField(
                  key: const Key('create_keo_title_field'),
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.mic_external_on_outlined),
                    labelText: _l10n?.keoCreateNameLabel ?? 'Tên kèo',
                    hintText: _l10n?.keoCreateNameHint ?? 'V-Pop tối nay',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('create_keo_area_field'),
                  controller: _areaCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.place_outlined),
                    labelText: _l10n?.keoCreateAreaLabel ?? 'Khu vực',
                    hintText: _l10n?.keoCreateAreaHint ?? 'Quận 1, Hồ Chí Minh',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              key: const Key('create_keo_venue_hint'),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.ink, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                boxShadow: const [AppShadows.hard],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      border: Border.all(color: AppColors.ink, width: 2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _l10n?.keoCreateVenueLater ?? 'Chọn quán sau khi tạo kèo',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _l10n?.keoCreateVenueLaterSub ??
                              'Chủ kèo sẽ chốt quán ở màn Kế hoạch.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const WaveDivider(),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _submitting
                  ? null
                  : () async {
                      final dt = await _pickDateTime(_start);
                      if (dt != null) setState(() => _start = dt);
                    },
              icon: const Icon(Icons.schedule_rounded),
              label: Text(
                _l10n?.keoCreateStart(_fmt(_start)) ?? 'Bắt đầu: ${_fmt(_start)}',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _submitting
                  ? null
                  : () async {
                      final dt = await _pickDateTime(_end);
                      if (dt != null) setState(() => _end = dt);
                    },
              icon: const Icon(Icons.flag_rounded),
              label: Text(
                _l10n?.keoCreateEnd(_fmt(_end)) ?? 'Kết thúc: ${_fmt(_end)}',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const WaveDivider(),
            const SizedBox(height: AppSpacing.md),
            _FormSection(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _size,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.groups_outlined),
                    labelText: _l10n?.keoCreateSize ?? 'Số người',
                  ),
                  items: [
                    for (final n in const [2, 3, 4, 5])
                      DropdownMenuItem(
                        value: n,
                        child: Text(_l10n?.keoCreateSizeN(n) ?? '$n người'),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) setState(() => _size = value);
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                const WaveDivider(),
                const SizedBox(height: AppSpacing.md),
                Text(_l10n?.keoCreateGenres ?? 'Thể loại',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                genresAsync.when(
                  data: (genres) => LayoutBuilder(
                    key: const Key('create_keo_genre_grid'),
                    builder: (context, constraints) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(12) / 12;
                      final twoColumns =
                          constraints.maxWidth >= 280 && textScale <= 1.35;
                      final itemWidth = twoColumns
                          ? (constraints.maxWidth - AppSpacing.sm) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final genre in genres)
                            SizedBox(
                              width: itemWidth,
                              child: FilterChip(
                                key: Key('keo_genre_${genre.id}'),
                                avatar: const Icon(
                                  Icons.music_note_outlined,
                                  color: AppColors.ink,
                                ),
                                label: Text(genre.nameVi),
                                selected: _genreIds.contains(genre.id),
                                selectedColor: AppColors.secondary,
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(
                                  color: AppColors.ink,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusCard,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.md,
                                ),
                                onSelected: _submitting
                                    ? null
                                    : (selected) => setState(() {
                                        if (selected) {
                                          _genreIds.add(genre.id);
                                        } else {
                                          _genreIds.remove(genre.id);
                                        }
                                      }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Text(_l10n?.keoCreateGenresError ?? 'Không tải được thể loại'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const WaveDivider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              _l10n?.keoCreateJoinMode ?? 'Chế độ tham gia',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _JoinModeChoices(
              selected: _joinMode,
              enabled: !_submitting,
              onSelected: (value) => setState(() => _joinMode = value),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinModeChoices extends StatelessWidget {
  const _JoinModeChoices({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
        final stack = constraints.maxWidth < 300 || textScale > 1.35;
        final approval = _JoinModeChoice(
          value: 'approval',
          label: l10n?.keoCreateModeApproval ?? 'Cần duyệt',
          icon: Icons.verified_user_outlined,
          selected: selected == 'approval',
          enabled: enabled,
          onTap: onSelected,
        );
        final open = _JoinModeChoice(
          value: 'open',
          label: l10n?.keoCreateModeOpen ?? 'Mở',
          icon: Icons.lock_open_outlined,
          selected: selected == 'open',
          enabled: enabled,
          onTap: onSelected,
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              approval,
              const SizedBox(height: AppSpacing.sm),
              open,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: approval),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: open),
          ],
        );
      },
    );
  }
}

class _JoinModeChoice extends StatelessWidget {
  const _JoinModeChoice({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: Key('create_keo_join_$value'),
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => onTap(value) : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary : AppColors.surface,
              border: Border.all(color: AppColors.ink, width: 2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              boxShadow: const [AppShadows.hard],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.ink),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.ink),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [AppShadows.hard],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
