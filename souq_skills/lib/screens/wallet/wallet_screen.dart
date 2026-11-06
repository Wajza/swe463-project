import 'package:flutter/material.dart';

import '../../data/demo_wallet.dart';
import '../../main.dart';
import '../../models/wallet_snapshot.dart';
import 'skill_credits_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({
    super.key,
    this.wallet = demoWallet,
  });

  final WalletSnapshot wallet;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _hideBalance = false;

  IconData _activityIcon(WalletActivityKind kind) {
    return switch (kind) {
      WalletActivityKind.earned => Icons.add,
      WalletActivityKind.spent => Icons.swap_horiz,
      WalletActivityKind.bonus => Icons.auto_awesome,
      WalletActivityKind.group => Icons.people_outline,
    };
  }

  void _showTransaction(WalletActivity transaction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: souqMint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  _activityIcon(transaction.kind),
                  color: souqGreen,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TRANSACTION DETAILS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: souqLavender,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              transaction.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '${transaction.amountLabel} credits',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(label: 'Date', value: transaction.dateLabel),
                    const Divider(height: 28),
                    _DetailRow(label: 'Status', value: transaction.status),
                    const Divider(height: 28),
                    _DetailRow(
                      label: 'Reference',
                      value: transaction.reference,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill wallet'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  color: souqGreen,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -60,
                        right: -50,
                        child: IgnorePointer(
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: souqMint,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'SKILL CREDITS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: _hideBalance
                                      ? 'Show balance'
                                      : 'Hide balance',
                                  onPressed: () {
                                    setState(() {
                                      _hideBalance = !_hideBalance;
                                    });
                                  },
                                  icon: Icon(
                                    _hideBalance
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hideBalance ? '••••' : '${wallet.balance}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              "Use credits when a direct skill swap isn't possible.",
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: _WalletTotal(
                                    label: 'EARNED',
                                    value: _hideBalance
                                        ? '••••'
                                        : '+${wallet.earned}',
                                  ),
                                ),
                                const SizedBox(
                                  height: 42,
                                  child: VerticalDivider(
                                    color: Colors.white38,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _WalletTotal(
                                    label: 'SPENT',
                                    value: _hideBalance
                                        ? '••••'
                                        : '−${wallet.spent}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF0E9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: souqLavender),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time becomes credit',
                              style: TextStyle(
                                color: souqLavender,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '1 hour shared earns 10 credits. '
                              'No buying or cashing out.',
                              style: TextStyle(color: souqLavender),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SkillCreditsScreen(),
                          ),
                        );
                      },
                      child: const Text('How it works ›'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (wallet.transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'No transactions yet',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final transaction in wallet.transactions)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECF0E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_activityIcon(transaction.kind)),
                    ),
                    title: Text(
                      transaction.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(transaction.subtitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          transaction.amountLabel,
                          style: TextStyle(
                            color: transaction.amount > 0
                                ? souqGreen
                                : souqNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => _showTransaction(transaction),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletTotal extends StatelessWidget {
  const _WalletTotal({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: souqMint,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
