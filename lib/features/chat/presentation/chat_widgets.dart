import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/message.dart';
import '../domain/song_share.dart';
import 'chat_timeline.dart';
import 'song_share_widgets.dart';

/// [AUDIT M2] Bubble + composer + dialog an toàn dùng chung cho chat đôi
/// (chat_screen) và chat nhóm kèo (keo_chat_screen) — trước đây copy nguyên
/// văn ~200 dòng ở cả 2 màn và đã bắt đầu phân kỳ.

/// Hỏi xác nhận trước khi gửi tin có dấu hiệu nhạy cảm (tiền bạc/OTP...).
/// Trả true nếu user vẫn muốn gửi.
Future<bool> confirmUnsafeMessage(BuildContext context) async {
  final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.sendThisTitle ?? 'Gửi tin này?'),
      content: Text(
        l10n?.sendThisBody ??
            'Tin nhắn có vẻ liên quan tới tiền bạc hoặc thông tin nhạy cảm. Hãy kiểm tra kỹ trước khi gửi.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n?.cancel ?? 'Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n?.send ?? 'Gửi'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    this.senderName,
  });

  final Message message;
  final bool mine;

  /// Tên người gửi hiện trên bubble của NGƯỜI KHÁC trong chat nhóm (mockup
  /// 17) — null với bubble của mình, chat 1-1, hoặc khi roster chưa tải.
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
          color: mine ? AppColors.primaryTint : AppColors.surface,
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
                  color: AppColors.ink,
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            const SizedBox(height: 2),
            Text(
              bubbleTime(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
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
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return SafeArea(
      key: const Key('chat_composer'),
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(color: AppColors.background),
        child: Row(
          children: [
            IconButton.outlined(
              key: const Key('share_song_btn'),
              tooltip: l10n?.chatShareSongTooltip ?? 'Gửi bài tủ',
              onPressed: sending ? null : onShareSong,
              icon: const Icon(Icons.music_note_outlined),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: l10n?.chatComposerHint ?? 'Nhắn gì đó...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // [UI-AUDIT] Nút gửi disable khi ô trống — bấm gửi chuỗi rỗng
            // trước đây chỉ âm thầm no-op trong _send, giờ nút tự nói điều đó.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => IconButton.filled(
                key: const Key('send_btn'),
                tooltip: l10n?.send ?? 'Gửi',
                onPressed: (sending || value.text.trim().isEmpty)
                    ? null
                    : onSend,
                icon: sending
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
