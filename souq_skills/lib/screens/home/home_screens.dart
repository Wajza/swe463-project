import 'package:flutter/material.dart';

import '../../main.dart';
import '../listings/listing_screens.dart';
import '../safety/safety_screens.dart';
import '../../models/skill_listing.dart';
import '../../widgets/souq_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⌖  Al Olaya, Riyadh', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text(
              'Marhaba, Yara',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_none),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'What do you want to learn?',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 56,
                width: 64,
                decoration: BoxDecoration(
                  color: souqMint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.tune),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SavedSearchesScreen(),
                  ),
                ),
                icon: const Icon(Icons.bookmark_border),
                label: const Text('Saved searches'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchAlertsScreen()),
                ),
                icon: const Icon(Icons.notifications_none),
                label: const Text('Alerts'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'CATEGORIES',
            style: TextStyle(
              color: souqGreen,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Category(
                icon: Icons.auto_awesome,
                label: 'For you',
                color: souqMint,
              ),
              _Category(
                icon: Icons.translate,
                label: 'Languages',
                color: Color(0xFFE6E8E3),
              ),
              _Category(
                icon: Icons.text_fields,
                label: 'Design',
                color: Color(0xFFFFE6DC),
              ),
              _Category(
                icon: Icons.code,
                label: 'Tech',
                color: Color(0xFFDDEDEC),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skills in Riyadh',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Chip(label: Text('Nearest first')),
            ],
          ),
          SkillListingCard(
            listing: const SkillListing(
              title: 'Brand design basics',
              owner: 'Lama A.',
              category: 'Creative & Design',
              offers: 'Design',
              wants: 'Excel',
              distance: '1.8',
              rating: 4.9,
            ),
            accentColor: const Color(0xFFD8EEE0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListingDetailScreen()),
            ),
          ),
          SkillListingCard(
            listing: const SkillListing(
              title: 'Conversational Arabic',
              owner: 'Noura S.',
              category: 'Languages',
              offers: 'Arabic',
              wants: 'Photography',
              distance: '4.1',
              rating: 4.8,
            ),
            accentColor: const Color(0xFFC9E8FA),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListingDetailScreen()),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyCentreScreen()),
            ),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Safety Centre'),
          ),
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  const _Category({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Icon(icon, color: souqNavy),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class SavedSearchesScreen extends StatelessWidget {
  const SavedSearchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Saved searches',
      description: 'Your saved skill searches will appear here in Phase 3.',
      icon: Icons.bookmark_border,
    );
  }
}

class SearchAlertsScreen extends StatelessWidget {
  const SearchAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Search alerts',
      description:
          'Get notified when a new listing matches your saved searches.',
      icon: Icons.notifications_none,
    );
  }
}
