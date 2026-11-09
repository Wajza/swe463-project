import 'package:flutter/material.dart';
import 'package:souq_skills/services/wallet_service.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/loading_state.dart';
import 'package:souq_skills/widgets/transaction_tile.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wallet')),
    body: FutureBuilder(
      future: Future.wait([WalletService().getBalance(), WalletService().getTransactions()]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingState(message: 'Loading wallet...');
        final transactions = snapshot.data![1] as List;
        return ListView(padding: const EdgeInsets.all(20), children: [
          Card(color: const Color(0xFF071A2A), child: Padding(padding: const EdgeInsets.all(24), child: Text('${snapshot.data![0] as int} skill credits', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 20),
          if (transactions.isEmpty) const SizedBox(height: 300, child: EmptyState(title: 'No transactions', message: 'Wallet activity will appear here.')),
          ...transactions.map((item) => TransactionTile(transaction: item)),
        ]);
      },
    ),
  );
}

