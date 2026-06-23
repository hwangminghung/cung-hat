import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Maps a card swipe direction to a swipe action recorded server-side.
  /// Returns null for directions we ignore (e.g. bottom).
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Không tải được. $err')),
          data: (candidates) {
            if (candidates.isEmpty) {
              return const Center(child: Text('Hết người quanh đây 👀'));
            }
            return Padding(
              padding: const EdgeInsets.all(16),
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
            );
          },
        ),
      ),
    );
  }

  /// Records the swipe and, for like/super, shows the match celebration on a
  /// mutual match. Called (not awaited) from the synchronous onSwipe callback.
  void _handleSwipe(Candidate candidate, String dir) {
    ref.read(discoveryRepositoryProvider).recordSwipe(candidate.id, dir).then((isMatch) {
      if ((dir == 'like' || dir == 'super') && isMatch && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchCelebration(
              otherName: candidate.displayName ?? '',
              sharedBaitu: candidate.sharedBaitu,
              // TODO(P2): open chat thread
              onChat: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    }).catchError((Object e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lưu được lượt vuốt. Thử lại sau.')),
        );
      }
    });
  }
}
