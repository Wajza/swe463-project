import 'package:flutter/material.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/user_avatar.dart';

class BlockedMembersScreen extends StatelessWidget {
  const BlockedMembersScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final blocked = SafetyService().blockedMembers();
      return AppPage(
        emptyState: const EmptyState(
          title: 'Nobody is blocked',
          message: 'Members you block will appear here.',
          icon: Icons.block,
        ),
        title: 'Blocked members',
        children: [
          for (final member in blocked)
            Card(
              child: ListTile(
                leading: UserAvatar(initials: member.initials),
                title: Text(member.name),
                trailing: TextButton(
                  onPressed: () => SafetyService().unblockMember(member.id),
                  child: const Text('Unblock'),
                ),
              ),
            ),
        ],
      );
    },
  );
}
