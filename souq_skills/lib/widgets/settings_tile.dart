import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.colors.error : context.colors.primary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: destructive ? TextStyle(color: context.colors.error) : null,
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
