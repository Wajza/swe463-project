import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, super.key});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount >= 0;
    final color = isCredit ? context.colors.primary : context.colors.error;
    return Card(
      child: ListTile(
        onTap: () =>
            context.open(AppRoutes.transactionDetails, args: transaction.id),
        leading: Icon(
          isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: color,
        ),
        title: Text(transaction.title),
        subtitle: Text(transaction.subtitle),
        trailing: Text(
          AppFormatters.signedCredits(transaction.amount),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
