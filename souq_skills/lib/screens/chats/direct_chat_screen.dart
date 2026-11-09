import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/shared/conversation_view.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/widgets/app_page.dart';

class DirectChatScreen extends StatelessWidget {
  const DirectChatScreen({required this.memberId, super.key});

  final String memberId;

  @override
  Widget build(BuildContext context) => LiveEntity<User>(
    find: () => MemberService().byId(memberId),
    builder: (context, member) => AppPage(
      title: member.name,
      actions: [
        IconButton(
          tooltip: 'Propose a trade',
          onPressed: () => context.open(
            AppRoutes.proposalInsideChat,
            args: ProposalRequest(memberId: memberId),
          ),
          icon: const Icon(Icons.handshake_outlined),
        ),
        IconButton(
          tooltip: 'View profile',
          onPressed: () =>
              context.open(AppRoutes.memberProfile, args: memberId),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      body: ConversationView(
        conversationId: memberId,
        onSend: (text) => ChatService().sendToMember(memberId, text),
      ),
    ),
  );
}
