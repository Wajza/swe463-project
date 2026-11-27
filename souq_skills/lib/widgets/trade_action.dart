import 'dart:async';

import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/services/online_trades.dart';

extension TradeActionFeedback on BuildContext {
  /// How long a change may take before a progress indicator covers the
  /// screen; changes on this device finish well before it.
  static const progressDelay = Duration(milliseconds: 300);

  /// How long the progress indicator waits for the server before giving
  /// the screen back, e.g. without a connection.
  static const slowAfter = Duration(seconds: 20);

  static const busyMessage =
      'Your last change is still being saved. Try again in a moment.';
  static const slowMessage =
      'This is taking longer than usual. Check your internet connection.';
  static const failedMessage = 'Something went wrong. Try again.';

  /// The trade change on its way, if any. Only one runs at a time, so a
  /// second tap never sends the same change twice.
  static Future<void>? _pending;

  /// Whether a trade change is still on its way.
  static bool get isBusy => _pending != null;

  /// Runs a trade change, showing why it failed; returns whether it worked.
  ///
  /// While it runs, other trade changes are refused, and after
  /// [progressDelay] a progress indicator covers the screen so nothing can
  /// be tapped twice. It always goes away: when the change finishes or
  /// fails, or after [slowAfter], when the member is told it is slow (the
  /// change itself still finishes, and nothing else runs until it has).
  /// Errors are shown in words, never as raw exceptions. Changes to demo
  /// members' trades finish at once and never fail.
  Future<bool> runTradeAction(Future<void> Function() action) async {
    if (_pending != null) {
      showMessage(busyMessage);
      return false;
    }
    final navigator = Navigator.of(this, rootNavigator: true);
    Route<void>? progress;
    final showProgress = Timer(progressDelay, () {
      if (!mounted) return;
      progress = DialogRoute<void>(
        context: this,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      navigator.push(progress!);
    });
    final running = Future.sync(action);
    final pending = running.then<void>((_) {}, onError: (Object _) {});
    _pending = pending;
    unawaited(
      pending.whenComplete(() {
        if (identical(_pending, pending)) _pending = null;
      }),
    );
    try {
      await running.timeout(slowAfter);
      return true;
    } on TradeException catch (error) {
      if (mounted) showMessage(error.message);
      return false;
    } on TimeoutException {
      if (mounted) showMessage(slowMessage);
      return false;
    } on Exception {
      if (mounted) showMessage(failedMessage);
      return false;
    } finally {
      showProgress.cancel();
      final route = progress;
      if (route != null && route.isActive) navigator.removeRoute(route);
    }
  }
}
