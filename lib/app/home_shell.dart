import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/push/push_primer.dart';
import '../l10n/app_localizations.dart';
import '../features/chat/application/inbox_providers.dart';
import '../features/profile/application/profile_providers.dart';
import '../features/chat/presentation/inbox_screen.dart';
import '../features/discovery/presentation/doi_deck_screen.dart';
import '../features/keo/presentation/keo_board_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  /// [PRIMER — đợt 4] Sheet giải thích thông báo chỉ hiện MỘT lần mỗi vòng
  /// đời màn hình; pref 'push_primer_choice' giữ nó im qua các phiên sau.
  bool _primerShown = false;

  void _maybeShowPushPrimer() {
    if (_primerShown) return;
    final hasProfile = ref.watch(myProfileProvider).value != null;
    final primer = ref.watch(pushPrimerChoiceProvider);
    // Chỉ hiện khi pref ĐÃ đọc xong và rỗng — đọc dở mà hiện là hỏi lại
    // người từng bấm "Để sau".
    if (hasProfile && primer.hasValue && primer.value == null) {
      _primerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) PushPrimerSheet.show(context);
      });
    }
  }

  /// [AUDIT M7] Tab đã thăm được giữ sống trong IndexedStack (giữ scroll/
  /// deck state khi chuyển tab); tab CHƯA thăm là SizedBox để giữ lazy-init
  /// như switch cũ — không fetch inbox/kèo trước khi user vào tab
  /// (home_shell_test khẳng định inboxCalls == 0 trước lần thăm đầu).
  final Set<int> _visited = {0};

  // Icon set follows design-system/MASTER.md: Đôi group · Kèo mic ·
  // Chat chat_bubble · Hồ sơ person.
  static const _icons = [
    Icons.group_outlined,
    Icons.mic_external_on_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.person_outline_rounded,
  ];
  static const _iconsSel = [
    Icons.group_rounded,
    Icons.mic_external_on_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  void _select(int i) {
    // inboxProvider là FutureProvider one-shot: không refetch khi vào
    // tab Chat thì pill 'Đến lượt bạn'/badge unread trễ tới khi user mở
    // 1 chat hoặc restart. Invalidate mỗi lần CHỌN tab 2 (NavigationBar
    // fire cả khi re-tap tab hiện tại — refetch thừa vô hại, coi như
    // pull-to-refresh). Realtime subscription: ngoài scope, không làm.
    if (i == 2) ref.invalidate(inboxProvider);
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowPushPrimer();
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final labels = [
      l10n?.tabDoi ?? 'Đôi',
      l10n?.tabKeo ?? 'Kèo',
      l10n?.tabChat ?? 'Tin nhắn',
      l10n?.tabProfile ?? 'Hồ sơ',
    ];
    final tabs = <Widget Function()>[
      () => const DoiDeckScreen(),
      () => const KeoBoardScreen(),
      () => InboxScreen(onFindKeo: () => _select(1)),
      () => const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < tabs.length; i++)
            _visited.contains(i) ? tabs[i]() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_iconsSel[i]),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}
