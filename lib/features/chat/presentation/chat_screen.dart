import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_safety.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/domain/candidate.dart';
import '../../discovery/presentation/candidate_detail_sheet.dart';
import '../application/chat_providers.dart';
import '../application/inbox_providers.dart';
import 'chat_timeline.dart';
import '../domain/message.dart';
import '../domain/song_share.dart';
import 'song_share_widgets.dart';

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
  final List<Message> _live = <Message>[];

  bool _sending = false;
  bool _unmatching = false;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatRepositoryProvider)
          .markRead(widget.matchId)
          .catchError((_) {});
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
      return null;
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
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
            'Tin nhắn có vẻ liên quan tới tiền bạc hoặc thông tin nhạy cảm. Hãy kiểm tra kỹ trước khi gửi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Gửi'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await ref.read(chatRepositoryProvider).sendMessage(widget.matchId, text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không gửi được tin nhắn. Thử lại sau.')),
      );
      return;
    }
    if (!mounted) return;
    _controller.clear();
    _scrollToBottom();
  }

  /// Icebreaker: xem hồ sơ người ĐÃ match từ chat, tap "Trả lời" trong sheet
  /// để prefill composer (KHÔNG tự gửi — user vẫn phải bấm gửi qua dialog
  /// an toàn như bình thường).
  Future<void> _openMatchProfile() async {
    Candidate? candidate;
    try {
      candidate = await ref
          .read(discoveryRepositoryProvider)
          .getMatchProfile(widget.matchId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được hồ sơ. Thử lại sau.')),
      );
      return;
    }
    if (!mounted) return;
    if (candidate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hồ sơ không còn.')));
      return;
    }
    CandidateDetailSheet.show(
      context,
      candidate: candidate,
      onQuote: (q) {
        _controller.text = q;
        _controller.selection = TextSelection.collapsed(offset: q.length);
      },
    );
  }

  /// [A-I1] Huỷ ghép: cắt kết nối mà không cần block hay xoá tài khoản.
  /// Xác nhận qua dialog trước khi gọi RPC. Unmatch là vĩnh viễn cho cặp này
  /// (swipes cũ còn nguyên → không quay lại deck của nhau; record_swipe cũng
  /// không hồi sinh match đã unmatched).
  Future<void> _confirmUnmatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ ghép?'),
        content: const Text('Hai bạn sẽ không nhắn tin được với nhau nữa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            key: const Key('unmatch_confirm_btn'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ ghép'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Guard chống double-pop (mirror pattern _sending): confirm lần 2 lọt
    // vào cửa sổ await bên dưới thì RPC idempotent vô hại, nhưng pop lần 2
    // trong lúc animation sẽ over-pop quá màn chat.
    if (_unmatching) return;
    setState(() => _unmatching = true);
    try {
      await ref.read(chatRepositoryProvider).unmatch(widget.matchId);
      // Inbox liệt kê match qua get_my_matches (FutureProvider one-shot) —
      // invalidate TRƯỚC khi pop để danh sách hết match vừa cắt ngay khi
      // quay lại, bất kể ChatScreen được push từ đâu (inbox hay màn ăn mừng
      // match mới).
      ref.invalidate(inboxProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không huỷ ghép được, thử lại sau')),
        );
      }
    } finally {
      if (mounted) setState(() => _unmatching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _myUid;

    ref.listen(liveMessagesProvider(widget.matchId), (prev, next) {
      next.whenData((message) {
        if (_live.any((existing) => existing.id == message.id)) return;
        setState(() => _live.add(message));
        _scrollToBottom();
        if (message.senderId != myUid) {
          ref
              .read(chatRepositoryProvider)
              .markRead(widget.matchId)
              .catchError((_) {});
        }
      });
    });

    final historyAsync = ref.watch(messageHistoryProvider(widget.matchId));
    final history = historyAsync.value ?? const <Message>[];

    if (!_initialScrollDone && historyAsync.hasValue) {
      _initialScrollDone = true;
      _scrollToBottom();
    }

    final seen = <String>{};
    final messages = <Message>[];
    for (final message in [...history, ..._live]) {
      if (seen.add(message.id)) messages.add(message);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherName),
        actions: [
          IconButton(
            key: const Key('chat_profile_btn'),
            onPressed: _openMatchProfile,
            icon: const Icon(Icons.person_rounded),
            tooltip: 'Hồ sơ',
          ),
          PopupMenuButton<String>(
            key: const Key('chat_menu_btn'),
            // Khoá menu khi đang huỷ ghép: chặn luôn ca mở-lại-dialog trong
            // lúc RPC bay (dialog 2 đang mở đúng lúc pop chạy thì pop nuốt
            // dialog thay vì màn chat — màn chat kẹt lại dù đã unmatch).
            enabled: !_unmatching,
            onSelected: (v) {
              if (v == 'unmatch') _confirmUnmatch();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'unmatch',
                key: Key('unmatch_btn'),
                child: Text('Huỷ ghép'),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => context.push('/keo/create'),
            icon: const Icon(Icons.groups_rounded),
            label: const Text('Lập kèo'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        'Chưa có tin nhắn. Rủ nhau bằng một bài tủ đi.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final dayLabel = dayLabelBetween(
                        index == 0 ? null : messages[index - 1].createdAt,
                        message.createdAt,
                        DateTime.now(),
                      );
                      final bubble = _MessageBubble(
                        message: message,
                        mine: message.senderId == myUid,
                      );
                      if (dayLabel == null) return bubble;
                      return Column(
                        children: [
                          DayDivider(label: dayLabel),
                          bubble,
                        ],
                      );
                    },
                  ),
          ),
          _Composer(
            controller: _controller,
            sending: _sending,
            onSend: _send,
            onShareSong: _shareSong,
          ),
        ],
      ),
    );
  }

  Future<void> _shareSong() async {
    if (_sending) return;
    final body = await showSongShareSheet(context);
    if (body == null || !mounted) return;
    setState(() => _sending = true);
    try {
      await _doSend(body);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(maxWidth: 292),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 6),
            bottomRight: Radius.circular(mine ? 6 : 18),
          ),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSongShare(message.body))
              SongShareContent(body: message.body, mine: mine)
            else
              Text(
                message.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.textPrimary,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              bubbleTime(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                color: mine
                    ? AppColors.onPrimary.withValues(alpha: 0.72)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onShareSong,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onShareSong;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: const BoxDecoration(color: AppColors.background),
        child: Row(
          children: [
            IconButton.outlined(
              key: const Key('share_song_btn'),
              tooltip: 'Gửi bài tủ',
              onPressed: sending ? null : onShareSong,
              icon: const Icon(Icons.music_note_outlined),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Nhắn gì đó...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              key: const Key('send_btn'),
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
