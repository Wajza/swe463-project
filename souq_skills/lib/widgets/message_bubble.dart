import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    this.showSender = false,
    super.key,
  });

  final Message message;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall,
        ),
      );
    }
    final isMine = message.isFromCurrentUser;
    final foreground = isMine
        ? context.colors.onPrimary
        : context.colors.onSurface;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        padding: const EdgeInsets.all(13),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isMine
              ? context.colors.primary
              : context.colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSender && !isMine)
              Text(
                message.senderName,
                style: TextStyle(
                  color: context.colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(message.text, style: TextStyle(color: foreground)),
          ],
        ),
      ),
    );
  }
}
