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
import '../domain/deck_item.dart';
import '../domain/music_themes.dart';
import 'candidate_card.dart';
import 'candidate_detail_sheet.dart';
import 'deck_action_bar.dart';
import 'keo_promo_card.dart';
import 'match_celebration.dart';
import 'swipe_overlays.dart';

class DoiDeckScreen extends ConsumerStatefulWidget {
  const DoiDeckScreen({super.key, this.genre});

  /// null = deck chính (Đôi hát, tab 0 home shell); khác null = deck chủ đề
  /// Khám Phá theo gu nhạc (mục 9 Tinder-parity), lọc theo genreId này.
  final String? genre;

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

  /// Tiến độ kéo hiện tại cho action bar. Cập nhật post-frame vì cardBuilder
  /// chạy TRONG build — notify ngay sẽ setState-during-build.
  final ValueNotifier<(double, double)> _dragProgress =
      ValueNotifier((0.0, 0.0));

  void _scheduleProgress(double h, double v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _dragProgress.value != (h, v)) {
        _dragProgress.value = (h, v);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Deck chủ đề (genre != null) cũng cần vị trí — giữ capture cho cả 2 chế độ.
      final ok = await ref.read(locationServiceProvider).captureAndPush();
      if (ok && mounted) ref.invalidate(candidatesProvider(widget.genre));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dragProgress.dispose();
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
    ref.invalidate(candidatesProvider(widget.genre));
  }

