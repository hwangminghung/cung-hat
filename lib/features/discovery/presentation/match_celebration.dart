import 'package:flutter/material.dart';

class MatchCelebration extends StatelessWidget {
  const MatchCelebration({
    super.key, required this.otherName, required this.sharedBaitu, required this.onChat,
  });
  final String otherName;
  final List<String> sharedBaitu;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chung gu! 🎤',
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Bạn và $otherName cùng ${sharedBaitu.length} bài tủ',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 24),
            FilledButton(onPressed: onChat, child: const Text('Rủ đi hát')),
          ],
        ),
      ),
    );
  }
}
