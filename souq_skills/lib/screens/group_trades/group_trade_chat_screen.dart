import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/screens/shared/conversation_view.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/widgets/app_page.dart';

class GroupTradeChatScreen extends StatelessWidget {
  const GroupTradeChatScreen({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context) => LiveEntity<GroupTrade>(
    find: () => GroupTradeService().byId(groupId),
    builder: (context, group) => AppPage(
      title: group.title,
      actions: [
        IconButton(
          tooltip: 'Group details',
          onPressed: () =>
              context.open(AppRoutes.groupTradeDetails, args: groupId),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      body: ConversationView(
        conversationId: ChatService.groupConversationId(groupId),
        showSenders: true,
        onSend: (text) => ChatService().sendToGroup(groupId, text),
      ),
    ),
  );
}
