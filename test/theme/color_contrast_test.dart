import 'dart:math' as math;

import 'package:cung_hat/core/theme/app_colors.dart';
import 'package:cung_hat/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chốt chặn chống trôi design system — TỪ 2026-08-01 CHO CẢ HAI BẢNG MÀU.
///
/// Bối cảnh: 2026-07-25 audit phát hiện `warning` trượt 4.5:1 đúng 0.06 và
/// MASTER.md ghi sai ngưỡng cỡ chữ trên nền cam — cả hai đều không thấy bằng
/// mắt. Test này biến mọi quyết định màu thành thứ máy kiểm được.
///
/// Quy ước ngưỡng (WCAG 2.2):
///   • 4.5:1 — chữ thường  • 3.0:1 — chữ lớn / thành phần giao diện (1.4.11)
///
/// CẤU TRÚC theo mode:
///   • Ma trận CHUNG — các cặp vai trò đúng ở cả light lẫn dark (ink trên
///     mọi surface/tint, accent làm chữ, v.v.).
///   • Cặp RIÊNG light — các cặp vật lý không thể giữ ở dark (chữ trắng trên
///     accent đậm: dark đảo vai trò accent thành sáng).
///   • Cặp MODE-INDEPENDENT — fill accent giữ nguyên hex hai mode, chữ trên
///     chúng là [AppColors.onAccent] (ink light cố định).
///
/// Fill nhạt không đạt 3:1 so với nền vẫn chấp nhận được vì hệ bắt buộc viền
/// ink 2px — viền gánh ranh giới (cả hai mode ink-vs-nền đều >10:1).
void main() {
  for (final (mode, p) in [
    ('light', AppPalette.light),
    ('dark', AppPalette.dark),
  ]) {
    group('[$mode] Tương phản chữ (4.5:1)', () {
      _expectText(p.ink, p.background, 'ink trên nền');
      _expectText(p.ink, p.surface, 'ink trên card');
      _expectText(p.textSecondary, p.background, 'textSecondary trên nền');
      _expectText(p.textSecondary, p.surface, 'textSecondary trên card');
      _expectText(p.textHint, p.background, 'textHint trên nền');
      _expectText(p.textHint, p.surface, 'textHint trên card');

      // Ink trên mọi tint: light = ink đậm/tint nhạt, dark = ink kem/tint tối
      // — cặp vai trò này sống ở CẢ hai mode nhờ tint đổi chiều cùng nền.
      _expectText(p.ink, p.secondaryTint, 'ink trên lime tint');
      _expectText(p.ink, p.tertiaryTint, 'ink trên teal tint');
      _expectText(p.ink, p.primaryTint, 'ink trên cam tint');
      _expectText(p.ink, p.surfaceAlt, 'ink trên surfaceAlt');
      _expectText(p.ink, p.surfaceWarm, 'ink trên surfaceWarm');
      _expectText(p.ink, p.surfaceMuted, 'ink trên surfaceMuted (disabled)');
      _expectText(p.ink, p.successTint, 'ink trên successTint');
      _expectText(p.ink, p.warningTint, 'ink trên warningTint');
      _expectText(p.ink, p.errorTint, 'ink trên errorTint');

      // Accent đậm/sáng làm CHỮ trên nền + trên tint cùng họ.
      _expectText(p.primaryDark, p.background, 'primaryDark làm chữ trên nền');
      _expectText(p.primaryDark, p.primaryTint, 'primaryDark trên cam tint');
      _expectText(
        p.secondaryDark,
        p.background,
        'secondaryDark làm chữ trên nền',
      );
      _expectText(
        p.secondaryDark,
        p.secondaryTint,
        'secondaryDark trên lime tint',
      );

      // Màu trạng thái làm chữ.
      _expectText(p.success, p.background, 'success làm chữ');
      _expectText(p.warning, p.background, 'warning làm chữ');
      _expectText(p.error, p.background, 'error làm chữ');
      _expectText(p.error, p.surface, 'error làm chữ trên card');
    });

    group('[$mode] Chữ lớn (3:1)', () {
      // Trắng trên cam 3.75:1 — CHỈ hợp lệ ở cỡ ≥19px bold, cả hai mode.
      _expectLarge(p.onPrimary, p.primary, 'trắng trên CTA cam');
    });

    group('[$mode] Thành phần giao diện (3:1)', () {
      _expectUi(p.ink, p.background, 'viền ink trên nền');
      _expectUi(p.ink, p.surface, 'viền ink trên card');
      _expectUi(p.primary, p.background, 'nền cam vs nền');
      _expectUi(p.primary, p.surface, 'nền cam vs card / viền OTP active');
      // WaveProgress vẽ trần không viền — tự đạt 3:1.
      _expectUi(
        p.secondaryDark,
        p.surfaceMuted,
        'WaveProgress: thanh đã xong vs chưa xong',
      );
      _expectUi(
        p.secondaryDark,
        p.background,
        'WaveProgress: thanh đã xong vs nền',
      );
    });

    group('[$mode] Cặp cấm — phải KHÔNG đạt', () {
      test('ink KHÔNG dùng được làm chữ trên nền cam', () {
        expect(_ratio(p.ink, p.primary), lessThan(4.5));
      });
      test('primary KHÔNG dùng được làm màu chữ nhỏ trên nền', () {
        expect(_ratio(p.primary, p.background), lessThan(4.5));
      });
    });
  }

  group('Fill accent (hex chung hai mode) + onAccent', () {
    // Fill sáng giữ nguyên hex ở cả hai bảng — khoá để không lệch nhau.
    for (final pick in [
      ('secondary', AppPalette.light.secondary, AppPalette.dark.secondary),
      ('teal', AppPalette.light.teal, AppPalette.dark.teal),
      ('pink', AppPalette.light.pink, AppPalette.dark.pink),
      (
        'primarySoft',
        AppPalette.light.primarySoft,
        AppPalette.dark.primarySoft,
      ),
      ('primary', AppPalette.light.primary, AppPalette.dark.primary),
      ('onPrimary', AppPalette.light.onPrimary, AppPalette.dark.onPrimary),
    ]) {
      test('${pick.$1} giống nhau ở hai bảng', () {
        expect(pick.$2, pick.$3);
      });
    }

    // Chữ trên fill accent sáng dùng onAccent (ink light cố định).
    final onAccent = AppPalette.light.ink;
    _expectText(onAccent, AppPalette.light.secondary, 'onAccent trên lime');
    _expectText(onAccent, AppPalette.light.teal, 'onAccent trên teal');
    _expectText(onAccent, AppPalette.light.pink, 'onAccent trên pink');
    _expectText(
      onAccent,
      AppPalette.light.primarySoft,
      'onAccent trên primarySoft',
    );
  });

  group('Cặp chỉ có ở LIGHT (dark đảo vai trò accent thành sáng)', () {
    final p = AppPalette.light;
    _expectText(p.onPrimary, p.error, 'trắng trên error');
    _expectText(p.onPrimary, p.success, 'trắng trên success');
    _expectText(p.onPrimary, p.warning, 'trắng trên warning');
    _expectText(p.onPrimary, p.primaryDark, 'trắng trên primaryDark');
    _expectText(p.onPrimary, p.secondaryDark, 'trắng trên secondaryDark');
    test('trắng KHÔNG dùng được trên primarySoft / pink', () {
      expect(_ratio(Colors.white, p.primarySoft), lessThan(4.5));
      expect(_ratio(Colors.white, p.pink), lessThan(4.5));
    });
  });

  test('Cỡ chữ tối thiểu trên nền cam đủ để tính là "chữ lớn"', () {
    expect(
      AppColors.onPrimaryMinBoldSize,
      greaterThanOrEqualTo(18.66),
      reason:
          'Trắng trên primary chỉ đạt '
          '${_ratio(AppPalette.light.onPrimary, AppPalette.light.primary).toStringAsFixed(2)}:1. '
          'Tỉ lệ này chỉ hợp lệ khi chữ là bold ≥18.66px. '
          'Hạ onPrimaryMinBoldSize xuống dưới ngưỡng này = mọi CTA trượt WCAG.',
    );
  });

  test('AppColors.select đổi bảng và mặc định là light', () {
    expect(AppColors.background, AppPalette.light.background);
    AppColors.select(Brightness.dark);
    addTearDown(() => AppColors.select(Brightness.light));
    expect(AppColors.background, AppPalette.dark.background);
    expect(
      AppColors.onAccent,
      AppPalette.light.ink,
      reason: 'onAccent cố định theo bảng light ở mọi mode',
    );
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
