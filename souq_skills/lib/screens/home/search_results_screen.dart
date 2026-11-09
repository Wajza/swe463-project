import 'package:flutter/material.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/loading_state.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({this.query = '', super.key});
  final String query;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(query.isEmpty ? 'Search results' : 'Results for $query')),
    body: FutureBuilder(
      future: ListingService().getListings(query: query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingState(message: 'Searching...');
        if (snapshot.hasError) return EmptyState(title: 'Search failed', message: snapshot.error.toString());
        final listings = snapshot.data!;
        if (listings.isEmpty) return const EmptyState(title: 'No results', message: 'Try a different search or clear your filters.');
        return ListView(padding: const EdgeInsets.all(20), children: listings.map((item) => ListingCard(listing: item, onTap: () {}, onSave: () => ListingService().saveListing(item.id))).toList());
      },
    ),
  );
}
