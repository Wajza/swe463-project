import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/wallet_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/info_card.dart';
import 'package:souq_skills/widgets/info_tile.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context) => LiveEntity<WalletTransaction>(
    find: () => WalletService().byId(transactionId),
    builder: (context, transaction) {
      final tradeId = transaction.tradeId;
      final participant = transaction.participantName;
      return AppPage(
        title: 'Transaction details',
        footer: [
          if (tradeId != null)
            SouqButton(
              label: 'View trade',
              onPressed: () =>
                  context.open(AppRoutes.tradeDetails, args: tradeId),
            ),
        ],
        children: [
          InfoCard(
            tiles: [
              InfoTile(label: 'Title', value: transaction.title),
              InfoTile(
                label: 'Amount',
                value:
                    '${AppFormatters.signedCredits(transaction.amount)} credits',
              ),
              InfoTile(label: 'Type', value: transaction.type.label),
              InfoTile(
                label: 'Date',
                value: AppFormatters.dateTime(transaction.date),
              ),
              if (transaction.subtitle.isNotEmpty)
                InfoTile(label: 'Details', value: transaction.subtitle),
              if (participant != null)
                InfoTile(label: 'With', value: participant),
            ],
          ),
        ],
      );
    },
  );
}
