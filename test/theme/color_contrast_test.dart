import 'dart:math' as math;

import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chốt chặn chống trôi design system.
///
/// Bối cảnh: 2026-07-25 audit phát hiện `warning` trượt 4.5:1 đúng 0.06 và
/// MASTER.md ghi sai ngưỡng cỡ chữ trên nền cam (16px thay vì 19px) — cả hai
/// đều không thể thấy bằng mắt. Test này biến mọi quyết định màu thành thứ
/// máy kiểm được, để lần sau đổi hex là biết ngay.
///
/// Quy ước ngưỡng (WCAG 2.2):
///   • 4.5:1 — chữ thường (<24px, hoặc <18.66px bold)
///   • 3.0:1 — chữ lớn (≥24px thường / ≥18.66px bold)
///   • 3.0:1 — thành phần giao diện & đồ hoạ mang thông tin (SC 1.4.11)
///
/// LƯU Ý về các fill nhạt (lime, teal, các tint): chúng KHÔNG đạt 3:1 so với
/// nền, và điều đó chấp nhận được vì hệ bắt buộc viền ink 2px — ranh giới do
/// viền gánh (ink vs nền = 10.75:1). Vì vậy test chỉ kiểm viền, không kiểm
/// fill. Widget nào KHÔNG có viền ink thì phải tự khai báo ở nhóm cuối file.
void main() {
  group('Tương phản chữ (WCAG 1.4.3 — 4.5:1)', () {
    _expectText(AppColors.ink, AppColors.background, 'ink trên nền giấy');
    _expectText(AppColors.ink, AppColors.surface, 'ink trên card');
    _expectText(
      AppColors.textSecondary,
      AppColors.background,
      'textSecondary trên nền giấy',
    );
    _expectText(
      AppColors.textSecondary,
      AppColors.surface,
      'textSecondary trên card',
    );
    _expectText(AppColors.textHint, AppColors.background, 'textHint trên nền');
    _expectText(AppColors.textHint, AppColors.surface, 'textHint trên card');

    // Chữ ink trên mọi fill có màu — đây là cách hệ dùng lime/teal/tint.
    _expectText(AppColors.ink, AppColors.secondary, 'ink trên lime');
    _expectText(AppColors.ink, AppColors.secondaryTint, 'ink trên lime nhạt');
    _expectText(AppColors.ink, AppColors.teal, 'ink trên teal');
    _expectText(AppColors.ink, AppColors.tertiaryTint, 'ink trên teal nhạt');
    _expectText(AppColors.ink, AppColors.primaryTint, 'ink trên cam nhạt');
    _expectText(AppColors.ink, AppColors.primarySoft, 'ink trên primarySoft');
    _expectText(AppColors.ink, AppColors.pink, 'ink trên pink');
    _expectText(AppColors.ink, AppColors.surfaceAlt, 'ink trên surfaceAlt');
    _expectText(AppColors.ink, AppColors.surfaceWarm, 'ink trên surfaceWarm');
    _expectText(AppColors.ink, AppColors.surfaceMuted, 'ink trên surfaceMuted');
    _expectText(AppColors.ink, AppColors.successTint, 'ink trên successTint');
    _expectText(AppColors.ink, AppColors.warningTint, 'ink trên warningTint');
    _expectText(AppColors.ink, AppColors.errorTint, 'ink trên errorTint');

    // Màu trạng thái dùng làm CHỮ trên nền giấy.
    _expectText(AppColors.success, AppColors.background, 'success làm chữ');
    _expectText(AppColors.warning, AppColors.background, 'warning làm chữ');
    _expectText(AppColors.error, AppColors.background, 'error làm chữ');
    _expectText(AppColors.error, AppColors.surface, 'error làm chữ trên card');

    // Chữ trắng trên các nền đậm.
    _expectText(Colors.white, AppColors.error, 'trắng trên error');
    _expectText(Colors.white, AppColors.success, 'trắng trên success');
    _expectText(Colors.white, AppColors.warning, 'trắng trên warning');
    _expectText(Colors.white, AppColors.primaryDark, 'trắng trên primaryDark');
    _expectText(
      Colors.white,
      AppColors.secondaryDark,
      'trắng trên secondaryDark',
    );

    // Nhãn tab active.
    _expectText(
      AppColors.primaryDark,
      AppColors.background,
      'primaryDark làm nhãn tab',
    );

    // Chữ disabled — WCAG miễn trừ control disabled, nhưng người dùng vẫn
    // cần đọc được nhãn nút. Giữ ngưỡng chữ thường.
    _expectText(
      AppColors.onDisabled,
      AppColors.surfaceMuted,
      'chữ disabled trên nền disabled',
    );
  });

  group('Tương phản chữ lớn (WCAG 1.4.3 — 3:1)', () {
    // Trắng trên cam CHỈ hợp lệ ở cỡ chữ lớn. Ràng buộc cỡ chữ nằm ở test dưới.
    _expectLarge(AppColors.onPrimary, AppColors.primary, 'trắng trên CTA cam');
  });

  test('Cỡ chữ tối thiểu trên nền cam đủ để tính là "chữ lớn"', () {
    // WCAG: bold ≥ 14pt = 18.66px. Hằng số của hệ phải ≥ ngưỡng này, nếu không
    // thì tỉ lệ 3.75:1 của trắng-trên-cam là bất hợp lệ.
    expect(
      AppColors.onPrimaryMinBoldSize,
      greaterThanOrEqualTo(18.66),
      reason:
          'Trắng trên primary chỉ đạt ${_ratio(AppColors.onPrimary, AppColors.primary).toStringAsFixed(2)}:1. '
          'Tỉ lệ này chỉ hợp lệ khi chữ là bold ≥18.66px. '
          'Hạ onPrimaryMinBoldSize xuống dưới ngưỡng này = mọi CTA trượt WCAG.',
    );
  });

  group('Thành phần giao diện (WCAG 1.4.11 — 3:1)', () {
    // Viền ink là thứ gánh ranh giới cho MỌI component có fill nhạt.
    _expectUi(AppColors.ink, AppColors.background, 'viền ink trên nền giấy');
    _expectUi(AppColors.ink, AppColors.surface, 'viền ink trên card');
    _expectUi(AppColors.ink, AppColors.secondary, 'viền ink trên lime');
    _expectUi(AppColors.ink, AppColors.teal, 'viền ink trên teal');

    // Nền nút cam vs nền giấy (nút KHÔNG chỉ dựa vào viền).
    _expectUi(AppColors.primary, AppColors.background, 'nền cam vs nền giấy');
    _expectUi(AppColors.primary, AppColors.surface, 'nền cam vs card');

    // Viền ô OTP đang active.
    _expectUi(AppColors.primary, AppColors.surface, 'viền OTP active');
  });

  group('Widget KHÔNG có viền ink — phải tự đạt 3:1', () {
    // WaveProgress vẽ thanh trần bằng CustomPainter, không có viền bao.
    // Ranh giới "đã xong / chưa xong" là thứ truyền đạt tiến độ.
    _expectUi(
      AppColors.secondaryDark,
      AppColors.surfaceMuted,
      'WaveProgress: thanh đã xong vs chưa xong',
    );
    _expectUi(
      AppColors.secondaryDark,
      AppColors.background,
      'WaveProgress: thanh đã xong vs nền',
    );
    // Track (surfaceMuted vs nền) CHỈ đạt 1.26:1 — cố ý không ép ở đây.
    // Bù bằng đường ink baseline trong wave_progress.dart; nếu bỏ baseline đi
    // thì người dùng mất tham chiếu tổng chiều dài thanh.
  });

  group('Cặp màu bị cấm — phải KHÔNG đạt (chốt để không ai dùng nhầm)', () {
    test('ink KHÔNG dùng được làm chữ trên nền cam', () {
      expect(
        _ratio(AppColors.ink, AppColors.primary),
        lessThan(4.5),
        reason:
            'Nếu cặp này đã đạt 4.5:1 thì primary đã bị đổi — hãy bỏ dòng cấm '
            'trong doc của AppColors.onPrimary và cập nhật test này.',
      );
    });

    test('primary KHÔNG dùng được làm màu chữ trên nền giấy', () {
      expect(
        _ratio(AppColors.primary, AppColors.background),
        lessThan(4.5),
        reason: 'Xem ghi chú ở AppColors.onPrimary.',
      );
    });

    test('trắng KHÔNG dùng được trên primarySoft / pink', () {
      expect(_ratio(Colors.white, AppColors.primarySoft), lessThan(4.5));
      expect(_ratio(Colors.white, AppColors.pink), lessThan(4.5));
    });
  });
}

