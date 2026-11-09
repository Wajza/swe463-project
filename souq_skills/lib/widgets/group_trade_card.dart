import 'package:flutter/material.dart';
import 'package:souq_skills/models/group_trade.dart';
class GroupTradeCard extends StatelessWidget { const GroupTradeCard({required this.trade, required this.onTap, super.key}); final GroupTrade trade; final VoidCallback onTap; @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: const Icon(Icons.groups_outlined), title: Text(trade.title), subtitle: Text('${trade.memberIds.length} members'), trailing: Text(trade.status.name))); }
