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
    // Signed out on this device right away, so leave even if this fails.
    final signingOut = AuthService().signOut();
    context.resetTo(AppRoutes.welcome);
    try {
      await signingOut;
    } on AuthException {
      // The device no longer treats the member as signed in.
    }
  }
}
