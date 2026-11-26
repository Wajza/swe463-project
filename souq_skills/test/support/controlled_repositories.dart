import 'dart:async';

import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/trade_proposal.dart';
import 'package:souq_skills/services/auth_service.dart';

const onlineTestUid = 'uid-maha';

/// A wallet whose live streams the test controls, so it can stay loading
/// or fail on demand.
class ControlledWallets extends DemoWalletRepository {
  var balance = StreamController<int?>.broadcast();
  var entries = StreamController<List<WalletEntry>>.broadcast();

  @override
  Stream<int?> watchBalance(String uid) => balance.stream;

  @override
  Stream<List<WalletEntry>> watchEntries(String uid) => entries.stream;
}

/// Trades whose live streams the test controls.
class ControlledTrades extends DemoTradeRepository {
  ControlledTrades(ControlledWallets wallets) : super(wallets: wallets);

  var trades = StreamController<List<OnlineTrade>>.broadcast();
  final proposals = StreamController<List<TradeProposal>>.broadcast();

  @override
  Stream<List<OnlineTrade>> watchTrades(String uid) => trades.stream;

  @override
  Stream<List<TradeProposal>> watchProposals(String uid) => proposals.stream;
}

class OnlineTestAuth extends DemoAuthRepository {
  OnlineTestAuth() : super(isKnownPhone: AuthService().isKnownPhone);

  @override
  String? get uid => onlineTestUid;
}
