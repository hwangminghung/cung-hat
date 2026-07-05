import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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

const _variantData = <ProUpsellVariant, _VariantData>{
  ProUpsellVariant.boost: _VariantData(
    Icons.bolt_rounded,
    'Boost hồ sơ của bạn',
    [
      '1 lần Boost 30 phút mỗi ngày',
      'Lên đầu deck của mọi người quanh đây',
      'Kèm mọi quyền lợi Pro khác',
    ],
  ),
  ProUpsellVariant.rewind: _VariantData(
    Icons.replay_rounded,
    'Rút lại lượt vuốt',
    [
      'Lỡ tay bỏ qua? Rút lại ngay lượt gần nhất',
      'Không giới hạn số lần rút lại',
      'Kèm mọi quyền lợi Pro khác',
    ],
  ),
  ProUpsellVariant.seeLikes: _VariantData(
    Icons.favorite_rounded,
    'Xem ai đã thích bạn',
    [
      'Mở danh sách người đã thả tim bạn',
      'Match ngay không cần vuốt trúng',
      'Kèm mọi quyền lợi Pro khác',
    ],
  ),
  ProUpsellVariant.keoCreate: _VariantData(
    Icons.mic_external_on_rounded,
    'Tự tạo kèo của riêng bạn',
    [
      'Làm chủ kèo: chọn quán, giờ, thành viên',
      'Kèo mở hoặc cần duyệt — bạn quyết',
      'Kèm mọi quyền lợi Pro khác',
    ],
  ),
  ProUpsellVariant.keoJoinLimit: _VariantData(
    Icons.groups_rounded,
    'Tham gia nhiều kèo cùng lúc',
    [
      'Miễn phí chỉ được 1 kèo đang hoạt động',
      'Pro tham gia không giới hạn kèo',
      'Kèm mọi quyền lợi Pro khác',
    ],
  ),
  ProUpsellVariant.likeQuota: _VariantData(
    Icons.favorite_border_rounded,
    'Hết lượt thích hôm nay',
    [
      'Pro thích không giới hạn mỗi ngày',
      '5 Siêu thích mỗi ngày',
      'Kèm mọi quyền lợi Pro khác',
    ],
  ),
  ProUpsellVariant.superQuota: _VariantData(
    Icons.star_rounded,
    'Hết lượt Siêu thích hôm nay',
    [
      'Pro có 5 Siêu thích mỗi ngày',
      'Siêu thích giúp bạn nổi bật gấp 3 lần',
      'Kèm mọi quyền lợi Pro khác',
    ],
  ),
};

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
    final data = _variantData[variant]!;
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
                label: const Text('Nâng cấp Pro'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Để sau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
