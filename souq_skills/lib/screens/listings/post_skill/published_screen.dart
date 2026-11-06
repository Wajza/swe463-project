import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../models/skill_listing.dart';

class PublishedScreen extends StatelessWidget {
  const PublishedScreen({
    super.key,
    required this.listing,
  });

  final SkillListing listing;

  void _openTab(BuildContext context, int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => MainShell(initialIndex: index),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Published'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const CircleAvatar(
                  radius: 62,
                  backgroundColor: Color(0xFFE5F4CF),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: souqMint,
                    child: Icon(
                      Icons.check,
                      size: 48,
                      color: souqGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Your skill is out there',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your listing is ready to be discovered.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.auto_awesome,
                      color: souqGreen,
                    ),
                    title: Text(listing.title),
                    subtitle: Text('Looking for ${listing.wants}'),
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () => _openTab(context, 0),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to home'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _openTab(context, 2),
                  child: const Text('Post another skill'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
