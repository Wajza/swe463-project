import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/conversation_view.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/support_service.dart';
import 'package:souq_skills/widgets/app_page.dart';

class SupportMessagesScreen extends StatelessWidget {
  const SupportMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Support messages',
    body: ConversationView(
      conversationId: ChatService.supportConversationId,
      onSend: SupportService().send,
    ),
  );
}
