import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class TimelineEntry {
  const TimelineEntry(this.label, {required this.isDone});

  final String label;
  final bool isDone;
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({required this.entries, super.key});

  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final entry in entries)
            ListTile(
              leading: Icon(
                entry.isDone ? Icons.check_circle : Icons.circle_outlined,
                color: entry.isDone
                    ? context.colors.primary
                    : context.colors.outline,
              ),
              title: Text(entry.label),
            ),
        ],
      ),
    ),
  );
}
