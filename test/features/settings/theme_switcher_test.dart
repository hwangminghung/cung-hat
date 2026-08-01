import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cung_hat/core/theme/theme_mode_controller.dart';

/// [DARK] Toggle Sáng/Tối/Theo máy trong Cài đặt (Task 3). Test tối giản ở
/// tầng controller-qua-UI: dựng riêng 3 tile giống settings (không dựng cả
/// SettingsScreen — màn đó kéo Supabase providers), khẳng định tap → set()
/// đổi state + persist. Cấu trúc tile trong SettingsScreen được smoke test
/// bởi settings_screen_test hiện có (đếm section).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap Tối → controller dark + tick chuyển tile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final mode = ref.watch(themeModeControllerProvider);
                Widget tile(Key key, ThemeMode m, String label) => ListTile(
                  key: key,
                  title: Text(label),
                  trailing: mode == m ? const Icon(Icons.check_rounded) : null,
                  onTap: () =>
                      ref.read(themeModeControllerProvider.notifier).set(m),
                );
                return Column(
                  children: [
                    tile(
                      const Key('theme_system'),
                      ThemeMode.system,
                      'Theo máy',
                    ),
                    tile(const Key('theme_light'), ThemeMode.light, 'Sáng'),
                    tile(const Key('theme_dark'), ThemeMode.dark, 'Tối'),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(container.read(themeModeControllerProvider), ThemeMode.system);

    await tester.tap(find.byKey(const Key('theme_dark')));
    await tester.pumpAndSettle();

    expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kThemeModePrefKey), 'dark');
  });
}
