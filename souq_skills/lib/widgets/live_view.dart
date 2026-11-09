import 'package:flutter/material.dart';
import 'package:souq_skills/services/repository.dart';

/// Rebuilds [builder] whenever the app's data changes.
class LiveView extends StatelessWidget {
  const LiveView({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Repository.instance,
    builder: (context, _) => builder(context),
  );
}
