import 'package:flutter/material.dart';

import '../../domain/pending_chat_media.dart';

class MediaPreviewBar extends StatelessWidget {
  const MediaPreviewBar({
    super.key,
    required this.media,
  });

  final PendingChatMedia media;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = media.mediaType == 'video';

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(isVideo ? Icons.videocam : Icons.image),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                media.mimeType,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
