import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/utils/message_safety.dart';
import '../../chat/application/chat_providers.dart';
import '../../chat/domain/message.dart';

/// Kèo group chat: history + realtime bubbles, composer with outbound safety,
/// and a collapsible group-rules banner.
class KeoChatScreen extends ConsumerStatefulWidget {
  const KeoChatScreen({super.key, required this.keoId});

  final String keoId;

  @override
  ConsumerState<KeoChatScreen> createState() => _KeoChatScreenState();
}

class _KeoChatScreenState extends ConsumerState<KeoChatScreen> {
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
      // markKeoRead returns void; a failure here must not crash the screen.
      ref.read(chatRepositoryProvider).markKeoRead(widget.keoId).catchError((_) {});
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
      final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n?.sendThisTitle ?? 'Gửi tin này?'),
          content: Text(
            l10n?.sendThisBody ??
                'Tin nhắn này có vẻ liên quan đến tiền bạc hoặc thông tin nhạy cảm. '
                    'Hãy cẩn thận với lừa đảo. Vẫn muốn gửi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n?.cancel ?? 'Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n?.send ?? 'Gửi'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // An approved-but-unconfirmed user can reach this screen, but the server
    // raises `not_in_keo` for them. Surface a friendly message instead of
    // crashing the composer.
    try {
      await ref.read(chatRepositoryProvider).sendKeoMessage(widget.keoId, text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa mở chat nhóm (cần tất cả thành viên đồng ý)'),
        ),
      );
      return;
    }
    if (!mounted) return;
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _myUid;

    // Append new live messages as they arrive (dedupe by id).
    ref.listen(keoLiveMessagesProvider(widget.keoId), (prev, next) {
      next.whenData((m) {
        if (_live.any((e) => e.id == m.id)) return;
        setState(() => _live.add(m));
        _scrollToBottom();
        // Clear the unread badge while actively reading; skip our own echoes.
        if (m.senderId != myUid) {
          ref
              .read(chatRepositoryProvider)
              .markKeoRead(widget.keoId)
              .catchError((_) {});
        }
      });
    });

    final historyAsync = ref.watch(keoMessageHistoryProvider(widget.keoId));
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
      appBar: AppBar(title: const Text('Chat nhóm')),
      body: Column(
        children: [
          const _GroupRulesBanner(),
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

/// Collapsible reminder of the group ground rules, shown atop the chat.
class _GroupRulesBanner extends StatelessWidget {
  const _GroupRulesBanner();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: ExpansionTile(
        leading: Icon(Icons.info_outline),
        title: Text('Luật nhóm'),
        childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Không quay/chụp khi chưa đồng ý · Chia tiền rõ ràng · '
              'Tôn trọng riêng tư',
            ),
          ),
        ],
      ),
    );
  }
}
