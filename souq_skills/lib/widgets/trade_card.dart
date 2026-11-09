import 'package:flutter/material.dart';
import 'package:souq_skills/models/trade.dart';
class TradeCard extends StatelessWidget { const TradeCard({required this.trade, required this.onTap, super.key}); final Trade trade; final VoidCallback onTap; @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, leading: const Icon(Icons.swap_horiz), title: Text('${trade.offeredSkill} ⇄ ${trade.requestedSkill}'), subtitle: Text(trade.otherMemberName), trailing: Text(trade.status.name))); }
