import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Delete your account?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    AuthService().deleteAccount();
    context.resetTo(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: 'Delete account',
    icon: Icons.warning_amber_rounded,
    title: 'Before you go',
    message:
        'Deleting your account removes your profile, listings, credits, '
        'badges, and ratings.',
    actions: [
      SouqButton(
        label: 'Delete my account',
        destructive: true,
        onPressed: () => _delete(context),
      ),
      SouqButton(
        label: 'Keep my account',
        outlined: true,
        onPressed: () => context.back(),
      ),
    ],
  );
}
