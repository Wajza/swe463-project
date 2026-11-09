import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class ScreenShell extends StatelessWidget {
  const ScreenShell({required this.title, required this.description, this.icon = Icons.auto_awesome, this.actions = const [], super.key});
  final String title;
  final String description;
  final IconData icon;
  final List<Widget> actions;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 24),
      CircleAvatar(radius: 38, backgroundColor: souqMint.withValues(alpha: .35), child: Icon(icon, size: 36, color: souqGreen)),
      const SizedBox(height: 20),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: souqNavy)),
      const SizedBox(height: 12),
      Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5)),
      const SizedBox(height: 28),
      ...actions,
    ]),
  );
}
class ScreenAction extends StatelessWidget {
  const ScreenAction({required this.label, this.onPressed, this.outlined = false, super.key});
  final String label; final VoidCallback? onPressed; final bool outlined;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SouqButton(label: label, onPressed: onPressed, outlined: outlined),
  );
}

