import 'package:flutter/material.dart';

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
      body: Center(child: Text('${_labels[_index]} — sắp có')),
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
