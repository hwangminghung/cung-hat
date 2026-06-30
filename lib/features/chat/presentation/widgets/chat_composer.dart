import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../domain/pending_chat_media.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    this.enabled = true,
  });

  final Future<void> Function(String text) onSendText;
  final Future<void> Function(PendingChatMedia media) onSendMedia;
  final bool enabled;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  static const _maxImageBytes = 8388608;
  static const _maxVideoBytes = 26214400;

  final _controller = TextEditingController();

  bool _sending = false;

  bool get _canSend => widget.enabled && !_sending;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (!_canSend || text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await widget.onSendText(text);
      if (!mounted) return;
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickMedia() async {
    if (!_canSend) return;

    setState(() => _sending = true);
    try {
      final picked = await ImagePicker().pickMedia();
      if (picked == null) return;

      final file = File(picked.path);
      final length = await file.length();
      final mimeType = picked.mimeType ?? lookupMimeType(picked.path);
      if (!mounted) return;

      final isImage = mimeType?.startsWith('image/') ?? false;
      final isVideo = mimeType?.startsWith('video/') ?? false;
      if (!isImage && !isVideo) {
        _showSnack('Dinh dang tep chua duoc ho tro.');
        return;
      }

      if ((isImage && length > _maxImageBytes) ||
          (isVideo && length > _maxVideoBytes)) {
        _showSnack('Tep qua lon de gui.');
        return;
      }

      await widget.onSendMedia(
        PendingChatMedia(
          file: file,
          mediaType: isImage ? 'image' : 'video',
          mimeType: mimeType!,
          sizeBytes: length,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
              key: const Key('attach_media_btn'),
              tooltip: 'Attach media',
              icon: const Icon(Icons.attach_file),
              onPressed: _canSend ? _pickMedia : null,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendText(),
                decoration: const InputDecoration(
                  hintText: 'Nhan gi do...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              key: const Key('send_btn'),
              tooltip: 'Send',
              icon: const Icon(Icons.send),
              onPressed: _canSend ? _sendText : null,
            ),
          ],
        ),
      ),
    );
  }
}
