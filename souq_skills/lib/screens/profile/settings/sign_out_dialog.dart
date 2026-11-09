import 'package:flutter/material.dart';

class SignOutDialog extends StatelessWidget {
  const SignOutDialog({super.key});
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Sign Out'),
    content: const Text('Complete this Souq Skills flow.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Confirm')),
    ],
  );
}
