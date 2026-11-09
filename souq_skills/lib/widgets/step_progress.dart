import 'package:flutter/material.dart';

class StepProgress extends StatelessWidget {
  const StepProgress({required this.step, required this.total, super.key});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Text('Step $step of $total'),
        LinearProgressIndicator(value: step / total, minHeight: 6),
      ],
    ),
  );
}
