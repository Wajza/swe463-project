import 'package:flutter/material.dart';
import 'package:souq_skills/services/chat_service.dart';

import 'live_view.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.index,
    required this.onChanged,
    super.key,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final unread = ChatService().unreadConversationCount();
      return NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onChanged,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_outlined),
            ),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Post',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      );
    },
  );
}
