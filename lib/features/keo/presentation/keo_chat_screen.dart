import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_safety.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../chat/application/chat_providers.dart';
import '../../chat/domain/message.dart';
import '../../chat/presentation/chat_timeline.dart';
import '../../chat/presentation/chat_widgets.dart';
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
      if (!await confirmUnsafeMessage(context)) return;
      if (!mounted) return;
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
            // [AUDIT M3] Lỗi tải history phải khác "thread trống": có nút
            // Thử lại; tin realtime đã tới thì ưu tiên hiển thị tin.
            child: historyAsync.hasError && messages.isEmpty
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Không tải được tin nhắn',
                    subtitle: 'Kiểm tra kết nối rồi thử lại.',
                    actionLabel: 'Thử lại',
                    onAction: () => ref.invalidate(
                      keoMessageHistoryProvider(widget.keoId),
                    ),
                  )
                : messages.isEmpty
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
                      final dayLabel = dayLabelBetween(
                        index == 0 ? null : messages[index - 1].createdAt,
                        message.createdAt,
                        DateTime.now(),
                      );
                      final bubble = MessageBubble(
                        message: message,
                        mine: mine,
                        senderName: mine ? null : nameById[message.senderId],
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
          ChatComposer(
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

