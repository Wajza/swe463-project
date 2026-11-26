import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/group_trade_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/trade_repository.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/online_groups.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/online_wallet.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/review_service.dart';

import 'support/controlled_repositories.dart';
import 'support/memory_data_source.dart';

const _me = User.currentUserId;
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _tradeId = 'trade-online-1';
const _groupId = 'group-online-1';

/// Group trades whose live stream the test controls, so they can stay
/// loading or fail on demand.
class _ControlledGroups extends DemoGroupTradeRepository {
  var groups = StreamController<List<GroupTrade>>.broadcast();

  @override
  Stream<List<GroupTrade>> watchGroups(String uid) => groups.stream;
}

/// [status] trade with Sami, as Maha's app reads it from Firestore.
OnlineTrade _trade({TradeStatus status = TradeStatus.completed}) => OnlineTrade(
  trade: Trade(
    id: _tradeId,
    proposalId: 'proposal-online-1',
    otherMemberId: _sami,
    offeredSkill: 'Figma',
    requestedSkill: 'Guitar basics',
    status: status,
  ),
  createdAt: DateTime(2026, 11, 20),
);

/// A completed group of Maha, Lina (the organizer) and Sami.
const _group = GroupTrade(
  id: _groupId,
  title: 'Design circle',
  ownerId: _lina,
  memberIds: [_lina, _me, _sami],
  status: GroupTradeStatus.completed,
);

