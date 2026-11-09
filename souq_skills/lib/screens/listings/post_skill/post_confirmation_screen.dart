import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class PostConfirmationScreen extends StatelessWidget {
  const PostConfirmationScreen({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context) => StatusPage(
    title: 'Your skill is live',
    message: 'Members can now find your listing and propose a trade.',
    showBackButton: false,
    actions: [
      SouqButton(
        label: 'View listing',
        onPressed: () =>
            context.resetThenOpen(AppRoutes.listingDetails, args: listingId),
      ),
      SouqButton(
        label: 'Back to home',
        outlined: true,
        onPressed: () => context.resetTo(AppRoutes.home),
      ),
    ],
  );
}
