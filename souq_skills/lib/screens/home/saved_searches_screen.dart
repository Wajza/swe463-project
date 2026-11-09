import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/search_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/live_view.dart';

class SavedSearchesScreen extends StatelessWidget {
  const SavedSearchesScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final searches = SearchService().savedSearches();
      return AppPage(
        emptyState: const EmptyState(
          title: 'No saved searches',
          message: 'Use the bookmark icon on search results to save one.',
          icon: Icons.bookmark_border,
        ),
        title: 'Saved searches',
        children: [
          for (final search in searches)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: Text(search.summary),
                onTap: () =>
                    context.open(AppRoutes.searchResults, args: search),
                trailing: IconButton(
                  tooltip: 'Delete',
                  onPressed: () => SearchService().deleteSearch(search.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
        ],
      );
    },
  );
}
