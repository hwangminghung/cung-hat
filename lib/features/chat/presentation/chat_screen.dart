import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/utils/message_safety.dart';
import '../application/chat_providers.dart';
import '../domain/message.dart';

/// 1-1 chat thread: history + realtime bubbles, composer with outbound safety.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.matchId, required this.otherName});

  final String matchId;
  final String otherName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  /// Live messages appended from the realtime stream; merged after history.
  final List<Message> _live = <Message>[];

  /// Guards against double-send on rapid taps.
  bool _sending = false;

  /// Ensures we only auto-scroll once when the initial history loads.
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // markRead returns void; a failure here must not crash the screen.
      ref.read(chatRepositoryProvider).markRead(widget.matchId).catchError((_) {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String? get _myUid {
    try {
      return ref.read(supabaseClientProvider).auth.currentUser?.id;
    } catch (_) {
      // supabaseClientProvider is overridden in main(); in widget tests that
      // don't override it, treat the current user as unknown (left-align).
      return null;
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await _doSend(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _doSend(String text) async {
    if (messageLooksUnsafe(text)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gửi tin này?'),
          content: const Text(
            'Tin nhắn này có vẻ liên quan đến tiền bạc hoặc thông tin nhạy cảm. '
            'Hãy cẩn thận với lừa đảo. Vẫn muốn gửi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Gửi'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref.read(chatRepositoryProvider).sendMessage(widget.matchId, text);
    if (!mounted) return;
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _myUid;

    // Append new live messages as they arrive (dedupe by id).
    ref.listen(liveMessagesProvider(widget.matchId), (prev, next) {
      next.whenData((m) {
        if (_live.any((e) => e.id == m.id)) return;
        setState(() => _live.add(m));
        _scrollToBottom();
        // Clear the unread badge while actively reading; skip our own echoes.
        if (m.senderId != myUid) {
          ref.read(chatRepositoryProvider).markRead(widget.matchId).catchError((_) {});
        }
      });
    });

    final historyAsync = ref.watch(messageHistoryProvider(widget.matchId));
    final history = historyAsync.value ?? const <Message>[];

    // Scroll to newest once, after the initial history resolves.
    if (!_initialScrollDone && historyAsync.hasValue) {
      _initialScrollDone = true;
      _scrollToBottom();
    }

    // Combine history + live, deduping by id (history wins).
    final seen = <String>{};
    final messages = <Message>[];
    for (final m in [...history, ..._live]) {
      if (seen.add(m.id)) messages.add(m);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final mine = m.senderId == myUid;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: mine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.body),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Nhắn gì đó…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('send_btn'),
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
