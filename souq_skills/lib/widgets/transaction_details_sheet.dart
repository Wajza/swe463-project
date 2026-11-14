import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/models/transaction.dart';

/// Opens the details of one wallet [transaction] from the wallet's history.
Future<void> showTransactionDetails(
  BuildContext context,
  WalletTransaction transaction,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => TransactionDetailsSheet(transaction: transaction),
);

/// What a wallet entry was for, when, and its reference: the id it is
/// stored under in the member's ledger.
class TransactionDetailsSheet extends StatelessWidget {
  const TransactionDetailsSheet({required this.transaction, super.key});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.amount >= 0;
    final color = isCredit ? context.colors.primary : context.colors.error;
    final tradeId = transaction.tradeId;
    final participant = transaction.participantName;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: context.colors.primaryContainer,
              child: Icon(
                isCredit
                    ? Icons.add_circle_outline
                    : Icons.remove_circle_outline,
                color: color,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TRANSACTION DETAILS',
            textAlign: TextAlign.center,
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transaction.title,
            textAlign: TextAlign.center,
            style: context.textStyles.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${AppFormatters.signedCredits(transaction.amount)} credits',
            textAlign: TextAlign.center,
            style: context.textStyles.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _DetailRow(label: 'Type', value: transaction.type.label),
                  _DetailRow(
                    label: 'Date',
                    value: AppFormatters.dateTime(transaction.date),
                  ),
                  if (transaction.subtitle.isNotEmpty)
                    _DetailRow(label: 'For', value: transaction.subtitle),
                  if (participant != null && participant.isNotEmpty)
                    _DetailRow(label: 'With', value: participant),
                  _DetailRow(
                    label: 'Reference',
                    value: transaction.id,
                    selectable: true,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (tradeId != null)
            OutlinedButton(
              onPressed: () {
                // The sheet closes first, so its context is not used after.
                Navigator.of(context)
                  ..pop()
                  ..pushNamed(AppRoutes.tradeDetails, arguments: tradeId);
              },
              child: const Text('View trade'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.selectable = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool selectable;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          Text(label),
          Expanded(
            child: selectable
                ? SelectableText(
                    value,
                    textAlign: TextAlign.right,
                    style: style,
                  )
                : Text(value, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
