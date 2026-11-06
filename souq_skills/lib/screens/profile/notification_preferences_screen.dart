import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/profile_provider.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification preferences'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: souqMint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: souqGreen,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Choose the updates you want to receive.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: const Text('Trade messages'),
                    subtitle: const Text(
                      'New messages in your trade conversations.',
                    ),
                    value: preferences.tradeMessagesEnabled,
                    onChanged: (value) {
                      context
                          .read<ProfileProvider>()
                          .updateNotificationPreferences(
                            tradeMessages: value,
                          );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: const Text('Trade updates'),
                    subtitle: const Text(
                      'Proposals, counteroffers, and trade status changes.',
                    ),
                    value: preferences.tradeUpdatesEnabled,
                    onChanged: (value) {
                      context
                          .read<ProfileProvider>()
                          .updateNotificationPreferences(
                            tradeUpdates: value,
                          );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: const Text('Matching listings'),
                    subtitle: const Text(
                      'New skills matching your saved interests.',
                    ),
                    value: preferences.matchingListingsEnabled,
                    onChanged: (value) {
                      context
                          .read<ProfileProvider>()
                          .updateNotificationPreferences(
                            matchingListings: value,
                          );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
