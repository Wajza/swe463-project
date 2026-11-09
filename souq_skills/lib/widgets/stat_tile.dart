import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            spacing: 2,
            children: [
              Icon(icon, color: context.colors.primary),
              Text(
                value,
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: context.textStyles.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}
