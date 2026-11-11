import 'dart:async';

import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({required this.onSend, this.isSending = false, super.key});

  /// Sends the text. The field is cleared once it was sent: unless this
  /// returns false, in which case the text stays for another try.
  final FutureOr<bool?> Function(String text) onSend;

  /// While a message is on its way, Send does nothing.
  final bool isSending;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    final sent = await widget.onSend(text);
    // Kept if it failed, or if the member already typed something else.
    if (sent != false && mounted && _controller.text.trim() == text) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(hintText: 'Write a message'),
            ),
          ),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: _send,
            style: IconButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    ),
  );
}
