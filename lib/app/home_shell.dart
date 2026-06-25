import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/billing/application/billing_providers.dart';
import '../features/chat/presentation/inbox_screen.dart';
import '../features/discovery/presentation/doi_deck_screen.dart';
import '../features/keo/presentation/keo_board_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static const _labels = ['Đôi', 'Kèo', 'Chat', 'Hồ sơ'];
  static const _icons = [Icons.favorite, Icons.groups, Icons.chat_bubble, Icons.person];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_index) {
        0 => const DoiDeckScreen(),
        1 => const KeoBoardScreen(),
        2 => const InboxScreen(),
        3 => ListView(
          children: [
            Consumer(
              builder: (context, ref, _) => ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Ai đã thích bạn'),
                onTap: () {
                  final unlocked = ref.read(hasEntitlementProvider('see_likes'));
                  context.push(unlocked ? '/likes' : '/store');
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
        _ => Center(child: Text('${_labels[_index]} — sắp có')),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(icon: Icon(_icons[i]), label: _labels[i]),
        ],
      ),
    );
  }
}
