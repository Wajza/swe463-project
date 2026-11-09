import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({
    required this.balance,
    required this.held,
    super.key,
  });

  final int balance;
  final int held;

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    final foreground = context.colors.onPrimary;
    return Card(
      color: context.colors.primary,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Skill credits', style: TextStyle(color: foreground)),
                  Text(
                    _isVisible ? '${widget.balance}' : '••••',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isVisible && widget.held > 0)
                    Text(
                      '${widget.held} on hold for active trades',
                      style: TextStyle(color: foreground),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: _isVisible ? 'Hide balance' : 'Show balance',
              onPressed: () => setState(() => _isVisible = !_isVisible),
              icon: Icon(
                _isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
