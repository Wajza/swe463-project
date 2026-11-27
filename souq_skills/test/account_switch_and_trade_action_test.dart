import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/online_groups.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/online_wallet.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/widgets/trade_action.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _lina = 'uid-lina';
const _demoSami = 'm-sami';
const _reply = 'Thanks for your message! Let’s arrange the details.';

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

User _user(String first, String username) => User(
  id: User.currentUserId,
  firstName: first,
  lastName: 'Test',
  username: username,
  phone: '501234567',
  city: 'Jeddah',
  isVerified: true,
);

/// A screen with one button that runs [action] as a trade change, and
/// records what each run returned.
Widget _actionScreen(Future<void> Function() action, List<bool> results) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async =>
                  results.add(await context.runTradeAction(action)),
              child: const Text('Accept'),
            ),
          ),
        ),
      ),
    );

void main() {
  group('switching accounts', () {
    final repository = Repository.instance;
    final originalAuth = AuthService.repository;
    late _Auth auth;

    setUp(() async {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      auth = _Auth();
      AuthService.repository = auth;
      AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(_maha, _user('Maha', 'maha_z'));
      await profiles.saveProfile(_lina, _user('Lina', 'lina_s'));
      AuthService.profiles = profiles;
      ChatService.repository = DemoChatRepository();
      OnlineTrades.repository = DemoTradeRepository();
      OnlineGroups.repository = null;
      AuthService().signIn();
    });

    tearDown(() {
      OnlineTrades.repository = null;
      OnlineWallet.syncSession();
      ChatService.repository = null;
      AuthService.profiles = null;
      AuthService.deviceAccount = null;
      AuthService.repository = originalAuth;
    });

    testWidgets(
      "a demo member's reply to one account never reaches the next one",
      (tester) async {
        await ChatService().sendToMember(_demoSami, 'Hello Sami');

        // Before the reply arrives, Maha signs out and Lina signs in.
        await AuthService().signOut();
        auth.currentUid = _lina;
        expect(await AuthService().verifyCode('123456'), isTrue);
        expect(repository.currentUser.firstName, 'Lina');

        await tester.pump(MemberSimulator.replyDelay * 2);

        expect(
          ChatService().messagesIn(_demoSami).map((item) => item.text),
          isNot(contains(_reply)),
        );
        expect(
          repository.notifications.where(
            (item) => item.title.startsWith('New message from'),
          ),
          isEmpty,
        );
      },
    );

    testWidgets('the same account still gets its reply', (tester) async {
      await ChatService().sendToMember(_demoSami, 'Hello Sami');
      await tester.pump(MemberSimulator.replyDelay * 2);

      expect(
        ChatService().messagesIn(_demoSami).map((item) => item.text),
        contains(_reply),
      );
    });
  });

  group('running a trade change', () {
    testWidgets('shows progress while saving and refuses a second tap', (
      tester,
    ) async {
      final results = <bool>[];
      final saving = Completer<void>();
      var runs = 0;
      await tester.pumpWidget(
        _actionScreen(() {
          runs++;
          return saving.future;
        }, results),
      );

      await tester.tap(find.text('Accept'));
      await tester.pump();
      // Quick changes never flash a progress indicator.
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pump(TradeActionFeedback.progressDelay);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(TradeActionFeedback.isBusy, isTrue);

      // The indicator covers the button, so it cannot be tapped again.
      await tester.tap(find.text('Accept'), warnIfMissed: false);
      await tester.pump();
      expect(runs, 1);

      saving.complete();
      await tester.pumpAndSettle();
      expect(results, [true]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(TradeActionFeedback.isBusy, isFalse);
    });

    testWidgets('a change already on its way is never sent twice', (
      tester,
    ) async {
      final results = <bool>[];
      final saving = Completer<void>();
      var runs = 0;
      await tester.pumpWidget(
        _actionScreen(() {
          runs++;
          return saving.future;
        }, results),
      );

      // Two taps before the indicator appears.
      await tester.tap(find.text('Accept'));
      await tester.tap(find.text('Accept'));
      await tester.pump();

      expect(runs, 1);
      expect(results, [false]);
      expect(find.text(TradeActionFeedback.busyMessage), findsOneWidget);

      saving.complete();
      await tester.pumpAndSettle();
      expect(results, [false, true]);
    });

    testWidgets('a failure is explained and the screen is given back', (
      tester,
    ) async {
      final results = <bool>[];
      await tester.pumpWidget(
        _actionScreen(() async {
          await Future<void>.delayed(const Duration(seconds: 1));
          throw TradeException.notSaved;
        }, results),
      );

      await tester.tap(find.text('Accept'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(results, [false]);
      expect(find.text(TradeException.notSaved.message), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // It can be tried again.
      await tester.tap(find.text('Accept'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(results, [false, false]);
    });

    testWidgets('an unexpected error is never shown raw', (tester) async {
      final results = <bool>[];
      await tester.pumpWidget(
        _actionScreen(
          () async => throw Exception('[cloud_firestore/internal] stack…'),
          results,
        ),
      );

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(results, [false]);
      expect(find.text(TradeActionFeedback.failedMessage), findsOneWidget);
      expect(find.textContaining('cloud_firestore'), findsNothing);
    });

    testWidgets('a request that hangs never leaves the screen loading', (
      tester,
    ) async {
      final results = <bool>[];
      final saving = Completer<void>();
      await tester.pumpWidget(_actionScreen(() => saving.future, results));

      await tester.tap(find.text('Accept'));
      await tester.pump(TradeActionFeedback.progressDelay);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(TradeActionFeedback.slowAfter);
      await tester.pumpAndSettle();
      expect(results, [false]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(TradeActionFeedback.slowMessage), findsOneWidget);
      // Still on its way, so it is not sent a second time.
      expect(TradeActionFeedback.isBusy, isTrue);

      saving.complete();
      await tester.pump();
      expect(TradeActionFeedback.isBusy, isFalse);
    });
  });
}
