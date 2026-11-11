import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/services/online_trades.dart';

extension TradeActionFeedback on BuildContext {
  /// Runs a trade change, showing why it failed; returns whether it worked.
  /// Changes to demo members' trades finish at once and never fail.
  Future<bool> runTradeAction(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on TradeException catch (error) {
      if (mounted) showMessage(error.message);
      return false;
    }
  }
}
