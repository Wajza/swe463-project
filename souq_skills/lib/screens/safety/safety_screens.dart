import 'package:flutter/material.dart';

import '../../widgets/souq_widgets.dart';

class SafetyCentreScreen extends StatelessWidget {
  const SafetyCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Safety Centre',
      description:
          'Helpful guidance for safe skill exchanges will be available here.',
      icon: Icons.shield_outlined,
      actions: [
        SouqButton(
          label: 'Report a problem',
          outlined: true,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportReceivedScreen()),
          ),
        ),
      ],
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
