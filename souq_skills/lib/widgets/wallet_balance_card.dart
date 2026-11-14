import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

class WalletBalanceCard extends StatefulWidget {
  const WalletBalanceCard({
    required this.balance,
    required this.held,
    this.earned,
    this.spent,
    super.key,
  });

  final int balance;
  final int held;

  /// Totals of the history shown in the wallet; left out when not given.
  final int? earned;
  final int? spent;

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    final foreground = context.colors.onPrimary;
    final earned = widget.earned;
    final spent = widget.spent;
    return Card(
      color: context.colors.primary,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalance(foreground),
            if (earned != null && spent != null) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _WalletTotal(
                      label: 'EARNED',
                      value: _isVisible ? '+$earned' : '••••',
                      color: foreground,
                    ),
                  ),
                  Expanded(
                    child: _WalletTotal(
                      label: 'SPENT',
                      value: _isVisible ? '−$spent' : '••••',
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalance(Color foreground) => Row(
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
  );
}

class _WalletTotal extends StatelessWidget {
  const _WalletTotal({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: .75),
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}
