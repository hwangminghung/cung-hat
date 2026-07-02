import 'package:flutter/material.dart';
import '../../../shared/widgets/empty_state.dart';

/// Reusable multi-select chip grid for genres / artists / songs (bài tủ).
///
/// Controlled widget: the parent owns [selected] and must rebuild (e.g. via its
/// own setState) inside [onToggle] so the chips reflect the new selection.
class TasteChips<T> extends StatelessWidget {
  const TasteChips({
    super.key,
    required this.items,
    required this.labelOf,
    required this.idOf,
    required this.selected,
    required this.onToggle,
  });
  final List<T> items;
  final String Function(T) labelOf;
  final String Function(T) idOf;
  final Set<String> selected;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        key: Key('taste_empty'),
        icon: Icons.library_music_outlined,
        title: 'Chưa có dữ liệu gu nhạc',
        subtitle: 'Kiểm tra dữ liệu mẫu hoặc thử tải lại sau ít phút.',
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          FilterChip(
            key: Key('chip_${idOf(item)}'),
            label: Text(labelOf(item)),
            selected: selected.contains(idOf(item)),
            onSelected: (_) => onToggle(idOf(item)),
          ),
      ],
    );
  }
}
