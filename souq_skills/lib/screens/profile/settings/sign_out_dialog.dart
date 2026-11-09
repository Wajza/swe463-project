import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';

abstract final class SignOutDialog {
  static Future<void> show(BuildContext context) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Sign out?',
      message: 'You can sign back in with your phone number.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;
    AuthService().signOut();
    context.resetTo(AppRoutes.welcome);
  }
}
