import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cung_hat/l10n/app_localizations.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../core/utils/message_safety.dart';
import '../application/chat_providers.dart';
import '../domain/message.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_message_bubble.dart';

/// 1-1 chat thread: history + realtime bubbles, composer with outbound safety.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.matchId, required this.otherName});

  final String matchId;
  final String otherName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  /// Live messages appended from the realtime stream; merged after history.
  final List<Message> _live = <Message>[];

  /// Ensures we only auto-scroll once when the initial history loads.
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // markRead returns void; a failure here must not crash the screen.
      ref
          .read(chatRepositoryProvider)
          .markRead(widget.matchId)
          .catchError((_) {});
    });
  }

  @override
  void dispose() {
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

  Future<void> _doSend(String text) async {
    if (messageLooksUnsafe(text)) {
      final l10n = Localizations.of<AppLocalizations>(
        context,
        AppLocalizations,
      );
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
      if (confirmed != true) throw const ChatSendCancelled();
    }

    await ref.read(chatRepositoryProvider).sendMessage(widget.matchId, text);
    if (!mounted) return;
    _scrollToBottom();
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(messageId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Khong xoa duoc tin nhan.')));
    }
  }

  void _showMatchMediaSendError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Khong gui duoc tep.')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final myUid = _myUid;

    // Append new live messages as they arrive (dedupe by id).
    ref.listen(liveMessagesProvider(widget.matchId), (prev, next) {
      next.whenData((m) {
        if (_live.any((e) => e.id == m.id)) return;
        setState(() => _live.add(m));
        _scrollToBottom();
        // Clear the unread badge while actively reading; skip our own echoes.
        if (m.senderId != myUid) {
          ref
              .read(chatRepositoryProvider)
              .markRead(widget.matchId)
              .catchError((_) {});
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
      appBar: AppBar(
        title: Text(widget.otherName),
        actions: [
          TextButton(
            // TODO(P3): navigate to /keo/create
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Sắp có'))),
            child: Text(l10n?.chatPromoteKeo ?? 'Lập kèo'),
          ),
        ],
      ),
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ChatMessageBubble(
                    message: m,
                    mine: mine,
                    resolveMediaUrl: (bucketId, objectPath) => ref
                        .read(chatRepositoryProvider)
                        .signedMediaUrl(bucketId, objectPath),
                    onDelete: mine ? () => _deleteMessage(m.id) : null,
                  ),
                );
              },
            ),
          ),
          ChatComposer(
            onSendText: _doSend,
            onSendMedia: (media) async {
              try {
                await ref
                    .read(chatRepositoryProvider)
                    .sendMatchMedia(widget.matchId, media);
                _scrollToBottom();
              } catch (_) {
                if (!mounted) return;
                _showMatchMediaSendError();
              }
            },
          ),
        ],
      ),
    );
  }
}
