import 'package:flutter/material.dart';

/// Reusable multi-select chip grid for genres / artists / songs (bài tủ).
class TasteChips extends StatefulWidget {
  const TasteChips({
    super.key,
    required this.items,
    required this.labelOf,
    required this.idOf,
    required this.selected,
    required this.onToggle,
  });
  final List<Object> items;
  final String Function(Object) labelOf;
  final String Function(Object) idOf;
  final Set<String> selected;
  final void Function(String id) onToggle;

  @override
  State<TasteChips> createState() => _TasteChipsState();
}

class _TasteChipsState extends State<TasteChips> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        for (final item in widget.items)
          FilterChip(
            label: Text(widget.labelOf(item)),
            selected: widget.selected.contains(widget.idOf(item)),
            onSelected: (_) {
              widget.onToggle(widget.idOf(item));
              setState(() {});
            },
          ),
      ],
    );
  }
}