// ─────────────────────────────── helpers ────────────────────────────────

void _expectText(Color fg, Color bg, String label) =>
    _expectRatio(fg, bg, 4.5, label, 'chữ thường');

void _expectLarge(Color fg, Color bg, String label) =>
    _expectRatio(fg, bg, 3.0, label, 'chữ lớn');

void _expectUi(Color fg, Color bg, String label) =>
    _expectRatio(fg, bg, 3.0, label, 'thành phần giao diện');

void _expectRatio(Color fg, Color bg, double min, String label, String kind) {
  test('$label ≥ $min:1', () {
    final r = _ratio(fg, bg);
    expect(
      r,
      greaterThanOrEqualTo(min),
      reason:
          '$label — ${_hex(fg)} trên ${_hex(bg)} chỉ đạt '
          '${r.toStringAsFixed(2)}:1, cần $min:1 ($kind).',
    );
  });
}

/// Tỉ lệ tương phản WCAG 2.x. Giả định màu đục (không alpha).
double _ratio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Độ sáng tương đối sRGB. Không dùng [Color.computeLuminance] để công thức
/// nằm ngay trong test — đọc là hiểu, không phải tra Flutter.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

String _hex(Color c) {
  String h(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${h(c.r)}${h(c.g)}${h(c.b)}'.toUpperCase();
}
