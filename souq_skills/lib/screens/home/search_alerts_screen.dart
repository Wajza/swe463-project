import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/search_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/live_view.dart';

class SearchAlertsScreen extends StatelessWidget {
  const SearchAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final alerts = SearchService().alerts();
      return AppPage(
        emptyState: const EmptyState(
          title: 'No search alerts',
          message: 'Use the bell icon on search results to create one.',
          icon: Icons.notifications_none,
        ),
        title: 'Search alerts',
        children: [
          for (final alert in alerts)
            Card(
              child: ListTile(
                onTap: () =>
                    context.open(AppRoutes.searchResults, args: alert.criteria),
                title: Text(alert.criteria.summary),
                subtitle: Text(
                  '${ListingService().discover(alert.criteria).length} matching skills',
                ),
                leading: IconButton(
                  tooltip: 'Delete',
                  onPressed: () => SearchService().deleteAlert(alert.id),
                  icon: const Icon(Icons.delete_outline),
                ),
                trailing: Switch(
                  value: alert.isEnabled,
                  onChanged: (value) =>
                      SearchService().setAlertEnabled(alert.id, value),
                ),
              ),
            ),
        ],
      );
    },
  );
}
