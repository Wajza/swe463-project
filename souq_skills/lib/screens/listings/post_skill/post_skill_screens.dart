import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../widgets/souq_widgets.dart';

class PostSkillSkillsScreen extends StatelessWidget {
  const PostSkillSkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a skill')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'What can you offer?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text('Choose a skill category to start your listing.'),
          const SizedBox(height: 24),
          for (final category in ['Teaching', 'Design', 'Cooking', 'Repairs'])
            Card(
              child: ListTile(
                title: Text(category),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PostSkillDetailsScreen(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PostSkillDetailsScreen extends StatelessWidget {
  const PostSkillDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill details')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Skill title'),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Describe what you offer'),
            ),
            const Spacer(),
            SouqButton(
              label: 'Preview listing',
              showArrow: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListingPreviewScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListingPreviewScreen extends StatelessWidget {
  const ListingPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Listing preview',
      description: 'This is how your skill listing will look to other members.',
      icon: Icons.preview_outlined,
      actions: [
        SouqButton(
          label: 'Publish listing',
          showArrow: true,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PublishedScreen()),
          ),
        ),
      ],
    );
  }
}

class PublishedScreen extends StatelessWidget {
  const PublishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: 'Published!',
      description: 'Your skill is now ready to be discovered. Publishing is represented as a demo in Phase 2.',
      icon: Icons.check_circle_outline,
      actions: [
        SouqButton(
          label: 'Back to Discover',
          showArrow: true,
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
            (_) => false,
          ),
        ),
      ],
    );
  }
}
