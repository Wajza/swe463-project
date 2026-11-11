import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/conversation.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/user_avatar.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  void _open(BuildContext context, Conversation conversation) {
    if (conversation.isGroup) {
      context.open(AppRoutes.groupChat, args: conversation.groupId);
    } else {
      context.open(AppRoutes.chat, args: conversation.memberId);
    }
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final chats = ChatService();
      final conversations = chats.conversations();
      final state = chats.loadStateOf(ChatService.conversationList);
      return AppPage(
        emptyState: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                title: 'No conversations yet',
                message: 'Message a member from any listing to start chatting.',
                icon: Icons.chat_bubble_outline,
                action: SouqButton(
                  label: 'Browse skills',
                  onPressed: () => context.resetTo(AppRoutes.home),
                ),
              ),
        title: 'Chats',
        children: [
          if (state.isFailed)
            ListingsLoadError(
              title: 'Could not load chats',
              message: state.error!,
              onRetry: () => chats.retry(ChatService.conversationList),
            ),
          for (final conversation in conversations)
            Card(
              child: ListTile(
                onTap: () => _open(context, conversation),
                leading: conversation.isGroup
                    ? const CircleAvatar(child: Icon(Icons.groups_outlined))
                    : UserAvatar(
                        initials: conversation.title
                            .split(' ')
                            .take(2)
                            .map((part) => part[0])
                            .join(),
                      ),
                title: Text(conversation.title),
                subtitle: Text(
                  conversation.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: conversation.unreadCount == 0
                    ? null
                    : Badge(label: Text('${conversation.unreadCount}')),
              ),
            ),
        ],
      );
    },
  );
}
