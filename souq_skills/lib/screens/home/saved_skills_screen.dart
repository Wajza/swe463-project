import 'package:flutter/material.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/loading_state.dart';

class SavedSkillsScreen extends StatelessWidget {
  const SavedSkillsScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Saved skills')),
    body: FutureBuilder(
      future: ListingService().getListings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingState(message: 'Loading saved skills...');
        final listings = snapshot.data!.where((item) => item.isSaved).toList();
        if (listings.isEmpty) return const EmptyState(title: 'No saved skills', message: 'Save a listing to find it here.');
        return ListView(padding: const EdgeInsets.all(20), children: listings.map((item) => ListingCard(listing: item, onTap: () {}, onSave: () => ListingService().saveListing(item.id))).toList());
      },
    ),
  );
}
