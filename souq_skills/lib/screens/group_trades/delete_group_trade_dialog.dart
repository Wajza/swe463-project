import 'package:flutter/material.dart';

class DeleteGroupTradeDialog extends StatelessWidget {
  const DeleteGroupTradeDialog({super.key});
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete Group Trade'),
    content: const Text('Confirm group trade deletion.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Confirm')),
    ],
  );
}
