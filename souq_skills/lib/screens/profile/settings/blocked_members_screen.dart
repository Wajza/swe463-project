import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/user_avatar.dart';

class BlockedMembersScreen extends StatelessWidget {
  const BlockedMembersScreen({super.key});

  Future<void> _unblock(BuildContext context, User member) async {
    try {
      await SafetyService().unblockMember(member.id);
    } on BlockingException catch (error) {
      if (context.mounted) context.showMessage(error.message);
      return;
    }
    if (context.mounted) context.showMessage('${member.name} was unblocked');
  }

  List<Widget> _buildMembers(BuildContext context, ListingLoadState load) {
    // Until loaded for this account, the blocks may be another account's.
    if (!ListingService().hasCurrentListings) {
      if (load.isFailed) return const [];
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final blocked = SafetyService().blockedMembers();
    if (blocked.isEmpty) {
      return const [
        EmptyState(
          title: 'Nobody is blocked',
          message: 'Members you block will appear here.',
          icon: Icons.block,
        ),
      ];
    }
    return [
      for (final member in blocked)
        Card(
          child: ListTile(
            leading: UserAvatar(initials: member.initials),
            title: Text(member.name),
            trailing: ValueListenableBuilder<Set<String>>(
              valueListenable: SafetyService.changingIds,
              builder: (context, changing, _) => changing.contains(member.id)
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => context.open(
                            AppRoutes.reportMember,
                            args: member.id,
                          ),
                          child: const Text('Report'),
                        ),
                        TextButton(
                          onPressed: () => _unblock(context, member),
                          child: const Text('Unblock'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => AppPage(
      title: 'Blocked members',
      body: ValueListenableBuilder<ListingLoadState>(
        valueListenable: ListingService.loadState,
        builder: (context, load, _) => RefreshIndicator(
          onRefresh: ListingService().refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (load.isFailed)
                ListingsLoadError(
                  message: load.error!,
                  onRetry: ListingService().refresh,
                ),
              ..._buildMembers(context, load),
            ],
          ),
        ),
      ),
    ),
  );
}
