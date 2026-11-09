import 'package:flutter/material.dart';
import 'package:souq_skills/models/user.dart';
import 'user_avatar.dart';
class ProfileHeader extends StatelessWidget { const ProfileHeader({required this.user, super.key}); final User user; @override Widget build(BuildContext context) => Column(children: [UserAvatar(user: user, radius: 42), const SizedBox(height: 12), Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), if (user.username.isNotEmpty) Text('@${user.username}'), if (user.city.isNotEmpty) Text(user.city)]); }
