import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/wallet_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/transaction_tile.dart';
import 'package:souq_skills/widgets/wallet_balance_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final wallet = WalletService();
      final transactions = wallet.transactions();
      var earned = 0;
      var spent = 0;
      for (final item in transactions) {
        if (item.amount > 0) earned += item.amount;
        if (item.amount < 0) spent -= item.amount;
      }
      return AppPage(
        title: 'Wallet',
        children: [
          WalletBalanceCard(
            balance: wallet.balance,
            held: wallet.heldCredits(),
            earned: earned,
            spent: spent,
          ),
          SectionHeader(
            title: 'Activity',
            actionLabel: 'How credits work',
            onAction: () => context.open(AppRoutes.skillCredits),
          ),
          if (transactions.isEmpty)
            const EmptyState(
              title: 'No transactions',
              message: 'Wallet activity will appear here.',
            ),
          ...transactions.map((item) => TransactionTile(transaction: item)),
        ],
      );
    },
  );
}
