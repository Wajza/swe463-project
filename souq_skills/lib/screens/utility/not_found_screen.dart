import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: 'Not found',
    icon: Icons.search_off,
    title: 'Page not found',
    message: 'This page may have been removed or is no longer available.',
    actions: [
      SouqButton(
        label: 'Go to start',
        onPressed: () => context.resetTo(
          AuthService().isSignedIn ? AppRoutes.home : AppRoutes.welcome,
        ),
      ),
    ],
  );
}
