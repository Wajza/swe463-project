import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/widgets/chat_composer.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/message_bubble.dart';
import 'package:souq_skills/widgets/proposal_card.dart';
import 'package:souq_skills/widgets/quick_replies.dart';

/// The message list and composer behind every chat in the app.
class ConversationView extends StatelessWidget {
  const ConversationView({
    required this.conversationId,
    required this.onSend,
    this.showSenders = false,
    super.key,
  });

  final String conversationId;
  final ValueChanged<String> onSend;
  final bool showSenders;

  void _markReadAfterFrame(List<Message> messages) {
    if (messages.every((message) => message.isRead)) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ChatService().markRead(conversationId),
    );
  }

  Widget _buildMessage(Message message) {
    final proposal = message.proposalId == null
        ? null
        : ProposalService().byId(message.proposalId!);
    return proposal != null
        ? ProposalCard(proposal: proposal)
        : MessageBubble(message: message, showSender: showSenders);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LiveView(
          builder: (context) {
            final messages = ChatService().messagesIn(conversationId);
            _markReadAfterFrame(messages);
            final newestFirst = messages.reversed.toList();
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: newestFirst.length,
              itemBuilder: (_, index) => _buildMessage(newestFirst[index]),
            );
          },
        ),
      ),
      QuickReplies(replies: AppOptions.quickReplies, onTap: onSend),
      ChatComposer(onSend: onSend),
    ],
  );
}
