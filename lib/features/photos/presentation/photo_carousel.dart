import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../application/photo_providers.dart';

/// Ảnh hồ sơ của [userId] dạng carousel (dùng chung cho card lẫn detail sheet).
///
/// - `loading` / rỗng / lỗi → nền gradient + chữ cái đầu (monogram). Không có
///   spinner: mỗi card trong deck sẽ nháy spinner nếu có.
/// - `N ≥ 1` ảnh → [PageView] N trang + N chấm chỉ số. Khi [swipeable] = false
///   (card), PageView khoá cuộn (NeverScrollableScrollPhysics, để không đụng
///   gesture kéo của CardSwiper) nhưng có 2 vùng tap trái/phải để chuyển
///   trang; [onPageChanged] báo trang hiện tại lên cha (card dùng để xoay
///   chip thông tin theo ảnh). Khi [swipeable] = true (detail sheet), cuộn
///   PageView bình thường, không có vùng tap.
class PhotoCarousel extends ConsumerWidget {
  const PhotoCarousel({
    super.key,
    required this.userId,
    required this.monogram,
    this.radius,
    this.swipeable = true,
    this.fallbackDecorations = const [],
    this.onPageChanged,
  });

  final String userId;
  final String monogram;
  final BorderRadius? radius;

  /// true = detail sheet (PageView cuộn được); false = card (tap trái/phải).
  final bool swipeable;

  /// Widget trang trí chỉ hiện trong fallback KHÔNG-ẢNH (card truyền 2 blob).
  final List<Widget> fallbackDecorations;

  /// Báo trang hiện tại (0-based) mỗi khi đổi trang, dù bằng cuộn hay tap.
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(signedUrlsProvider(userId));
    final urls = async.asData?.value ?? const <String>[];

    if (urls.isEmpty) {
      return _fallback(
        monogram: monogram,
        decorations: fallbackDecorations,
        radius: radius,
      );
    }

    final pager = _Pager(
      urls: urls,
      monogram: monogram,
      swipeable: swipeable,
      onPageChanged: onPageChanged,
    );
    return radius == null
        ? pager
        : ClipRRect(borderRadius: radius!, child: pager);
  }
}

/// Nền gradient + monogram — dùng cho fallback và cho [Image.errorBuilder].
Widget _fallback({
  required String monogram,
  List<Widget> decorations = const [],
  BorderRadius? radius,
}) {
  final content = Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
      ),
      ...decorations,
      Center(
        child: Text(
          monogram,
          style: AppTypography.display(
            fontSize: 104,
            fontWeight: FontWeight.w800,
            color: AppColors.onPrimary.withValues(alpha: 0.92),
          ),
        ),
      ),
    ],
  );
  return radius == null
      ? content
      : ClipRRect(borderRadius: radius, child: content);
}

/// Trang ảnh + chấm chỉ số. Giữ [PageController] + trang hiện tại để tô đậm chấm.
class _Pager extends StatefulWidget {
  const _Pager({
    required this.urls,
    required this.monogram,
    required this.swipeable,
    this.onPageChanged,
  });

  final List<String> urls;
  final String monogram;
  final bool swipeable;
  final ValueChanged<int>? onPageChanged;

  @override
  State<_Pager> createState() => _PagerState();
}

class _PagerState extends State<_Pager> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_current + delta).clamp(0, widget.urls.length - 1);
    if (next == _current) return;
    _controller.jumpToPage(next);
    setState(() => _current = next);
    widget.onPageChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          physics: widget.swipeable
              ? null
              : const NeverScrollableScrollPhysics(),
          onPageChanged: (i) {
            if (widget.swipeable) setState(() => _current = i);
            widget.onPageChanged?.call(i);
          },
          itemCount: widget.urls.length,
          itemBuilder: (_, i) => Image.network(
            widget.urls[i],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                _fallback(monogram: widget.monogram),
          ),
        ),
        if (widget.urls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.md,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.urls.length; i++)
                  PhotoDot(active: i == _current),
              ],
            ),
          ),
        if (!widget.swipeable)
          Positioned.fill(
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  key: const Key('photo_tap_left'),
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _go(-1),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  key: const Key('photo_tap_right'),
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _go(1),
                ),
              ),
            ]),
          ),
      ],
    );
  }
}

/// Một chấm chỉ số trang; chấm đang xem to/đậm hơn. Công khai để test đếm.
class PhotoDot extends StatelessWidget {
  const PhotoDot({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: active ? 0.95 : 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
    );
  }
}
