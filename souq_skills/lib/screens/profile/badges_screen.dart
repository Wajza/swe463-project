import 'package:flutter/material.dart';

import '../../main.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  // Sample achievements matching the approved design.
  // Replace these with achievement data from the shared service later.
  static const _badges = [
    (
      name: 'Trusted Trader',
      requirement: '10 safe trades',
      icon: Icons.verified_user_outlined,
      unlocked: true,
    ),
    (
      name: 'Connector',
      requirement: 'First group trade',
      icon: Icons.people_outline,
      unlocked: true,
    ),
    (
      name: 'Five-star Skill',
      requirement: '5 perfect reviews',
      icon: Icons.auto_awesome,
      unlocked: true,
    ),
    (
      name: 'Community Guide',
      requirement: 'Reach level 15',
      icon: Icons.star_outline,
      unlocked: false,
    ),
    (
      name: 'Always Ready',
      requirement: 'Reply in under 1 hour',
      icon: Icons.schedule_outlined,
      unlocked: false,
    ),
    (
      name: 'Local Hero',
      requirement: 'Complete 50 trades',
      icon: Icons.bookmark_outline,
      unlocked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
                      Icon(Icons.auto_awesome, color: souqGreen),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Earn recognition by trading safely, '
                          'reliably, and generously.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 300 ? 1 : 2;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final badge in _badges)
                          SizedBox(
                            width: width,
                            child: Semantics(
                              label: '${badge.name}, '
                                  '${badge.unlocked ? "Earned" : "Locked"}, '
                                  '${badge.requirement}',
                              excludeSemantics: true,
                              child: Card(
                                margin: EdgeInsets.zero,
                                color: badge.unlocked
                                    ? Colors.white
                                    : const Color(0xFFF1F3EE),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(
                                    color: Color(0xFFD7DFD8),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: badge.unlocked
                                              ? const Color(0xFFE5F4CF)
                                              : const Color(0xFFE5E9E2),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          badge.icon,
                                          color: badge.unlocked
                                              ? souqGreen
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        badge.name,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        badge.requirement,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        badge.unlocked ? 'Earned' : 'Locked',
                                        style: TextStyle(
                                          color: badge.unlocked
                                              ? souqGreen
                                              : Colors.grey.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
