import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../onboarding/application/reference_providers.dart';
import '../application/keo_providers.dart';

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
        _snack('Cần quyền vị trí để tạo kèo');
        return;
      }
      final id = await ref.read(keoRepositoryProvider).createKeo(
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
    } catch (_) {
      if (!mounted) return;
      _snack('Không tạo được kèo, thử lại');
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
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Tên kèo'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _areaCtrl,
            decoration: const InputDecoration(labelText: 'Khu vực (tuỳ chọn)'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          final dt = await _pickDateTime(_start);
                          if (dt != null) setState(() => _start = dt);
                        },
                  child: Text('Bắt đầu: ${_fmt(_start)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          final dt = await _pickDateTime(_end);
                          if (dt != null) setState(() => _end = dt);
                        },
                  child: Text('Kết thúc: ${_fmt(_end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Số người:'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _size,
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2')),
                  DropdownMenuItem(value: 3, child: Text('3')),
                  DropdownMenuItem(value: 4, child: Text('4')),
                  DropdownMenuItem(value: 5, child: Text('5')),
                ],
                onChanged: _submitting
                    ? null
                    : (v) {
                        if (v != null) setState(() => _size = v);
                      },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Thể loại'),
          const SizedBox(height: 8),
          genresAsync.when(
            data: (genres) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in genres)
                  FilterChip(
                    key: Key('keo_genre_${g.id}'),
                    label: Text(g.nameVi),
                    selected: _genreIds.contains(g.id),
                    onSelected: _submitting
                        ? null
                        : (sel) => setState(() {
                              if (sel) {
                                _genreIds.add(g.id);
                              } else {
                                _genreIds.remove(g.id);
                              }
                            }),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('Không tải được thể loại'),
          ),
          const SizedBox(height: 16),
          const Text('Chế độ tham gia'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'approval', label: Text('Cần duyệt'), icon: Icon(Icons.verified_user_outlined)),
              ButtonSegment(value: 'open', label: Text('Mở'), icon: Icon(Icons.lock_open_outlined)),
            ],
            selected: {_joinMode},
            onSelectionChanged: _submitting
                ? null
                : (s) => setState(() => _joinMode = s.first),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('create_keo_btn'),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tạo kèo'),
          ),
        ],
      ),
    );
  }
}
