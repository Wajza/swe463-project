import 'package:flutter/material.dart';

/// Shown in place of a list while its data is still loading, so an empty
/// list is never mistaken for a finished, empty result.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          const CircularProgressIndicator(),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
