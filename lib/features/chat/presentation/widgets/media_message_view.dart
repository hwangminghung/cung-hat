import 'package:cung_hat/features/chat/domain/message_attachment.dart';
import 'package:flutter/material.dart';

class MediaMessageView extends StatelessWidget {
  const MediaMessageView({
    super.key,
    required this.attachment,
    required this.resolveMediaUrl,
  });

  final MessageAttachment attachment;
  final Future<String> Function(String bucketId, String objectPath)
      resolveMediaUrl;

  static const double width = 220;
  static const double height = 160;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: resolveMediaUrl(attachment.bucketId, attachment.objectPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            key: Key('media_loading_bubble'),
            width: width,
            height: height,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            width: width,
            height: height,
            child: Center(child: Text('Khong tai duoc tep')),
          );
        }

        if (attachment.mediaType == 'image') {
          return ClipRRect(
            key: const Key('image_media_bubble'),
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  width: width,
                  height: height,
                  child: Center(child: Text('Khong tai duoc tep')),
                );
              },
            ),
          );
        }

        if (attachment.mediaType == 'video') {
          return Container(
            key: const Key('video_media_bubble'),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.play_circle_fill,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        return const SizedBox(
          width: width,
          height: height,
          child: Center(child: Text('Khong tai duoc tep')),
        );
      },
    );
  }
}
