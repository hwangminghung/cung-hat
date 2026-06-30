import 'package:cung_hat/features/chat/domain/message.dart';
import 'package:cung_hat/features/chat/presentation/widgets/media_message_view.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.resolveMediaUrl,
    this.onDelete,
  });

  final Message message;
  final bool mine;
  final Future<String> Function(String bucketId, String objectPath)
      resolveMediaUrl;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDeleted =
        message.hidden || message.attachment?.status == 'hidden';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: mine ? onDelete : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: mine
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _BubbleContent(
                message: message,
                isDeleted: isDeleted,
                resolveMediaUrl: resolveMediaUrl,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({
    required this.message,
    required this.isDeleted,
    required this.resolveMediaUrl,
  });

  final Message message;
  final bool isDeleted;
  final Future<String> Function(String bucketId, String objectPath)
      resolveMediaUrl;

  @override
  Widget build(BuildContext context) {
    if (isDeleted) {
      return Text(
        'Tin da xoa',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    if (message.kind == 'text') {
      return Text(message.body ?? '');
    }

    final attachment = message.attachment;
    if (attachment == null) {
      return const Text('Khong tai duoc tep');
    }

    return MediaMessageView(
      attachment: attachment,
      resolveMediaUrl: resolveMediaUrl,
    );
  }
}
