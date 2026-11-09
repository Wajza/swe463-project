import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';
import 'package:souq_skills/core/category_config.dart';
class CategoryIcon extends StatelessWidget { const CategoryIcon({required this.category, this.size = 56, super.key}); final String category; final double size; @override Widget build(BuildContext context) => CircleAvatar(radius: size / 2, backgroundColor: souqMint.withValues(alpha: .35), child: Icon(CategoryConfig.iconFor(category), color: souqGreen, size: size * .48)); }
