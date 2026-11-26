import 'package:flutter/material.dart';
import 'package:souq_skills/models/load_status.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/loading_indicator.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

/// Keeps one record's screen up to date. While the record is missing it
/// shows why: still loading, failed to load (with Try again), or not found.
class LiveEntity<T> extends StatelessWidget {
  const LiveEntity({
    required this.find,
    required this.builder,
    this.loadStatus,
    this.alsoListenTo = const [],
    super.key,
  });

  final T? Function() find;
  final Widget Function(BuildContext context, T entity) builder;

  /// Where the record comes from; without it a missing record is not found.
  final LoadStatus Function()? loadStatus;

  /// Load states [loadStatus] reads that are kept outside the repository.
  final List<Listenable> alsoListenTo;

  Widget _buildMissing() {
    final status = loadStatus?.call() ?? LoadStatus.ready;
    if (status.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const LoadingIndicator(label: 'Loading…'),
      );
    }
    final error = status.error;
    if (error != null) {
      return StatusPage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load this page',
        message: error,
        action: status.onRetry == null
            ? null
            : SouqButton(label: 'Try again', onPressed: status.onRetry),
      );
    }
    return const NotFoundScreen();
  }

  @override
  Widget build(BuildContext context) => LiveView(
    alsoListenTo: alsoListenTo,
    builder: (context) {
      final entity = find();
      return entity == null ? _buildMissing() : builder(context, entity);
    },
  );
}
