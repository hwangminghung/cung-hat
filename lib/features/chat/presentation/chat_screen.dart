import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/message_safety.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../discovery/application/discovery_providers.dart';
import '../../discovery/domain/candidate.dart';
import '../../discovery/presentation/candidate_detail_sheet.dart';
import '../application/chat_providers.dart';
import '../application/inbox_providers.dart';
import 'chat_timeline.dart';
import 'chat_widgets.dart';
import '../domain/message.dart';
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

  AppLocalizations? get _l10n =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

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
      await ref.read(chatRepositoryProvider).sendMessage(widget.matchId, text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _l10n?.chatSendError ?? 'Không gửi được tin nhắn. Thử lại sau.',
          ),
        ),
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
        SnackBar(
          content: Text(
            _l10n?.chatProfileError ?? 'Không mở được hồ sơ. Thử lại sau.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (candidate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n?.chatProfileGone ?? 'Hồ sơ không còn.')),
      );
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
        title: Text(_l10n?.chatUnmatchTitle ?? 'Huỷ ghép?'),
        content: Text(
          _l10n?.chatUnmatchBody ?? 'Hai bạn sẽ không nhắn tin được với nhau nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l10n?.upsellLater ?? 'Để sau'),
          ),
          FilledButton(
            key: const Key('unmatch_confirm_btn'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_l10n?.chatUnmatchCta ?? 'Huỷ ghép'),
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
          SnackBar(
            content: Text(
              _l10n?.chatUnmatchError ?? 'Không huỷ ghép được, thử lại sau',
            ),
          ),
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
            tooltip: _l10n?.tabProfile ?? 'Hồ sơ',
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
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'unmatch',
                key: const Key('unmatch_btn'),
                child: Text(_l10n?.chatUnmatchCta ?? 'Huỷ ghép'),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => context.push('/keo/create'),
            icon: const Icon(Icons.groups_rounded),
            label: Text(_l10n?.chatPromoteKeo ?? 'Lập kèo'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // [AUDIT M3] Lỗi tải history phải khác "thread trống": có nút
            // Thử lại; tin realtime đã tới (messages non-empty) thì ưu tiên
            // hiển thị tin thay vì che bằng error.
            child: historyAsync.hasError && messages.isEmpty
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: _l10n?.chatHistoryError ?? 'Không tải được tin nhắn',
                    subtitle: _l10n?.commonCheckConnection ??
                        'Kiểm tra kết nối rồi thử lại.',
                    actionLabel: _l10n?.commonRetry ?? 'Thử lại',
                    onAction: () => ref.invalidate(
                      messageHistoryProvider(widget.matchId),
                    ),
                  )
                : messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        _l10n?.chatEmptyMatch ??
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
                        today: _l10n?.chatToday ?? 'Hôm nay',
                      );
                      final bubble = MessageBubble(
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

