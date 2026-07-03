import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../../billing/application/billing_providers.dart';
import '../application/discovery_providers.dart';
import '../data/discovery_errors.dart';
import '../domain/candidate.dart';
import 'candidate_card.dart';
import 'candidate_detail_sheet.dart';
import 'deck_action_bar.dart';
import 'match_celebration.dart';
import 'swipe_overlays.dart';

class DoiDeckScreen extends ConsumerStatefulWidget {
  const DoiDeckScreen({super.key});

  @override
  ConsumerState<DoiDeckScreen> createState() => _DoiDeckScreenState();
}

class _DoiDeckScreenState extends ConsumerState<DoiDeckScreen> {
  final CardSwiperController _controller = CardSwiperController();

  /// Chặn mở trùng ProUpsellSheet khi nhiều swipe lỗi like_limit liên tiếp.
  bool _upsellShowing = false;

  /// Ứng viên vừa vuốt gần nhất, set ở mỗi swipe để rewind có thể khôi phục.
  Candidate? _lastSwiped;

  /// Chặn double-tap rewind khi RPC undo đang bay — gọi lần 2 sẽ xoá nhầm
  /// lượt vuốt CŨ HƠN phía server trong khi deck chỉ khôi phục được 1 card.
  bool _rewindInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await ref.read(locationServiceProvider).captureAndPush();
      if (ok && mounted) ref.invalidate(candidatesProvider);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _directionToSwipe(CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.right) return 'like';
    if (direction == CardSwiperDirection.top) return 'super';
    if (direction == CardSwiperDirection.left) return 'pass';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(candidatesProvider);
    return Scaffold(
      body: SafeArea(
        child: candidatesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Skeleton(
              width: double.infinity,
              height: double.infinity,
              radius: 28,
            ),
          ),
          error: (err, _) => EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Không tải được gợi ý',
            subtitle: 'Kiểm tra kết nối rồi thử lại.',
            actionLabel: 'Thử lại',
            onAction: () => ref.invalidate(candidatesProvider),
          ),
          data: (candidates) {
            if (candidates.isEmpty) {
              return EmptyState(
                icon: Icons.music_note_rounded,
                title: 'Chưa có bạn hát quanh đây',
                subtitle: 'Mở lại sau một chút để xem gợi ý mới.',
                actionLabel: 'Làm mới gợi ý',
                onAction: () => ref.invalidate(candidatesProvider),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đôi hát',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Gợi ý hợp gu nhạc và khoảng cách an toàn.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Làm mới',
                        onPressed: () => ref.invalidate(candidatesProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: CardSwiper(
                      controller: _controller,
                      cardsCount: candidates.length,
                      isLoop: false,
                      numberOfCardsDisplayed: candidates.length.clamp(1, 2),
                      maxAngle: 25,
                      threshold: 60,
                      cardBuilder: (context, index, h, v) => GestureDetector(
                        onTap: () => CandidateDetailSheet.show(
                          context,
                          candidate: candidates[index],
                          onPass: () =>
                              _controller.swipe(CardSwiperDirection.left),
                          onLike: () =>
                              _controller.swipe(CardSwiperDirection.right),
                        ),
                        child: SwipeOverlays(
                          hProgress: h / 100,
                          vProgress: v / 100,
                          child: CandidateCard(candidate: candidates[index]),
                        ),
                      ),
                      onSwipe: (previousIndex, currentIndex, direction) {
                        final dir = _directionToSwipe(direction);
                        if (dir != null) {
                          _lastSwiped = candidates[previousIndex];
                          _handleSwipe(candidates[previousIndex], dir);
                        }
                        return true;
                      },
                      onEnd: () {
                        // Refetch dựng CardSwiper mới với history rỗng —
                        // rewind lúc này sẽ xoá row server mà không khôi phục
                        // được card nào, nên bỏ quyền rewind của deck cũ.
                        _lastSwiped = null;
                        if (mounted) ref.invalidate(candidatesProvider);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: DeckActionBar(
                    rewindEnabled: ref.watch(isProProvider),
                    onRewind: _handleRewind,
                    onPass: () => _controller.swipe(CardSwiperDirection.left),
                    onSuperLike: () =>
                        _controller.swipe(CardSwiperDirection.top),
                    onLike: () => _controller.swipe(CardSwiperDirection.right),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleRewind() async {
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      ProUpsellSheet.show(context,
          title: 'Rút lại lượt vuốt?',
          subtitle: 'Thành viên Pro có thể rút lại lượt vuốt gần nhất.');
      return;
    }
    if (_lastSwiped == null) return;
    if (_rewindInFlight) return;
    _rewindInFlight = true;
    try {
      final undone =
          await ref.read(discoveryRepositoryProvider).undoLastSwipe();
      if (undone && mounted) {
        _controller.undo(); // card_swiper đưa card trước đó trở lại deck
        _lastSwiped = null;
      }
    } catch (e) {
      final err = discoverySwipeError(e);
      if (err == DiscoverySwipeError.proRequired) {
        // Entitlement hết hạn phía server trong khi cache client còn Pro —
        // làm mới để lần bấm sau đi vào nhánh upsell thay vì lặp RPC hỏng.
        ref.invalidate(entitlementsProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err.message)));
      }
    } finally {
      _rewindInFlight = false;
    }
  }

  void _handleSwipe(Candidate candidate, String dir) {
    ref
        .read(discoveryRepositoryProvider)
        .recordSwipe(candidate.id, dir)
        .then((isMatch) {
          if ((dir == 'like' || dir == 'super') && isMatch && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchCelebration(
                  otherName: candidate.displayName ?? '',
                  sharedBaitu: candidate.sharedBaitu,
                  onChat: () => Navigator.of(context).pop(),
                ),
              ),
            );
          }
        })
        .catchError((Object e) {
          // State.mounted ≡ context.mounted cho context của chính State này.
          if (!mounted) return;
          final err = discoverySwipeError(e);
          switch (err) {
            case DiscoverySwipeError.likeLimit:
              if (_upsellShowing) return;
              _upsellShowing = true;
              ProUpsellSheet.show(
                context,
                title: 'Hết lượt thích hôm nay',
                subtitle:
                    'Pro thích không giới hạn và có 5 Siêu thích mỗi ngày.',
              ).whenComplete(() => _upsellShowing = false);
            case DiscoverySwipeError.superLimit:
            case DiscoverySwipeError.proRequired:
            case DiscoverySwipeError.unknown:
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err.message)));
          }
        });
  }
}