  /// Lưu toggle "tự mở rộng" server-side. Chỉ invalidate provider khi lưu OK;
  /// lỗi (offline/RPC) thì báo SnackBar và giữ nguyên trạng thái cũ — cùng
  /// convention try/catch + mounted như _handleBoost/_handleRewind.
  Future<void> _handleToggleAutoExpand(bool on) async {
    try {
      await ref.read(discoveryRepositoryProvider).setAutoExpand(on);
      if (mounted) ref.invalidate(autoExpandProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không lưu được cài đặt, thử lại.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(deckItemsProvider(widget.genre));
    return Scaffold(
      body: SafeArea(
        child: itemsAsync.when(
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
          data: (items) {
            final hasCandidates =
                items.whereType<CandidateItem>().isNotEmpty;
            if (!hasCandidates) {
              final radius = ref.watch(deckRadiusProvider);
              final autoExpand = ref.watch(autoExpandProvider).value ?? false;
              // Auto-expand: 50km rỗng + user đã bật → tự lên 100km 1 lần.
              if (radius == 50 && autoExpand) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ref.read(deckRadiusProvider.notifier).state = 100;
                  }
                });
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Skeleton(
                      width: double.infinity, height: double.infinity, radius: 28),
                );
              }
              return _EmptyDeck(
                radius: radius,
                autoExpand: autoExpand,
                onExpand: () =>
                    ref.read(deckRadiusProvider.notifier).state = 100,
                onToggleAutoExpand: _handleToggleAutoExpand,
                onRefresh: _refreshDeck,
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
                      if (widget.genre != null)
                        IconButton(
                          key: const Key('theme_deck_back'),
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.genre == null
                                  ? 'Đôi hát'
                                  : (musicThemeById(widget.genre!)?.title ??
                                      'Khám Phá'),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              widget.genre == null
                                  ? 'Gợi ý hợp gu nhạc và khoảng cách an toàn.'
                                  : (musicThemeById(widget.genre!)?.subtitle ??
                                      'Gợi ý hợp gu nhạc và khoảng cách an toàn.'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            if (ref.watch(deckRadiusProvider) == 100)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text('Đang tìm trong 100 km',
                                    key: const Key('radius_chip'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: AppColors.primaryDark)),
                              ),
                          ],
                        ),
                      ),
                      if (widget.genre == null) ...[
                        IconButton.filledTonal(
                          key: const Key('explore_btn'),
                          tooltip: 'Khám Phá theo gu nhạc',
                          onPressed: () => context.push('/explore'),
                          icon: const Icon(Icons.explore_rounded),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildBoostButton(context),
                        const SizedBox(width: AppSpacing.xs),
                      ],
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
                      key: ObjectKey(items),
                      controller: _controller,
                      cardsCount: items.length,
                      isLoop: false,
                      numberOfCardsDisplayed: items.length.clamp(1, 2),
                      maxAngle: 25,
                      threshold: 60,
                      cardBuilder: (context, index, h, v) {
                        _scheduleProgress(h / 100, v / 100);
                        final item = items[index];
                        return switch (item) {
                          CandidateItem(:final candidate) => SwipeOverlays(
                              hProgress: h / 100,
                              vProgress: v / 100,
                              child: CandidateCard(
                                // CardSwiper dựng card theo vị trí — không
                                // key thì State (chỉ số ảnh) bị tái dụng cho
                                // ứng viên khác khi deck tiến lên.
                                key: ValueKey(candidate.id),
                                candidate: candidate,
                                onOpenDetail: () => CandidateDetailSheet.show(
                                  context,
                                  candidate: candidate,
                                  onPass: () => _controller
                                      .swipe(CardSwiperDirection.left),
                                  onLike: () => _controller
                                      .swipe(CardSwiperDirection.right),
                                ),
                              ),
                            ),
                          KeoPromoItem(:final keo) => SwipeOverlays(
                              hProgress: h / 100,
                              vProgress: v / 100,
                              likeLabel: 'XEM KÈO',
                              showSuper: false,
                              child: KeoPromoCard(
                                  key: ValueKey('keo-promo-${keo.id}'),
                                  keo: keo),
                            ),
                        };
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        _scheduleProgress(0, 0);
                        final item = items[previousIndex];
                        switch (item) {
                          case CandidateItem(:final candidate):
                            final dir = _directionToSwipe(direction);
                            if (dir != null) {
                              _lastSwiped = candidate;
                              _handleSwipe(candidate, dir);
                            }
                          case KeoPromoItem(:final keo):
                            // Promo: không quota, không record_swipe, không
                            // rewind — null _lastSwiped để rewind sau promo
                            // no-op thay vì undo nhầm swipe thật cũ hơn.
                            _lastSwiped = null;
                            if (direction == CardSwiperDirection.right) {
                              context.push('/keo/${keo.id}');
                            }
                        }
                        return true;
                      },
                      onEnd: () {
                        _scheduleProgress(0, 0);
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
                  child: ValueListenableBuilder<(double, double)>(
                    valueListenable: _dragProgress,
                    builder: (context, prog, _) => DeckActionBar(
                      rewindEnabled: ref.watch(isProProvider),
                      hProgress: prog.$1,
                      vProgress: prog.$2,
                      onRewind: _handleRewind,
                      onPass: () => _controller.swipe(CardSwiperDirection.left),
                      onSuperLike: () =>
                          _controller.swipe(CardSwiperDirection.top),
                      onLike: () => _controller.swipe(CardSwiperDirection.right),
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

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({
    required this.radius,
    required this.autoExpand,
    required this.onExpand,
    required this.onToggleAutoExpand,
    required this.onRefresh,
  });

  final int radius;
  final bool autoExpand;
  final VoidCallback onExpand;
  final ValueChanged<bool> onToggleAutoExpand;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.music_note_rounded,
              size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            radius >= 100
                ? 'Đã tìm hết trong 100 km'
                : 'Chưa có bạn hát quanh đây',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (radius < 100)
            FilledButton.icon(
              key: const Key('expand_radius_btn'),
              onPressed: onExpand,
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Mở rộng tìm quanh 100 km'),
            )
          else
            OutlinedButton.icon(
              key: const Key('deck_retry_btn'),
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới gợi ý'),
            ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            key: const Key('auto_expand_switch'),
            title: const Text('Tự mở rộng khi hết người'),
            subtitle: const Text('Tự động tìm quanh 100 km khi 50 km đã hết'),
            value: autoExpand,
            onChanged: onToggleAutoExpand,
          ),
        ],
      ),
    );
  }
}
