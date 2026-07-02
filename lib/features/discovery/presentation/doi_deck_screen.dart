import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../application/discovery_providers.dart';
import '../domain/candidate.dart';
import 'candidate_card.dart';
import 'match_celebration.dart';

class DoiDeckScreen extends ConsumerStatefulWidget {
  const DoiDeckScreen({super.key});

  @override
  ConsumerState<DoiDeckScreen> createState() => _DoiDeckScreenState();
}

class _DoiDeckScreenState extends ConsumerState<DoiDeckScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await ref.read(locationServiceProvider).captureAndPush();
      if (ok && mounted) ref.invalidate(candidatesProvider);
    });
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
                      cardsCount: candidates.length,
                      isLoop: false,
                      numberOfCardsDisplayed: candidates.length.clamp(1, 2),
                      cardBuilder: (context, index, h, v) =>
                          CandidateCard(candidate: candidates[index]),
                      onSwipe: (previousIndex, currentIndex, direction) {
                        final dir = _directionToSwipe(direction);
                        if (dir != null) {
                          _handleSwipe(candidates[previousIndex], dir);
                        }
                        return true;
                      },
                      onEnd: () {
                        if (mounted) ref.invalidate(candidatesProvider);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không lưu được lượt vuốt. Thử lại sau.'),
              ),
            );
          }
        });
  }
}
