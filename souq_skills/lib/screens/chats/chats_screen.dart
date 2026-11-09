import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_store.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/message_bubble.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final messages = AppStore.instance.messages;
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: messages.isEmpty
        ? const EmptyState(title: 'No conversations yet', message: 'Your messages and trade discussions will appear here.')
        : ListView(padding: const EdgeInsets.all(20), children: messages.map((message) => MessageBubble(message: message)).toList()),
    );
  }
}

