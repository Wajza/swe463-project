import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class InfoTile extends StatelessWidget {
  const InfoTile({
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: icon == null ? null : Icon(icon, color: context.colors.primary),
    title: Text(
      label,
      style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
    ),
    subtitle: Text(value, style: const TextStyle(fontSize: 15)),
    trailing: trailing,
  );
}
