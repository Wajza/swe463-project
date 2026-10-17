import 'package:flutter/material.dart';

import '../../widgets/souq_widgets.dart';

class ChatNegotiateScreen extends StatelessWidget {
  const ChatNegotiateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat and negotiate')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Expanded(
              child: Center(
                child: Text(
                  'This is a demo conversation.\nMessages and offers will be added in Phase 3.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: 'Write a message',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const CounterofferDialog(),
                    ),
                    child: const Text('Counteroffer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompleteTradeScreen(),
                      ),
                    ),
                    child: const Text('Accept trade'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CounterofferDialog extends StatelessWidget {
  const CounterofferDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Make a counteroffer'),
      content: const TextField(
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Describe what you would like in return',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Send offer'),
        ),
      ],
    );
  }
}

class CompleteTradeScreen extends StatelessWidget {
  const CompleteTradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Complete trade and review',
      description: 'Confirming a trade and leaving a review will be available in Phase 3.',
      icon: Icons.rate_review_outlined,
      actions: [
        SouqButton(
          label: 'Done',
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ],
    );
  }
}
