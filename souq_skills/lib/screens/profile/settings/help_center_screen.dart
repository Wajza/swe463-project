import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _questions = <(String, String)>[
    (
      'How does a skill trade work?',
      'Find a listing, send a proposal, schedule a session, complete the '
          'exchange, then rate your experience.',
    ),
    (
      'What are skill credits?',
      'You earn credits for each completed exchange. Your balance and history '
          'are in your wallet.',
    ),
    (
      'How do I earn badges?',
      'Badges unlock as you complete trades, publish listings, join groups, '
          'and share ratings. Open any badge to see its requirement.',
    ),
    (
      'What if something goes wrong?',
      'Open the trade, use the menu to report it or open a dispute, and track '
          'your case in the Safety Centre.',
    ),
  ];

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Help center',
    footer: [
      SouqButton(
        label: 'Contact support',
        onPressed: () => context.open(AppRoutes.contactSupport),
      ),
    ],
    children: [
      for (final (question, answer) in _questions)
        Card(
          child: ExpansionTile(
            shape: const Border(),
            title: Text(question),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [Text(answer, style: const TextStyle(height: 1.5))],
          ),
        ),
    ],
  );
}
