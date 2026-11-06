import 'listing_reviews_screen.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/skill_listing.dart';
import '../safety/safety_screens.dart';
import '../trades/trade_screens.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({
    super.key,
    required this.listing,
  });

  final SkillListing listing;

  @override
  Widget build(BuildContext context) {
    final isLanguage = listing.category.toLowerCase().contains('language');
    final accent = isLanguage
        ? const Color(0xFFC9E8FA)
        : const Color(0xFFD0EADD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
        backgroundColor: accent,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 200,
                  color: accent,
                  alignment: Alignment.center,
                  child: Container(
                    width: 110,
                    height: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: souqGreen, width: 3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      isLanguage ? 'أب' : 'Aa',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: souqGreen,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        listing.category.toUpperCase(),
                        style: const TextStyle(
                          color: souqGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        listing.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        listing.description.isEmpty
                            ? 'No description provided.'
                            : listing.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: souqGreen,
                            child: Text(
                              listing.ownerInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.owner,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (listing.isVerified) ...[
                                  const SizedBox(height: 5),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: souqGreen,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Verified',
                                        style: TextStyle(color: souqGreen),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '★ ${listing.rating} · '
                                  '${listing.reviewCount} reviews',
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${listing.completedTrades} completed trades',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECF0E9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SkillSummary(
                                label: 'SKILL OFFERED',
                                skill: listing.offers,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.swap_horiz),
                            ),
                            Expanded(
                              child: _SkillSummary(
                                label: 'SKILL REQUESTED',
                                skill: listing.wants,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ListingInfo(
                        icon: Icons.location_on_outlined,
                        label: 'LOCATION',
                        value: listing.location.isEmpty
                            ? 'Not specified'
                            : '${listing.location} · ${listing.distance} km',
                      ),
                      _ListingInfo(
                        icon: Icons.calendar_today_outlined,
                        label: 'AVAILABILITY',
                        value: listing.availability.isEmpty
                            ? 'To be agreed'
                            : listing.availability,
                      ),
                      _ListingInfo(
                        icon: Icons.schedule,
                        label: 'IDEAL TRADE',
                        value: listing.idealTrade.isEmpty
                            ? 'Discuss in chat'
                            : listing.idealTrade,
                      ),
                      const SizedBox(height: 20),
                      ListingReviewsSection(listing: listing),
                      const SizedBox(height: 24),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: const Icon(
                            Icons.shield_outlined,
                            color: souqGreen,
                          ),
                          title: const Text('Trade safely'),
                          subtitle: const Text(
                            'Meet publicly, keep plans in chat, '
                            'and trust your instincts.',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SafetyCentreScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skill exchange'),
                        Text(
                          'No cash needed',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Propose a trade'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: RouteSettings(
                              name: '/trade',
                              arguments: listing,
                            ),
                            builder: (_) => const ChatNegotiateScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillSummary extends StatelessWidget {
  const _SkillSummary({required this.label, required this.skill});

  final String label;
  final String skill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 6),
        Text(skill, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ListingInfo extends StatelessWidget {
  const _ListingInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: souqLavender),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
