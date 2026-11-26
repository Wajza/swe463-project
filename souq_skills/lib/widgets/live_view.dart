import 'package:flutter/material.dart';
import 'package:souq_skills/services/repository.dart';

/// Rebuilds [builder] whenever the app's data changes, and when any of
/// [alsoListenTo] does, such as a load state kept outside the repository.
class LiveView extends StatelessWidget {
  const LiveView({
    required this.builder,
    this.alsoListenTo = const [],
    super.key,
  });

  final WidgetBuilder builder;
  final List<Listenable> alsoListenTo;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: alsoListenTo.isEmpty
        ? Repository.instance
        : Listenable.merge([Repository.instance, ...alsoListenTo]),
    builder: (context, _) => builder(context),
  );
}
