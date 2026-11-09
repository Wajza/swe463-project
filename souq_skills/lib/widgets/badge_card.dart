import 'package:flutter/material.dart';
import 'package:souq_skills/models/badge.dart' as models;
class BadgeCard extends StatelessWidget { const BadgeCard({required this.badge, this.onTap, super.key}); final models.Badge badge; final VoidCallback? onTap; @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: Icon(badge.isEarned ? Icons.emoji_events : Icons.lock_outline), title: Text(badge.title), subtitle: Text(badge.description), trailing: Text('${badge.progress}/${badge.target}'))); }
