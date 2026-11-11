import 'dart:async';

import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/models/message.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/proposal_service.dart';
import 'package:souq_skills/widgets/chat_composer.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/message_bubble.dart';
import 'package:souq_skills/widgets/proposal_card.dart';
import 'package:souq_skills/widgets/quick_replies.dart';

/// The message list and composer behind every chat in the app.
class ConversationView extends StatefulWidget {
  const ConversationView({
    required this.conversationId,
    required this.onSend,
    this.showSenders = false,
    super.key,
  });

  final String conversationId;

  /// Sends a message; may throw a [ChatException], which is shown.
  final FutureOr<void> Function(String text) onSend;
  final bool showSenders;

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    ChatService().open(widget.conversationId);
  }

  @override
  void didUpdateWidget(ConversationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      ChatService()
        ..close(oldWidget.conversationId)
        ..open(widget.conversationId);
    }
  }

  @override
  void dispose() {
    ChatService().close(widget.conversationId);
    super.dispose();
  }

  /// Sends [text] unless a message is already on its way; returns whether
  /// it was sent.
  Future<bool> _send(String text) async {
    if (_sending) return false;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      return true;
    } on ChatException catch (error) {
      if (mounted) context.showMessage(error.message);
      return false;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _markReadAfterFrame(List<Message> messages) {
    if (messages.every((message) => message.isRead)) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ChatService().markRead(widget.conversationId),
    );
  }

  Widget _buildMessage(Message message) {
    final proposal = message.proposalId == null
        ? null
        : ProposalService().byId(message.proposalId!);
    return proposal != null
        ? ProposalCard(proposal: proposal)
        : MessageBubble(message: message, showSender: widget.showSenders);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LiveView(
          builder: (context) {
            final chats = ChatService();
            final messages = chats.messagesIn(widget.conversationId);
            final state = chats.loadStateOf(widget.conversationId);
            _markReadAfterFrame(messages);
            if (messages.isEmpty && state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final newestFirst = messages.reversed.toList();
            return Column(
              children: [
                if (state.isFailed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ListingsLoadError(
                      title: 'Could not load messages',
                      message: state.error!,
                      onRetry: () => chats.retry(widget.conversationId),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: newestFirst.length,
                    itemBuilder: (_, index) =>
                        _buildMessage(newestFirst[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      QuickReplies(replies: AppOptions.quickReplies, onTap: _send),
      ChatComposer(onSend: _send, isSending: _sending),
    ],
  );
}
