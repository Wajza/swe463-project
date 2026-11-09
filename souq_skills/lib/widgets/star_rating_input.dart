import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    required this.stars,
    required this.onChanged,
    super.key,
  });

  final int stars;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var star = 1; star <= 5; star++)
        IconButton(
          tooltip: '$star star${star == 1 ? '' : 's'}',
          iconSize: 44,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
          onPressed: () => onChanged(star),
          icon: Icon(
            star <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
            color: souqGold,
          ),
        ),
    ],
  );
}
