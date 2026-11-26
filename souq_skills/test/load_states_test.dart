import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/trades/my_trades_screen.dart';
import 'package:souq_skills/screens/wallet/wallet_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/online_wallet.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/wallet_service.dart';

import 'support/controlled_repositories.dart';
import 'support/memory_data_source.dart';

const _maha = onlineTestUid;

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late ControlledWallets wallets;
  late ControlledTrades trades;

  setUp(() async {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    AuthService.repository = OnlineTestAuth();
    AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
    final profiles = DemoProfileRepository();
    await profiles.saveProfile(
      _maha,
      const User(
        id: User.currentUserId,
        firstName: 'Maha',
        lastName: 'Test',
        username: 'maha_z',
        phone: '501234567',
        city: 'Jeddah',
        isVerified: true,
      ),
    );
    AuthService.profiles = profiles;
    ChatService.repository = DemoChatRepository();
    wallets = ControlledWallets();
    trades = ControlledTrades(wallets);
    OnlineTrades.repository = trades;
    AuthService().signIn();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() {
    OnlineTrades.repository = null;
    OnlineWallet.syncSession();
    ChatService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  Future<void> show(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();
  }

  group('Wallet', () {
    testWidgets('shows loading, never a zero balance, until it arrives', (
      tester,
    ) async {
      await show(tester, const WalletScreen());

      expect(WalletService().isLoaded, isFalse);
      expect(find.text('Loading balance…'), findsOneWidget);
      expect(find.text('Loading your wallet…'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('No transactions'), findsNothing);

      wallets.balance.add(120);
      wallets.entries.add(const []);
      await tester.pump();

      expect(find.text('120'), findsOneWidget);
      expect(find.text('No transactions'), findsOneWidget);
      expect(find.text('Loading balance…'), findsNothing);
    });

    testWidgets('a failed load says so and can be retried', (tester) async {
      await show(tester, const WalletScreen());

      wallets.entries.addError(WalletException.offline);
      await tester.pump();

      expect(find.text('Could not load your wallet'), findsOneWidget);
      expect(find.text(WalletException.offline.message), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.text('No transactions'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('Loading your wallet…'), findsOneWidget);

      wallets.balance.add(120);
      wallets.entries.add(const []);
      await tester.pump();
      expect(find.text('Could not load your wallet'), findsNothing);
      expect(find.text('120'), findsOneWidget);
    });
  });

  group('My trades', () {
    testWidgets('shows loading instead of an empty list', (tester) async {
      await show(tester, const MyTradesScreen());

      expect(TradeService().isLoading, isTrue);
      expect(find.text('Loading your trades…'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsNothing);

      trades.trades.add(const []);
      await tester.pump();
      expect(find.text('Loading your trades…'), findsNothing);
      expect(TradeService().isLoaded, isTrue);
    });

    testWidgets('a failed load says so and can be retried', (tester) async {
      await show(tester, const MyTradesScreen());

      trades.trades.addError(const TradeException('No connection.'));
      await tester.pump();

      expect(find.text('Could not load your trades'), findsOneWidget);
      expect(find.text('No connection.'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('Loading your trades…'), findsOneWidget);

      trades.trades.add(const []);
      await tester.pump();
      expect(find.text('Could not load your trades'), findsNothing);
      expect(find.text('Loading your trades…'), findsNothing);
    });
  });
}
