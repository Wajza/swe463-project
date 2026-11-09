import 'package:flutter/material.dart';

/// One-tap messages shown above the chat composer.
class QuickReplies extends StatelessWidget {
  const QuickReplies({required this.replies, required this.onTap, super.key});

  final List<String> replies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        for (final reply in replies)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(reply),
              onPressed: () => onTap(reply),
            ),
          ),
      ],
    ),
  );
}
