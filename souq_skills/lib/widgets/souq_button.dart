import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class SouqButton extends StatelessWidget {
  const SouqButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.destructive = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final danger = context.colors.error;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        if (icon != null) Icon(icon, size: 20),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              style: destructive
                  ? OutlinedButton.styleFrom(
                      foregroundColor: danger,
                      side: BorderSide(color: danger),
                    )
                  : null,
              onPressed: onPressed,
              child: child,
            )
          : FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(
                      backgroundColor: danger,
                      foregroundColor: context.colors.onError,
                    )
                  : null,
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}
