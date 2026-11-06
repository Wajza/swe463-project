import '../listings/post_skill/post_skill_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../models/skill_listing.dart';
import '../../providers/listing_provider.dart';
import '../../providers/profile_provider.dart';
import '../listings/listing_screens.dart';

class MyTradesScreen extends StatelessWidget {
  const MyTradesScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    SkillListing listing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text(
          'Remove "${listing.title}" from your listings and Home?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep listing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      context.read<ListingProvider>().deleteListing(
            id: listing.id,
            ownerId: context.read<ProfileProvider>().profile.id,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted')),
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<ProfileProvider>().profile.id;
    final listings = context.watch<ListingProvider>().ownedBy(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trades'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: souqMint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.list_alt_outlined, color: souqGreen),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Manage the skills you offer and remove '
                          'listings you no longer need.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (listings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.post_add_outlined,
                          size: 48,
                          color: souqGreen,
                        ),
                        SizedBox(height: 16),
                        Text('No listings yet'),
                        SizedBox(height: 8),
                        Text(
                          'Use the Post tab to publish your first skill.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                for (final listing in listings) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Chip(label: Text('Active')),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            listing.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(listing.category),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECF0E9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('You offer: ${listing.offers}'),
                                const SizedBox(height: 8),
                                Text('You want: ${listing.wants}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(listing.description),
                          const SizedBox(height: 12),
                          Text(
                            listing.onlineOnly
                                ? 'Online only'
                                : listing.location,
                          ),
                          const SizedBox(height: 6),
                          Text(listing.availability),
                          if (listing.womenOnly) ...[
                            const SizedBox(height: 8),
                            const Text('Women only'),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ListingDetailScreen(listing: listing),
                                ),
                              );
                            },
                            child: const Text('View listing'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => PostSkillSkillsScreen(
                                          existingListing: listing,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700,
                                  ),
                                  onPressed: () => _delete(context, listing),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Delete'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
