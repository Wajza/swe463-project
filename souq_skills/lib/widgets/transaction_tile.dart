import 'package:flutter/material.dart';
import 'package:souq_skills/models/transaction.dart';
class TransactionTile extends StatelessWidget { const TransactionTile({required this.transaction, this.onTap, super.key}); final WalletTransaction transaction; final VoidCallback? onTap; @override Widget build(BuildContext context) => ListTile(onTap: onTap, leading: Icon(transaction.amount >= 0 ? Icons.add_circle : Icons.remove_circle), title: Text(transaction.title), subtitle: Text(transaction.subtitle), trailing: Text(transaction.amount.toString())); }