/// The app opened straight at the rating page of [contextId], as tapping
/// the "How was your exchange?" notification does.
Widget _rateAt(String contextId) => MaterialApp(
  onGenerateRoute: AppRouter.onGenerateRoute,
  onGenerateInitialRoutes: (_) => [
    AppRouter.onGenerateRoute(
      RouteSettings(name: AppRoutes.rateTrade, arguments: contextId),
    ),
  ],
);

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late ControlledTrades trades;
  late _ControlledGroups groups;

  setUp(() async {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    AuthService.repository = OnlineTestAuth();
    AuthService.deviceAccount = MemoryDeviceAccountStore(onlineTestUid);
    final profiles = DemoProfileRepository();
    for (final (uid, first, username) in [
      (onlineTestUid, 'Maha', 'maha_z'),
      (_sami, 'Sami', 'sami_a'),
      (_lina, 'Lina', 'lina_s'),
    ]) {
      await profiles.saveProfile(
        uid,
        User(
          id: User.currentUserId,
          firstName: first,
          lastName: 'Test',
          username: username,
          phone: '501234567',
          isVerified: true,
        ),
      );
    }
    AuthService.profiles = profiles;
    MemberService.forgetChecked();
    await MemberService().loadMembers([_sami, _lina]);
    ChatService.repository = DemoChatRepository();
    trades = ControlledTrades(ControlledWallets());
    OnlineTrades.repository = trades;
    groups = _ControlledGroups();
    OnlineGroups.repository = groups;
    AuthService().signIn();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() {
    OnlineTrades.repository = null;
    OnlineGroups.repository = null;
    OnlineWallet.syncSession();
    ChatService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  group('a trade', () {
    testWidgets('opened before trades arrive shows loading, then the form', (
      tester,
    ) async {
      await tester.pumpWidget(_rateAt(_tradeId));
      await tester.pump();

      expect(find.text('Loading…'), findsOneWidget);
      expect(find.text('Page not found'), findsNothing);

      trades.trades.add([_trade()]);
      groups.groups.add(const []);
      await tester.pump();

      expect(find.text('Rate your experience'), findsOneWidget);
      expect(
        find.text('How was your exchange with Sami Test?'),
        findsOneWidget,
      );
      expect(find.text('Guitar basics'), findsOneWidget);
    });

    testWidgets('still missing once everything has loaded is not found', (
      tester,
    ) async {
      await tester.pumpWidget(_rateAt(_tradeId));
      await tester.pump();

      trades.trades.add(const []);
      await tester.pump();
      // Group trades are still loading: it may yet be one of them.
      expect(find.text('Loading…'), findsOneWidget);

      groups.groups.add(const []);
      await tester.pump();
      expect(find.text('Page not found'), findsOneWidget);
    });

    testWidgets('that is not completed yet is not found once loaded', (
      tester,
    ) async {
      await tester.pumpWidget(_rateAt(_tradeId));
      trades.trades.add([_trade(status: TradeStatus.accepted)]);
      groups.groups.add(const []);
      await tester.pump();

      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text('Rate your experience'), findsNothing);
    });

    testWidgets('that failed to load can be tried again', (tester) async {
      await tester.pumpWidget(_rateAt(_tradeId));
      await tester.pump();

      trades.trades.addError(const TradeException('No connection.'));
      await tester.pump();
      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.text('No connection.'), findsOneWidget);
      expect(find.text('Page not found'), findsNothing);

      trades.trades = StreamController<List<OnlineTrade>>.broadcast();
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('Loading…'), findsOneWidget);

      trades.trades.add([_trade()]);
      groups.groups.add(const []);
      await tester.pump();
      expect(find.text('Rate your experience'), findsOneWidget);
    });

    testWidgets('already rated shows that, once the trade arrives', (
      tester,
    ) async {
      repository.insert(
        repository.reviews,
        Review(
          id: 'uid-maha_${_tradeId}_$_sami',
          authorId: _me,
          subjectId: _sami,
          contextId: _tradeId,
          rating: 5,
          comment: '',
          date: DateTime(2026, 11, 21),
        ),
      );
      await tester.pumpWidget(_rateAt(_tradeId));
      await tester.pump();
      expect(find.text('Loading…'), findsOneWidget);

      trades.trades.add([_trade()]);
      groups.groups.add(const []);
      await tester.pump();

      expect(find.text('Already rated'), findsOneWidget);
      expect(find.text('Rate your experience'), findsNothing);
    });

    testWidgets('can be rated once it arrives, and the rating is saved', (
      tester,
    ) async {
      await tester.pumpWidget(_rateAt(_tradeId));
      await tester.pump();
      trades.trades.add([_trade()]);
      groups.groups.add(const []);
      await tester.pump();

      await tester.tap(find.byTooltip('4 stars'));
      await tester.pump();
      await tester.tap(find.text('Submit rating'));
      // Not pumpAndSettle: the profile it moves on to keeps spinning while
      // the wallet, held back in these tests, loads.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Rating saved to your profile'), findsOneWidget);
      final given = ReviewService().givenFor(_tradeId, subjectId: _sami);
      expect(given, isNotNull);
      expect(given!.rating, 4);
    });

    testWidgets('opened after trades loaded shows the form straight away', (
      tester,
    ) async {
      trades.trades.add([_trade()]);
      groups.groups.add(const []);
      await tester.pump();

      await tester.pumpWidget(_rateAt(_tradeId));
      await tester.pump();

      expect(find.text('Loading…'), findsNothing);
      expect(find.text('Rate your experience'), findsOneWidget);
    });
  });

  group('a group trade', () {
    testWidgets('opened before groups arrive shows loading, then the form '
        'for the first member to rate', (tester) async {
      await tester.pumpWidget(_rateAt(_groupId));
      await tester.pump();
      trades.trades.add(const []);
      await tester.pump();

      expect(find.text('Loading…'), findsOneWidget);
      expect(find.text('Page not found'), findsNothing);

      groups.groups.add(const [_group]);
      await tester.pump();

      expect(find.text('Rate your experience'), findsOneWidget);
      // The organizer comes first.
      expect(
        find.text('How was your exchange with Lina Test?'),
        findsOneWidget,
      );
      expect(find.text('Design circle'), findsOneWidget);
    });

    testWidgets('missing once groups have loaded is not found', (tester) async {
      await tester.pumpWidget(_rateAt(_groupId));
      trades.trades.add(const []);
      groups.groups.add(const []);
      await tester.pump();

      expect(find.text('Page not found'), findsOneWidget);
    });

    testWidgets('that failed to load can be tried again', (tester) async {
      await tester.pumpWidget(_rateAt(_groupId));
      trades.trades.add(const []);
      await tester.pump();

      groups.groups.addError(StateError('No connection.'));
      await tester.pump();
      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.text('Page not found'), findsNothing);
    });

    testWidgets('keeps the member being rated once found', (tester) async {
      await tester.pumpWidget(_rateAt(_groupId));
      trades.trades.add(const []);
      groups.groups.add(const [_group]);
      await tester.pump();
      expect(
        find.text('How was your exchange with Lina Test?'),
        findsOneWidget,
      );

      // Rated elsewhere meanwhile: the form being filled in is not swapped
      // for another member; it shows that Lina is already rated.
      repository.insert(
        repository.reviews,
        Review(
          id: 'uid-maha_${_groupId}_$_lina',
          authorId: _me,
          subjectId: _lina,
          contextId: _groupId,
          rating: 5,
          comment: '',
          date: DateTime(2026, 11, 21),
        ),
      );
      await tester.pump();
      expect(find.text('How was your exchange with Sami Test?'), findsNothing);
      expect(find.text('Already rated'), findsOneWidget);
    });
  });
}
