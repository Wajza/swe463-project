import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/experience_level.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/experience_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/review_service.dart';

import 'listings_load_error.dart';
import 'live_view.dart';

/// The member's level and XP progress, with how XP is earned. Shows a
/// spinner, not zero, until the records XP comes from have loaded.
class ExperienceCard extends StatefulWidget {
  const ExperienceCard({super.key});

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard> {
  @override
  void initState() {
    super.initState();
    // Ratings received count towards XP; load them if no screen has yet.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ReviewService().refreshReviews(const [User.currentUserId]),
    );
  }

  void _showSources() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ExperienceSources(),
  );

  @override
  Widget build(BuildContext context) => LiveView(
    alsoListenTo: [ListingService.loadState, ReviewService.loadStates],
    builder: (context) {
      final service = ExperienceService();
      final status = service.loadStatus;
      final error = status.error;
      if (error != null) {
        return ListingsLoadError(
          title: 'Could not load your level',
          message: error,
          onRetry: service.retry,
        );
      }
      return Card(
        child: InkWell(
          onTap: status.isLoading ? null : _showSources,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: status.isLoading
                ? const Row(
                    spacing: 12,
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      Text('Loading your level…'),
                    ],
                  )
                : _LevelProgress(level: service.current()),
          ),
        ),
      );
    },
  );
}

class _LevelProgress extends StatelessWidget {
  const _LevelProgress({required this.level});

  final ExperienceLevel level;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Level ${level.level} · ${level.title}',
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(Icons.info_outline, size: 20, color: context.colors.primary),
        ],
      ),
      LinearProgressIndicator(
        value: level.progress,
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
      Row(
        children: [
          Expanded(
            child: Text('${level.xpIntoLevel} / ${level.xpForLevel} XP'),
          ),
          Text(
            level.nextTitle == level.title
                ? '${level.xpToNextLevel} XP to Level ${level.level + 1}'
                : '${level.xpToNextLevel} XP to ${level.nextTitle}',
            style: context.textStyles.bodySmall,
          ),
        ],
      ),
    ],
  );
}

class _ExperienceSources extends StatelessWidget {
  const _ExperienceSources();

  @override
  Widget build(BuildContext context) {
    final service = ExperienceService();
    final level = service.current();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How XP works',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have ${level.xp} XP. Every '
              '${ExperienceService.xpPerLevel} XP is a new level.',
            ),
            const SizedBox(height: 8),
            for (final source in service.sources())
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(source.label),
                subtitle: Text(
                  '+${source.xpEach} XP each'
                  '${source.limit == null ? '' : ', up to ${source.limit}'}'
                  ' · ${source.count} so far',
                ),
                trailing: Text(
                  '${source.xp} XP',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
