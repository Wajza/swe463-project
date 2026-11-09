import 'package:flutter/material.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';

abstract final class DeleteGroupTradeDialog {
  static Future<bool> confirm(BuildContext context) =>
      ConfirmationDialog.confirm(
        context,
        title: 'Delete group trade?',
        message: 'This removes the group for all of its members.',
        confirmLabel: 'Delete',
        destructive: true,
      );
}
