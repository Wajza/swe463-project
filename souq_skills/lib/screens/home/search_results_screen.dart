import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/saved_search.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/search_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/search_field.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({required this.initial, super.key});

  final SavedSearch initial;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late SavedSearch _criteria = widget.initial;
  late final _query = TextEditingController(text: widget.initial.query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final category = await context.open(AppRoutes.categoryFilter);
    if (category is String) {
      setState(() => _criteria = _criteria.copyWith(category: category));
    }
  }

  Future<void> _pickCity() async {
    final city = await context.open(AppRoutes.cityFilter);
    if (city is String) {
      setState(() => _criteria = _criteria.copyWith(city: city));
    }
  }

  void _saveSearch() {
    if (!_requireCriteria()) return;
    SearchService().saveSearch(_criteria);
    context.showMessage('Search saved');
  }

  void _createAlert() {
    if (!_requireCriteria()) return;
    SearchService().createAlert(_criteria);
    context.showMessage('Alert created');
  }

  bool _requireCriteria() {
    if (_criteria.hasCriteria) return true;
    context.showMessage('Add a search term or filter first');
    return false;
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Search results',
    actions: [
      IconButton(
        tooltip: 'Save search',
        onPressed: _saveSearch,
        icon: const Icon(Icons.bookmark_add_outlined),
      ),
      IconButton(
        tooltip: 'Create alert',
        onPressed: _createAlert,
        icon: const Icon(Icons.add_alert_outlined),
      ),
    ],
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SearchField(
          controller: _query,
          onSubmitted: (query) =>
              setState(() => _criteria = _criteria.copyWith(query: query)),
        ),
        const SizedBox(height: 10),
        _buildFilters(),
        const SizedBox(height: 10),
        LiveView(builder: (_) => _buildResults()),
      ],
    ),
  );

  Widget _buildFilters() => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      InputChip(
        label: Text(_criteria.category ?? 'Category'),
        selected: _criteria.category != null,
        onPressed: _pickCategory,
        onDeleted: _criteria.category == null
            ? null
            : () => setState(
                () => _criteria = _criteria.copyWith(clearCategory: true),
              ),
      ),
      InputChip(
        label: Text(_criteria.city ?? 'City'),
        selected: _criteria.city != null,
        onPressed: _pickCity,
        onDeleted: _criteria.city == null
            ? null
            : () => setState(
                () => _criteria = _criteria.copyWith(clearCity: true),
              ),
      ),
      FilterChip(
        label: const Text('Online'),
        selected: _criteria.onlineOnly,
        onSelected: (value) =>
            setState(() => _criteria = _criteria.copyWith(onlineOnly: value)),
      ),
      FilterChip(
        label: const Text('Women only'),
        selected: _criteria.womenOnly,
        onSelected: (value) =>
            setState(() => _criteria = _criteria.copyWith(womenOnly: value)),
      ),
    ],
  );

  Widget _buildResults() {
    final listings = ListingService().discover(_criteria);
    if (listings.isEmpty) {
      return const EmptyState(
        title: 'No results',
        message: 'Try a different search or clear your filters.',
      );
    }
    return Column(
      children: [for (final item in listings) ListingCard(listing: item)],
    );
  }
}
