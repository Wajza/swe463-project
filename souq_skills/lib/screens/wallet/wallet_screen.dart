import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/services/wallet_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/loading_indicator.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/transaction_tile.dart';
import 'package:souq_skills/widgets/wallet_balance_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  /// The activity list, or why it cannot be shown yet. The empty message
  /// appears only once the history has really loaded with nothing in it.
  List<Widget> _buildActivity(
    WalletService wallet,
    List<WalletTransaction> transactions,
  ) {
    if (wallet.isLoading) {
      return const [LoadingIndicator(label: 'Loading your wallet…')];
    }
    if (transactions.isEmpty) {
      return wallet.loadError != null
          ? const []
          : const [
              EmptyState(
                title: 'No transactions',
                message: 'Wallet activity will appear here.',
              ),
            ];
    }
    return [
      for (final item in transactions) TransactionTile(transaction: item),
    ];
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final wallet = WalletService();
      final transactions = wallet.transactions();
      final error = wallet.loadError;
      final isLoaded = wallet.isLoaded;
      var earned = 0;
      var spent = 0;
      for (final item in transactions) {
        if (item.amount > 0) earned += item.amount;
        if (item.amount < 0) spent -= item.amount;
      }
      return AppPage(
        title: 'Wallet',
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListingsLoadError(
                title: 'Could not load your wallet',
                message: error,
                onRetry: wallet.retry,
              ),
            ),
          WalletBalanceCard(
            balance: isLoaded ? wallet.balance : null,
            isLoading: wallet.isLoading,
            held: wallet.heldCredits(),
            earned: isLoaded ? earned : null,
            spent: isLoaded ? spent : null,
          ),
          SectionHeader(
            title: 'Activity',
            actionLabel: 'How credits work',
            onAction: () => context.open(AppRoutes.skillCredits),
          ),
          ..._buildActivity(wallet, transactions),
        ],
      );
    },
  );
}
