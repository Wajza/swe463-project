import '../../main.dart';
import 'package:flutter/material.dart';

import '../../widgets/souq_widgets.dart';

class SafetyCentreScreen extends StatelessWidget {
  const SafetyCentreScreen({super.key});

  static const _guidance = [
    (
      number: '01',
      title: 'Meet in public first',
      description: 'Choose a busy café, library, or community space.',
    ),
    (
      number: '02',
      title: 'Keep plans in chat',
      description: 'It helps both members stay clear on what was agreed.',
    ),
    (
      number: '03',
      title: 'Protect personal details',
      description: "Share only what's needed for the skill exchange.",
    ),
    (
      number: '04',
      title: 'Trust your instincts',
      description: 'Leave, block, or report anytime you feel uncomfortable.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Centre'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: souqGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: souqMint,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Simple habits for confident, respectful '
                          'skill exchanges.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                for (final item in _guidance) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 42,
                          child: Text(
                            item.number,
                            style: const TextStyle(
                              color: souqLavender,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: souqNavy,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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

class ReportReceivedScreen extends StatelessWidget {
  const ReportReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: 'Report received',
      description: 'Thank you for helping keep Souq Skills welcoming. A report flow will be connected in Phase 3.',
      icon: Icons.check_circle_outline,
    );
  }
}
