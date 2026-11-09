import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({required this.initials, this.radius = 20, super.key});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: souqGreen,
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * .55,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
