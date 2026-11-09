import 'package:flutter/material.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/widgets/live_view.dart';

/// Keeps one record's screen up to date, or shows Not Found if it is gone.
class LiveEntity<T> extends StatelessWidget {
  const LiveEntity({required this.find, required this.builder, super.key});

  final T? Function() find;
  final Widget Function(BuildContext context, T entity) builder;

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final entity = find();
      return entity == null ? const NotFoundScreen() : builder(context, entity);
    },
  );
}
