import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../../billing/application/billing_providers.dart';
import '../../profile/application/profile_providers.dart';
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

  /// Chặn double-tap boost khi RPC activate_boost đang bay — lần 2 sẽ tiêu
  /// lượt boost thứ hai (hoặc raise boost_active) một cách vô ích.
  bool _boostInFlight = false;

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

  /// Điểm refetch DUY NHẤT: list mới → ObjectKey đổi → CardSwiper dựng lại
  /// với history rỗng, nên phải bỏ quyền rewind của deck cũ — nếu không,
  /// rewind sẽ xoá swipe phía server mà không khôi phục được card nào.
  void _refreshDeck() {
    _lastSwiped = null;
    ref.invalidate(candidatesProvider);
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
            onAction: _refreshDeck,
          ),
          data: (candidates) {
            if (candidates.isEmpty) {
              return EmptyState(
                icon: Icons.music_note_rounded,
                title: 'Chưa có bạn hát quanh đây',
                subtitle: 'Mở lại sau một chút để xem gợi ý mới.',
                actionLabel: 'Làm mới gợi ý',
                onAction: _refreshDeck,
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
                      _buildBoostButton(context),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filledTonal(
                        tooltip: 'Làm mới',
                        onPressed: _refreshDeck,
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
                      // Key theo list instance: sau khi vuốt hết deck, CardSwiper
                      // cũ giữ index đã cạn nên list mới fetch về không hiển thị —
                      // đổi key ép dựng swiper mới cho mỗi lần fetch.
                      key: ObjectKey(candidates),
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
                        if (mounted) _refreshDeck();
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

  Widget _buildBoostButton(BuildContext context) {
    final boostExpiry = ref.watch(activeBoostProvider);
    final boosting =
        boostExpiry != null && boostExpiry.isAfter(DateTime.now());
    final tooltip = boosting
        ? 'Đang boost đến ${_formatHhMm(boostExpiry)}'
        : 'Boost hồ sơ';
    return IconButton.filledTonal(
      key: const Key('deck_boost_btn'),
      tooltip: tooltip,
      onPressed: _handleBoost,
      icon: Icon(
        Icons.bolt_rounded,
        color: boosting ? AppColors.primary : null,
      ),
    );
  }

  /// HH:mm giờ địa phương — chỉ dùng cho tooltip boost. Expiry parse từ
  /// timestamptz ('...Z') nên là UTC; phải toLocal() trước khi đọc hour/minute
  /// (nếu không VN UTC+7 lệch 7 tiếng). Không cần package ngoài.
  String _formatHhMm(DateTime t) {
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _handleBoost() async {
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      ProUpsellSheet.show(context, variant: ProUpsellVariant.boost);
      return;
    }
    if (_boostInFlight) return;
    _boostInFlight = true;
    try {
      final expiry =
          await ref.read(discoveryRepositoryProvider).activateBoost();
      ref.read(activeBoostProvider.notifier).state = expiry;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Đang boost 30 phút — hồ sơ của bạn được ưu tiên quanh đây.')));
      }
    } catch (e) {
      final err = discoverySwipeError(e);
      if (err == DiscoverySwipeError.proRequired) {
        // Entitlement hết hạn phía server trong khi cache client còn Pro.
        ref.invalidate(entitlementsProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err.message)));
      }
    } finally {
      _boostInFlight = false;
    }
  }

  Future<void> _handleRewind() async {
    final isPro = ref.read(isProProvider);
    if (!isPro) {
      ProUpsellSheet.show(context, variant: ProUpsellVariant.rewind);
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

  Future<void> _handleSwipe(Candidate candidate, String dir) async {
    try {
      final isMatch = await ref
          .read(discoveryRepositoryProvider)
          .recordSwipe(candidate.id, dir);
      if ((dir == 'like' || dir == 'super') && isMatch && mounted) {
        final myName =
            ref.read(myProfileProvider).value?.displayName ?? 'Bạn';
        // Không để lỗi lấy matchId chặn màn ăn mừng — matchId null vẫn cho
        // xem MatchCelebration, chỉ là nút "Nhắn tin ngay" sẽ không điều
        // hướng được.
        String? matchId;
        try {
          matchId = await ref
              .read(discoveryRepositoryProvider)
              .getMatchIdWith(candidate.id);
        } catch (_) {
          matchId = null;
        }
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchCelebration(
              otherName: candidate.displayName ?? '',
              myName: myName,
              sharedBaitu: candidate.sharedBaitu,
              onChat: () {
                Navigator.of(context).pop();
                if (matchId != null) {
                  context.push(
                      '/chat/$matchId?name=${Uri.encodeComponent(candidate.displayName ?? '')}');
                }
              },
              onContinue: () => Navigator.of(context).pop(),
            ),
          ),
        );
      }
    } catch (e) {
      // State.mounted ≡ context.mounted cho context của chính State này.
      if (!mounted) return;
      final err = discoverySwipeError(e);
      switch (err) {
        case DiscoverySwipeError.likeLimit:
          if (!_upsellShowing) {
            _upsellShowing = true;
            ProUpsellSheet.show(context, variant: ProUpsellVariant.likeQuota)
                .whenComplete(() => _upsellShowing = false);
          }
          // Server raise like_limit/super_limit TRƯỚC khi ghi swipe, nên ta
          // BIẾT lượt vuốt chưa được lưu — hoàn card về deck để client khớp
          // với server. _lastSwiped đã bị onSwipe gán sang ứng viên bị từ chối
          // này; sau undo, history của CardSwiper rỗng nên phải null nó (như
          // _handleRewind), nếu không rewind kế tiếp sẽ gọi undo_last_swipe xoá
          // một swipe CŨ HƠN có thật trong khi deck không còn gì để khôi phục —
          // đúng cái desync mà _refreshDeck/_handleRewind cảnh báo.
          if (mounted) {
            _controller.undo();
            _lastSwiped = null;
          }
        case DiscoverySwipeError.superLimit:
          if (!_upsellShowing) {
            _upsellShowing = true;
            ProUpsellSheet.show(context, variant: ProUpsellVariant.superQuota)
                .whenComplete(() => _upsellShowing = false);
          }
          if (mounted) {
            _controller.undo();
            _lastSwiped = null;
          }
        case DiscoverySwipeError.proRequired:
        // boost* chỉ phát sinh từ activate_boost; ở đây chỉ để switch đủ nhánh.
        case DiscoverySwipeError.boostActive:
        case DiscoverySwipeError.boostLimit:
        // unknown: swipe CÓ THỂ đã được ghi — undo sẽ desync, nên chỉ báo lỗi.
        case DiscoverySwipeError.unknown:
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(err.message)));
      }
    }
  }
}
