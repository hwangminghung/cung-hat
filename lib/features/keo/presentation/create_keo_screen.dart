import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../onboarding/application/reference_providers.dart';
import '../application/keo_providers.dart';
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return 'Chọn';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final areaText = _areaCtrl.text.trim();
    if (title.isEmpty) {
      _snack('Nhập tên kèo');
      return;
    }
    if (_start == null || _end == null) {
      _snack('Chọn giờ bắt đầu và kết thúc');
      return;
    }
    if (!_end!.isAfter(_start!)) {
      _snack('Giờ kết thúc phải sau giờ bắt đầu');
      return;
    }

    setState(() => _submitting = true);
    try {
      final pos = await ref.read(locationServiceProvider).currentPosition();
      if (!mounted) return;
      if (pos == null) {
        _snack(
          'Không lấy được vị trí. Bật Location trên emulator rồi thử lại.',
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
      _snack(keoErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo kèo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Text(
            'Rủ một nhóm đi hát',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chọn thời gian, gu nhạc và cách duyệt thành viên.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          _FormSection(
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên kèo',
                  hintText: 'V-Pop tối nay',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Khu vực',
                  hintText: 'Quận 1, Hồ Chí Minh',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            key: const Key('create_keo_venue_hint'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: AppColors.secondaryDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn quán sau khi tạo kèo',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Chủ kèo sẽ chốt quán ở màn Kế hoạch.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _submitting
                ? null
                : () async {
                    final dt = await _pickDateTime(_start);
                    if (dt != null) setState(() => _start = dt);
                  },
            icon: const Icon(Icons.schedule_rounded),
            label: Text('Bắt đầu: ${_fmt(_start)}'),
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
            label: Text('Kết thúc: ${_fmt(_end)}'),
          ),
          const SizedBox(height: AppSpacing.md),
          _FormSection(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _size,
                decoration: const InputDecoration(labelText: 'Số người'),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2 người')),
                  DropdownMenuItem(value: 3, child: Text('3 người')),
                  DropdownMenuItem(value: 4, child: Text('4 người')),
                  DropdownMenuItem(value: 5, child: Text('5 người')),
                ],
                onChanged: _submitting
                    ? null
                    : (value) {
                        if (value != null) setState(() => _size = value);
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Thể loại', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              genresAsync.when(
                data: (genres) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final genre in genres)
                      FilterChip(
                        key: Key('keo_genre_${genre.id}'),
                        label: Text(genre.nameVi),
                        selected: _genreIds.contains(genre.id),
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
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Text('Không tải được thể loại'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Chế độ tham gia',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'approval',
                label: Text('Cần duyệt'),
                icon: Icon(Icons.verified_user_rounded),
              ),
              ButtonSegment(
                value: 'open',
                label: Text('Mở'),
                icon: Icon(Icons.lock_open_rounded),
              ),
            ],
            selected: {_joinMode},
            onSelectionChanged: _submitting
                ? null
                : (selection) => setState(() => _joinMode = selection.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            key: const Key('create_keo_btn'),
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Icon(Icons.add_rounded),
            label: const Text('Tạo kèo'),
          ),
        ],
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
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
