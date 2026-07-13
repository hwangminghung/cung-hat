import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_safety.dart';
import '../../chat/application/chat_providers.dart';
import '../../chat/domain/message.dart';
import '../../chat/domain/song_share.dart';
import '../../chat/presentation/song_share_widgets.dart';
import '../application/keo_providers.dart';
import '../domain/keo_member.dart';

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
  final List<Message> _live = <Message>[];

  bool _sending = false;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatRepositoryProvider)
          .markKeoRead(widget.keoId)
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
      await ref.read(chatRepositoryProvider).sendKeoMessage(widget.keoId, text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa mở chat nhóm. Cần tất cả thành viên đồng ý tham gia.',
          ),
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

    ref.listen(keoLiveMessagesProvider(widget.keoId), (prev, next) {
      next.whenData((message) {
        if (_live.any((existing) => existing.id == message.id)) return;
        setState(() => _live.add(message));
        _scrollToBottom();
        if (message.senderId != myUid) {
          ref
              .read(chatRepositoryProvider)
              .markKeoRead(widget.keoId)
              .catchError((_) {});
        }
      });
    });

    final historyAsync = ref.watch(keoMessageHistoryProvider(widget.keoId));
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

    // Tên kèo (subtitle AppBar) + tên người gửi trên bubble (mockup 17) —
    // cả hai degrade êm khi provider lỗi: subtitle ẩn, bubble không tên.
    final keoTitle = ref.watch(keoHeaderProvider(widget.keoId)).value?.title;
    final roster =
        ref.watch(keoRosterProvider(widget.keoId)).value ?? const <KeoMember>[];
    final nameById = {
      for (final member in roster) member.userId: member.displayName,
    };

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chat nhóm'),
            if (keoTitle != null)
              Text(
                keoTitle,
                key: const Key('keo_chat_subtitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          const _GroupRulesBanner(),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        'Chưa có tin nhắn. Mở lời bằng một bài tủ của bạn.',
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
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final mine = message.senderId == myUid;
                      return _MessageBubble(
                        message: message,
                        mine: mine,
                        senderName: mine ? null : nameById[message.senderId],
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

class _GroupRulesBanner extends StatelessWidget {
  const _GroupRulesBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      // Màu nền đặt trên Material (không phải DecoratedBox) để ink/splash của
      // ListTile bên trong ExpansionTile vẽ đúng lớp.
      child: Material(
        color: AppColors.secondary.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppSpacing.radiusInput),
        clipBehavior: Clip.antiAlias,
        child: const ExpansionTile(
          leading: Icon(Icons.info_rounded, color: AppColors.secondaryDark),
          iconColor: AppColors.secondaryDark,
          collapsedIconColor: AppColors.secondaryDark,
          title: Text('Luật nhóm'),
          childrenPadding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Không quay/chụp khi chưa đồng ý · Chia tiền rõ ràng · Tôn trọng riêng tư',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    this.senderName,
  });

  final Message message;
  final bool mine;

  /// Tên người gửi hiện trên bubble của NGƯỜI KHÁC (mockup 17) — null với
  /// bubble của mình hoặc khi roster chưa tải.
  final String? senderName;

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
            if (senderName != null && senderName!.isNotEmpty) ...[
              Text(
                senderName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.tertiaryPop,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
            ],
            if (isSongShare(message.body))
              SongShareContent(body: message.body, mine: mine)
            else
              Text(
                message.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.textPrimary,
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
