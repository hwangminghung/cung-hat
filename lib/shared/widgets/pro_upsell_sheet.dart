import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Paywall theo ngữ cảnh: mỗi tính năng bị chặn mở đúng biến thể của nó
/// (học Tinder — headline khớp tính năng vừa bấm). KHÔNG hiện số giá ở đây:
/// giá thuộc /store (nhánh pricing riêng đang xây catalog server-side).
enum ProUpsellVariant {
  boost,
  rewind,
  seeLikes,
  keoCreate,
  keoJoinLimit,
  likeQuota,
  superQuota,
}

class _VariantData {
  const _VariantData(this.icon, this.headline, this.bullets);
  final IconData icon;
  final String headline;
  final List<String> bullets;
}

/// [L10N] Copy theo variant qua l10n (fallback VI khi test pump không
/// delegates); icon giữ trong switch để 1 nguồn sự thật cho từng variant.
_VariantData _dataFor(ProUpsellVariant variant, AppLocalizations? l) {
  final perks = l?.upsellAllProPerks ?? 'Kèm mọi quyền lợi Pro khác';
  switch (variant) {
    case ProUpsellVariant.boost:
      return _VariantData(
        Icons.bolt_rounded,
        l?.upsellBoostTitle ?? 'Boost hồ sơ của bạn',
        [
          l?.upsellBoostB1 ?? '1 lần Boost 30 phút mỗi ngày',
          l?.upsellBoostB2 ?? 'Lên đầu deck của mọi người quanh đây',
          perks,
        ],
      );
    case ProUpsellVariant.rewind:
      return _VariantData(
        Icons.replay_rounded,
        l?.upsellRewindTitle ?? 'Rút lại lượt vuốt',
        [
          l?.upsellRewindB1 ?? 'Lỡ tay bỏ qua? Rút lại ngay lượt gần nhất',
          l?.upsellRewindB2 ?? 'Không giới hạn số lần rút lại',
          perks,
        ],
      );
    case ProUpsellVariant.seeLikes:
      return _VariantData(
        Icons.favorite_rounded,
        l?.upsellSeeLikesTitle ?? 'Xem ai đã thích bạn',
        [
          l?.upsellSeeLikesB1 ?? 'Mở danh sách người đã thả tim bạn',
          l?.upsellSeeLikesB2 ?? 'Match ngay không cần vuốt trúng',
          perks,
        ],
      );
    case ProUpsellVariant.keoCreate:
      return _VariantData(
        Icons.mic_external_on_rounded,
        l?.upsellKeoCreateTitle ?? 'Tự tạo kèo của riêng bạn',
        [
          l?.upsellKeoCreateB1 ?? 'Làm chủ kèo: chọn quán, giờ, thành viên',
          l?.upsellKeoCreateB2 ?? 'Kèo mở hoặc cần duyệt — bạn quyết',
          perks,
        ],
      );
    case ProUpsellVariant.keoJoinLimit:
      return _VariantData(
        Icons.groups_rounded,
        l?.upsellKeoJoinTitle ?? 'Tham gia nhiều kèo cùng lúc',
        [
          l?.upsellKeoJoinB1 ?? 'Miễn phí chỉ được 1 kèo đang hoạt động',
          l?.upsellKeoJoinB2 ?? 'Pro tham gia không giới hạn kèo',
          perks,
        ],
      );
    case ProUpsellVariant.likeQuota:
      return _VariantData(
        Icons.favorite_border_rounded,
        l?.upsellLikeQuotaTitle ?? 'Hết lượt thích hôm nay',
        [
          l?.upsellLikeQuotaB1 ?? 'Pro thích không giới hạn mỗi ngày',
          l?.upsellLikeQuotaB2 ?? '5 Siêu thích mỗi ngày',
          perks,
        ],
      );
    case ProUpsellVariant.superQuota:
      return _VariantData(
        Icons.star_rounded,
        l?.upsellSuperQuotaTitle ?? 'Hết lượt Siêu thích hôm nay',
        [
          l?.upsellSuperQuotaB1 ?? 'Pro có 5 Siêu thích mỗi ngày',
          l?.upsellSuperQuotaB2 ?? 'Siêu thích giúp bạn nổi bật gấp 3 lần',
          perks,
        ],
      );
  }
}

/// Bottom sheet mời nâng cấp Pro — dùng chung cho mọi gate ở Kèo và Đôi.
class ProUpsellSheet extends StatelessWidget {
  const ProUpsellSheet({super.key, required this.variant});

  final ProUpsellVariant variant;

  static Future<void> show(
    BuildContext context, {
    required ProUpsellVariant variant,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => ProUpsellSheet(variant: variant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final data = _dataFor(variant, l10n);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(data.icon, color: AppColors.primaryDark, size: 30),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                data.headline,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final bullet in data.bullets)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          bullet,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const Key('upsell_cta_btn'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/store');
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(l10n?.upsellCta ?? 'Nâng cấp Pro'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.upsellLater ?? 'Để sau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
