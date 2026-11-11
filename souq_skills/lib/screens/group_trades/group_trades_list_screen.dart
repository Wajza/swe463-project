import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/online_groups.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/choice_chip_row.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/group_trade_card.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';

enum _GroupFilter {
  all('All'),
  mine('My groups'),
  invited('Invitations');

  const _GroupFilter(this.label);
  final String label;
}

class GroupTradesListScreen extends StatefulWidget {
  const GroupTradesListScreen({super.key});

  @override
  State<GroupTradesListScreen> createState() => _GroupTradesListScreenState();
}

class _GroupTradesListScreenState extends State<GroupTradesListScreen> {
  _GroupFilter _filter = _GroupFilter.all;

  bool _matches(GroupTrade group) {
    final service = GroupTradeService();
    return switch (_filter) {
      _GroupFilter.all => true,
      _GroupFilter.mine => service.isMember(group),
      _GroupFilter.invited => service.isInvited(group),
    };
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Group trades',
    floatingActionButton: FloatingActionButton(
      tooltip: 'Create group trade',
      onPressed: () =>
          context.open(AppRoutes.createListing, args: ListingKind.group),
      child: const Icon(Icons.add),
    ),
    children: [
      ChoiceChipRow<_GroupFilter>(
        options: _GroupFilter.values,
        selected: _filter,
        labelOf: (filter) => filter.label,
        onSelected: (filter) => setState(() => _filter = filter),
      ),
      const SizedBox(height: 14),
      LiveView(
        builder: (_) {
          final groups = GroupTradeService().all().where(_matches);
          final error = OnlineGroups.loadError;
          // Online groups that have not arrived yet.
          final loading =
              OnlineGroups.isAvailable &&
              !OnlineGroups.isLoaded &&
              error == null;
          return Column(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListingsLoadError(
                    title: 'Could not load group trades',
                    message: error,
                    onRetry: OnlineGroups.retry,
                  ),
                ),
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (groups.isEmpty)
                const EmptyState(
                  title: 'No group trades',
                  message:
                      'Groups are invite only. Create one with the + button.',
                  icon: Icons.groups_outlined,
                ),
              for (final group in groups) GroupTradeCard(group: group),
            ],
          );
        },
      ),
    ],
  );
}
