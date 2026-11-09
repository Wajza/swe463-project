import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({required this.onSend, super.key});

  final ValueChanged<String> onSend;

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

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
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
