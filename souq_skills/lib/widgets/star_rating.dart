import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';

class StarRating extends StatelessWidget {
  const StarRating({required this.rating, this.size = 18, super.key});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var star = 1; star <= 5; star++)
        Icon(_iconFor(star), size: size, color: souqGold),
    ],
  );

  IconData _iconFor(int star) {
    if (rating >= star) return Icons.star_rounded;
    if (rating >= star - .5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }
}
