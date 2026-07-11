import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.sm;
        final tileWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - spacing) / 2
            : null;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    boxShadow: const [AppShadows.hard],
                  ),
                  child: FilterChip(
                    key: Key('chip_${idOf(item)}'),
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(labelOf(item)),
                    ),
                    selected: selected.contains(idOf(item)),
                    showCheckmark: true,
                    checkmarkColor: AppColors.secondary,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.ink, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusCard,
                      ),
                    ),
                    labelStyle: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(
                          color: selected.contains(idOf(item))
                              ? AppColors.surface
                              : AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    elevation: 0,
                    pressElevation: 0,
                    onSelected: (_) => onToggle(idOf(item)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
