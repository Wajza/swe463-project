import 'package:flutter/material.dart';

import '../../main.dart';

class SkillCreditsScreen extends StatelessWidget {
  const SkillCreditsScreen({super.key});

  static const _guidance = [
    (
      symbol: '10',
      title: 'Credits per hour',
      description: 'You earn 10 credits for each verified hour shared.',
    ),
    (
      symbol: '0',
      title: 'No cash value',
      description: 'Credits cannot be purchased, sold, transferred, '
          'or cashed out.',
    ),
    (
      symbol: '∞',
      title: 'Keep trading',
      description: "Use credits when the other person doesn't "
          'need your offered skill.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill credits'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: souqGreen),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'A flexible way to keep exchanges fair. '
                          "Credits can't be bought or sold.",
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                for (final item in _guidance) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 44,
                          child: Text(
                            item.symbol,
                            style: const TextStyle(
                              color: souqLavender,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                style: const TextStyle(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
