import 'package:flutter/material.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/loading_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: FutureBuilder(
        future: ListingService().getListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Loading skills...');
          }
          if (snapshot.hasError) {
            return EmptyState(title: 'Could not load listings', message: snapshot.error.toString());
          }
          final listings = snapshot.data ?? [];
          if (listings.isEmpty) {
            return const EmptyState(title: 'No listings yet', message: 'New skill listings will appear here.');
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: listings.map((listing) => ListingCard(
              listing: listing,
              onTap: () {},
              onSave: () => ListingService().saveListing(listing.id),
            )).toList(),
          );
        },
      ),
    );
  }
}
