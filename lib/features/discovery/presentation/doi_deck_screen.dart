import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/tab_header.dart';
import '../../../shared/widgets/wave_divider.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/pro_upsell_sheet.dart';
import '../../billing/application/billing_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../application/discovery_providers.dart';
import '../application/location_service.dart';
import '../data/discovery_errors.dart';
import '../domain/candidate.dart';
import '../domain/deck_item.dart';
import '../domain/music_themes.dart';
import 'candidate_card.dart';
import 'candidate_detail_sheet.dart';
import 'deck_action_bar.dart';
import 'filter_sheet.dart';
import 'keo_promo_card.dart';
import 'location_error_state.dart';
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

  // Neo rewind KHÔNG còn là field per-State: main deck vẫn mounted dưới route
  // /explore/:genre, nên field cục bộ sẽ giữ neo cũ trong khi swipe thật mới
  // nhất phía server thuộc deck khác → dùng lastSwipeAnchorProvider (toàn cục,
  // ghi kèm genre của deck) thay thế.

  /// Chặn double-tap rewind khi RPC undo đang bay — gọi lần 2 sẽ xoá nhầm
  /// lượt vuốt CŨ HƠN phía server trong khi deck chỉ khôi phục được 1 card.
  bool _rewindInFlight = false;

  /// Chặn double-tap boost khi RPC activate_boost đang bay — lần 2 sẽ tiêu
  /// lượt boost thứ hai (hoặc raise boost_active) một cách vô ích.
  bool _boostInFlight = false;

  /// Tiến độ kéo hiện tại cho action bar. Cập nhật post-frame vì cardBuilder
  /// chạy TRONG build — notify ngay sẽ setState-during-build.
  final ValueNotifier<(double, double)> _dragProgress = ValueNotifier((
    0.0,
    0.0,
  ));

  AppLocalizations? get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  void _scheduleProgress(double h, double v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _dragProgress.value != (h, v)) {
        _dragProgress.value = (h, v);
      }
    });
  }

  /// P2: coach-mark vuốt lần đầu — cờ per-device, hiện MỘT lần khi deck có
  /// card; tắt khi tap hoặc ngay lượt vuốt đầu tiên.
  static const _coachSeenKey = 'deck_swipe_coach_seen';
  bool _showCoach = false;

  Future<void> _initCoachMark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_coachSeenKey) ?? false) return;
    } catch (_) {
      return; // không đọc được cờ → thà không hiện còn hơn hiện lặp
    }
    if (mounted) setState(() => _showCoach = true);
  }

  Future<void> _dismissCoach() async {
    if (!_showCoach) return;
    setState(() => _showCoach = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_coachSeenKey, true);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initCoachMark());
    if (widget.genre != null) return;
    // Bất biến tái dùng vị trí: deck chủ đề dùng vị trí đã đẩy từ deck chính
    // (luôn mount trước ở tab 0); server đọc vị trí LƯU TRỮ nên không cần bắt
    // lại — bắt lại mỗi lần vào vừa chậm (chờ GPS) vừa xoá cache candidates
    // của genre qua invalidate bên dưới.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await ref.read(locationServiceProvider).captureAndPush();
      if (!mounted) return;
      // Ghi NGUYÊN NHÂN (P0-1) để deck/board không đổ lỗi "hết người" khi
      // thật ra là thiếu quyền/GPS tắt/mạng lỗi.
      ref.read(locationStatusProvider.notifier).state = status;
      // P0-3: kết quả xin quyền vị trí — điểm rơi lớn nhất của funnel.
      unawaited(
        ref
            .read(analyticsProvider)
            .logLocationResult(
              granted: status != LocationCaptureStatus.permissionDenied,
            ),
      );
      if (status == LocationCaptureStatus.success) {
        ref.invalidate(candidatesProvider(widget.genre));
      }
    });
  }

  /// Chặn double-tap "Thử lại" khi capture đang bay (cùng convention
  /// _boostInFlight/_rewindInFlight).
  bool _locationRetryInFlight = false;

  Future<void> _retryLocation() async {
    if (_locationRetryInFlight) return;
    _locationRetryInFlight = true;
    try {
      final status = await ref.read(locationServiceProvider).captureAndPush();
      if (!mounted) return;
      ref.read(locationStatusProvider.notifier).state = status;
      unawaited(
        ref
            .read(analyticsProvider)
            .logLocationResult(
              granted: status != LocationCaptureStatus.permissionDenied,
            ),
      );
      if (status == LocationCaptureStatus.success) _refreshDeck();
    } finally {
      _locationRetryInFlight = false;
    }
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
  /// với history rỗng, nên phải bỏ neo rewind của deck cũ — nếu không,
  /// rewind sẽ xoá swipe phía server mà không khôi phục được card nào.
  /// (Null neo TOÀN CỤC là hướng an toàn: nếu neo đang thuộc deck khác thì
  /// deck đó chỉ mất tiện ích rewind, không bao giờ desync.)
  void _refreshDeck() {
    ref.read(lastSwipeAnchorProvider.notifier).state = null;
    ref.invalidate(candidatesProvider(widget.genre));
  }

  /// Lưu toggle "tự mở rộng" server-side. Chỉ invalidate provider khi lưu OK;
  /// lỗi (offline/RPC) thì báo SnackBar và giữ nguyên trạng thái cũ — cùng
  /// convention try/catch + mounted như _handleBoost/_handleRewind.
  Future<void> _handleToggleAutoExpand(bool on) async {
    try {
      await ref.read(discoveryRepositoryProvider).setAutoExpand(on);
      if (mounted) ref.invalidate(discoveryPrefsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n?.commonSaveError ?? 'Không lưu được cài đặt, thử lại.',
            ),
          ),
        );
      }
    }
  }

  /// Bán kính HIỆU LỰC của deck: override phiên ([deckRadiusProvider]) nếu
  /// có, nếu không thì bán kính đã lưu server; pref chưa tải xong/lỗi → mặc
  /// định 50 (không chặn UI chờ bộ lọc — cùng convention swallow-to-50 với
  /// candidatesProvider).
  int _effectiveRadius() {
    final override = ref.watch(deckRadiusProvider);
    if (override != null) return override;
    return ref.watch(discoveryPrefsProvider).value?.radiusKm ?? 50;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final itemsAsync = ref.watch(deckItemsProvider(widget.genre));
    // Vòng cuối UI review: header CỐ ĐỊNH phía trên cho MỌI trạng thái
    // (loading/error/rỗng/có card) — trước đây empty state thay cả màn làm
    // mất nhận diện + 4 action; phần dưới mới đổi theo itemsAsync.
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _buildHeader(context, l10n),
            ),
            Expanded(child: _buildDeckBody(context, l10n, itemsAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckBody(
    BuildContext context,
    AppLocalizations? l10n,
    AsyncValue<List<DeckItem>> itemsAsync,
  ) {
    return itemsAsync.when(
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
        title: l10n?.deckLoadErrorTitle ?? 'Không tải được gợi ý',
        subtitle:
            l10n?.commonCheckConnection ?? 'Kiểm tra kết nối rồi thử lại.',
        actionLabel: l10n?.commonRetry ?? 'Thử lại',
        onAction: _refreshDeck,
      ),
      data: (items) {
        final hasCandidates = items.whereType<CandidateItem>().isNotEmpty;
        if (!hasCandidates) {
          // P0-1: deck rỗng VÌ THIẾU VỊ TRÍ phải nói đúng nguyên nhân —
          // mở rộng bán kính cũng vô ích khi server không có vị trí user.
          final locStatus = ref.watch(locationStatusProvider);
          if (locStatus != null && locStatus != LocationCaptureStatus.success) {
            return LocationErrorState(
              status: locStatus,
              onRetry: _retryLocation,
              onOpenSettings: () =>
                  ref.read(locationServiceProvider).openSettingsFor(locStatus),
            );
          }
          final radius = _effectiveRadius();
          final autoExpand =
              ref.watch(discoveryPrefsProvider).value?.autoExpand ?? false;
          // Auto-expand: hiệu lực CHƯA tới 100km + rỗng + user đã bật →
          // tự lên 100km 1 lần (so hiệu lực, không so cứng == 50 — pref
          // server có thể đã lưu bán kính khác 50).
          if (radius < 100 && autoExpand) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(deckRadiusProvider.notifier).state = 100;
              }
            });
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Skeleton(
                width: double.infinity,
                height: double.infinity,
                radius: 28,
              ),
            );
          }
          return _EmptyDeck(
            radius: radius,
            autoExpand: autoExpand,
            onExpand: () => ref.read(deckRadiusProvider.notifier).state = 100,
            onToggleAutoExpand: _handleToggleAutoExpand,
            onRefresh: _refreshDeck,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Stack(
                  children: [
                    CardSwiper(
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
                                onPass: () =>
                                    _controller.swipe(CardSwiperDirection.left),
                                onLike: () => _controller.swipe(
                                  CardSwiperDirection.right,
                                ),
                              ),
                            ),
                          ),
                          KeoPromoItem(:final keo) => SwipeOverlays(
                            hProgress: h / 100,
                            vProgress: v / 100,
                            likeLabel: _l10n?.deckPromoSeeKeo ?? 'XEM KÈO',
                            showSuper: false,
                            child: KeoPromoCard(
                              key: ValueKey('keo-promo-${keo.id}'),
                              keo: keo,
                            ),
                          ),
                        };
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        _scheduleProgress(0, 0);
                        // Vuốt được rồi thì coach-mark hết nhiệm vụ.
                        if (_showCoach) unawaited(_dismissCoach());
                        final item = items[previousIndex];
                        switch (item) {
                          case CandidateItem(:final candidate):
                            final dir = _directionToSwipe(direction);
                            if (dir != null) {
                              // Neo toàn cục ghi kèm genre: rewind chỉ hợp lệ
                              // từ đúng deck sở hữu swipe thật mới nhất.
                              ref.read(lastSwipeAnchorProvider.notifier).state =
                                  (genre: widget.genre, candidate: candidate);
                              _handleSwipe(candidate, dir);
                            }
                          case KeoPromoItem(:final keo):
                            // Promo: không quota, không record_swipe, không
                            // rewind — null neo để rewind sau promo no-op
                            // thay vì undo nhầm swipe thật cũ hơn.
                            ref.read(lastSwipeAnchorProvider.notifier).state =
                                null;
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
                    if (_showCoach)
                      Positioned.fill(
                        child: GestureDetector(
                          key: const Key('swipe_coach_mark'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _dismissCoach,
                          // Scrim nhẹ để card hồ sơ vẫn thấy được; nội
                          // dung hướng dẫn nằm trong card kem tương phản
                          // cao + CTA rõ ràng (UI review: bỏ 'Tap to
                          // start' chìm).
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusCard,
                                  ),
                                  border: Border.all(
                                    color: AppColors.ink,
                                    width: 2,
                                  ),
                                  boxShadow: const [AppShadows.hard],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Icon(
                                      Icons.swipe_rounded,
                                      color: AppColors.primary,
                                      size: 40,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      _l10n?.deckCoachSwipe ??
                                          'Vuốt phải để thích\nVuốt trái để bỏ qua\nVuốt lên để Siêu thích',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppColors.ink,
                                            fontWeight: FontWeight.w800,
                                            height: 1.6,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    GradientButton(
                                      key: const Key('coach_start_btn'),
                                      onPressed: _dismissCoach,
                                      child: Text(
                                        _l10n?.deckCoachTap ?? 'Bắt đầu',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                  onSuperLike: () => _controller.swipe(CardSwiperDirection.top),
                  onLike: () => _controller.swipe(CardSwiperDirection.right),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final theme = widget.genre == null ? null : musicThemeById(widget.genre!);
    final subtitle =
        theme?.subtitle ??
        l10n?.discoveryDeckSubtitle ??
        'Gợi ý hợp gu nhạc, trong khoảng cách an toàn.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.genre != null) ...[
              HeaderActionButton(
                key: const Key('theme_deck_back'),
                tooltip: l10n?.commonBack ?? 'Quay lại',
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                widget.genre == null
                    ? l10n?.appTitle ?? 'Cùng Hát'
                    : theme?.title ??
                          (l10n?.exploreFallbackTitle ?? 'Khám Phá'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (widget.genre == null) ...[
              HeaderActionButton(
                key: const Key('filter_btn'),
                tooltip: l10n?.filterTitle ?? 'Bộ lọc',
                icon: Icons.filter_alt_outlined,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const FilterSheet(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              HeaderActionButton(
                key: const Key('explore_btn'),
                tooltip: l10n?.deckExploreTooltip ?? 'Khám Phá theo gu nhạc',
                icon: Icons.queue_music_rounded,
                onTap: () => context.push('/explore'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildBoostButton(context),
              const SizedBox(width: AppSpacing.sm),
            ],
            HeaderActionButton(
              tooltip: l10n?.deckRefreshTooltip ?? 'Làm mới',
              icon: Icons.refresh_rounded,
              onTap: _refreshDeck,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.genre == null)
          Row(
            children: [
              // flex 3:1 — title ưu tiên bề ngang (Flexible 1:1 với divider
              // từng cắt 'Ghép đôi cùn…' ngay cả ở 412dp — bug vòng cuối).
              Flexible(
                flex: 3,
                child: Text(
                  l10n?.discoveryDeckTitle ?? 'Ghép đôi cùng hát',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: WaveDivider()),
            ],
          ),
        if (widget.genre == null) const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_effectiveRadius() >= 100)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n?.deckSearching100 ?? 'Đang tìm trong 100 km',
              key: const Key('radius_chip'),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        const WaveDivider(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildBoostButton(BuildContext context) {
    final boostExpiry = ref.watch(activeBoostProvider);
    final boosting = boostExpiry != null && boostExpiry.isAfter(DateTime.now());
    final tooltip = boosting
        ? (_l10n?.deckBoostingUntil(_formatHhMm(boostExpiry)) ??
              'Đang tăng hiển thị đến ${_formatHhMm(boostExpiry)}')
        : (_l10n?.deckBoostTooltip ?? 'Tăng hiển thị hồ sơ');
    return HeaderActionButton(
      key: const Key('deck_boost_btn'),
      tooltip: tooltip,
      onTap: _handleBoost,
      icon: Icons.bolt_rounded,
      active: boosting,
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
      final expiry = await ref
          .read(discoveryRepositoryProvider)
          .activateBoost();
      ref.read(activeBoostProvider.notifier).state = expiry;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n?.deckBoostStarted ??
                  'Đang tăng hiển thị 30 phút — hồ sơ của bạn được ưu tiên quanh đây.',
            ),
          ),
        );
      }
    } catch (e) {
      final err = discoverySwipeError(e);
      if (err == DiscoverySwipeError.proRequired) {
        // Entitlement hết hạn phía server trong khi cache client còn Pro.
        ref.invalidate(entitlementsProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err.localizedMessage(_l10n))));
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
    // Bất biến xuyên deck: undo_last_swipe phía server xoá swipe MỚI NHẤT
    // toàn cục (bất kể deck), nên chỉ được rewind khi neo thuộc ĐÚNG deck
    // này. Neo null hoặc thuộc deck khác (vd: vuốt trên main deck rồi sang
    // /explore/ballad vuốt tiếp, quay lại main bấm rewind) → no-op im lặng;
    // nếu cứ undo, server xoá swipe của deck kia trong khi UI deck này khôi
    // phục nhầm card của mình — silent desync.
    final anchor = ref.read(lastSwipeAnchorProvider);
    if (anchor == null || anchor.genre != widget.genre) return;
    if (_rewindInFlight) return;
    _rewindInFlight = true;
    try {
      final undone = await ref
          .read(discoveryRepositoryProvider)
          .undoLastSwipe();
      if (undone && mounted) {
        _controller.undo(); // card_swiper đưa card trước đó trở lại deck
        ref.read(lastSwipeAnchorProvider.notifier).state = null;
      }
    } catch (e) {
      final err = discoverySwipeError(e);
      if (err == DiscoverySwipeError.proRequired) {
        // Entitlement hết hạn phía server trong khi cache client còn Pro —
        // làm mới để lần bấm sau đi vào nhánh upsell thay vì lặp RPC hỏng.
        ref.invalidate(entitlementsProvider);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err.localizedMessage(_l10n))));
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
      if (mounted) {
        // P0-3: TTFV — chỉ log sau khi server ĐÃ ghi lượt vuốt (quota reject
        // raise trước khi ghi nên không tính là "đã vuốt").
        unawaited(ref.read(analyticsProvider).logFirstSwipe());
        if (isMatch) unawaited(ref.read(analyticsProvider).logMatch());
      }
      if ((dir == 'like' || dir == 'super') && isMatch && mounted) {
        final myName =
            ref.read(myProfileProvider).value?.displayName ??
            (_l10n?.celebrateYouFallback ?? 'Bạn');
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
                    '/chat/$matchId?name=${Uri.encodeComponent(candidate.displayName ?? '')}',
                  );
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
            ProUpsellSheet.show(
              context,
              variant: ProUpsellVariant.likeQuota,
            ).whenComplete(() => _upsellShowing = false);
          }
          // Server raise like_limit/super_limit TRƯỚC khi ghi swipe, nên ta
          // BIẾT lượt vuốt chưa được lưu — hoàn card về deck để client khớp
          // với server. Neo rewind đã bị onSwipe gán sang ứng viên bị từ chối
          // này; sau undo, history của CardSwiper rỗng nên phải null nó (như
          // _handleRewind), nếu không rewind kế tiếp sẽ gọi undo_last_swipe xoá
          // một swipe CŨ HƠN có thật trong khi deck không còn gì để khôi phục —
          // đúng cái desync mà _refreshDeck/_handleRewind cảnh báo.
          if (mounted) {
            _controller.undo();
            ref.read(lastSwipeAnchorProvider.notifier).state = null;
          }
        case DiscoverySwipeError.superLimit:
          if (!_upsellShowing) {
            _upsellShowing = true;
            ProUpsellSheet.show(
              context,
              variant: ProUpsellVariant.superQuota,
            ).whenComplete(() => _upsellShowing = false);
          }
          if (mounted) {
            _controller.undo();
            ref.read(lastSwipeAnchorProvider.notifier).state = null;
          }
        case DiscoverySwipeError.proRequired:
        // boost* chỉ phát sinh từ activate_boost; ở đây chỉ để switch đủ nhánh.
        case DiscoverySwipeError.boostActive:
        case DiscoverySwipeError.boostLimit:
        // unknown: swipe CÓ THỂ đã được ghi — undo sẽ desync, nên chỉ báo lỗi.
        case DiscoverySwipeError.unknown:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err.localizedMessage(_l10n))));
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    // Vòng cuối UI review: header giờ chiếm chỗ cố định phía trên nên vùng
    // này hẹp lại — Center + scroll để màn thấp/text scale lớn cuộn được
    // thay vì RenderFlex overflow (bắt @360dp ×1.2).
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.music_note_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              radius >= 100
                  ? (l10n?.deckExhausted100 ?? 'Đã tìm hết trong 100 km')
                  : (l10n?.deckEmptyNearby ?? 'Chưa có bạn hát quanh đây'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (radius < 100)
              FilledButton.icon(
                key: const Key('expand_radius_btn'),
                onPressed: onExpand,
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(l10n?.deckExpand100 ?? 'Mở rộng tìm quanh 100 km'),
              )
            else
              OutlinedButton.icon(
                key: const Key('deck_retry_btn'),
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l10n?.deckRefreshSuggestions ?? 'Làm mới gợi ý'),
              ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              key: const Key('auto_expand_switch'),
              title: Text(
                l10n?.deckAutoExpandTitle ?? 'Tự mở rộng khi hết người',
              ),
              subtitle: Text(
                l10n?.deckAutoExpandSub ??
                    'Tự động tìm quanh 100 km khi 50 km đã hết',
              ),
              value: autoExpand,
              onChanged: onToggleAutoExpand,
            ),
          ],
        ),
      ),
    );
  }
}
