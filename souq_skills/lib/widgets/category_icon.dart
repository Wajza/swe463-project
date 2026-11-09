import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/category_config.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({required this.category, this.size = 48, super.key});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: context.colors.primaryContainer,
    child: Icon(
      CategoryConfig.iconFor(category),
      color: context.colors.onPrimaryContainer,
      size: size * .48,
    ),
  );
}
