import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/chat_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/profile/profile_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/experience_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/online_trades.dart';
import 'package:souq_skills/services/online_wallet.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/trade_service.dart';

import 'support/controlled_repositories.dart';
import 'support/memory_data_source.dart';

/// Opens [route] with [args] the way the app does.
Widget _appAt(String route, [Object? args]) => MaterialApp(
  onGenerateRoute: AppRouter.onGenerateRoute,
  onGenerateInitialRoutes: (_) => [
    AppRouter.onGenerateRoute(RouteSettings(name: route, arguments: args)),
  ],
);

void main() {
  final repository = Repository.instance;

  group('XP and levels', () {
    test('every 250 XP is a level, with titles at levels 3, 6 and 10', () {
      final start = ExperienceService.levelFor(0);
      expect(start.level, 1);
      expect(start.title, 'Newcomer');
      expect(start.xpToNextLevel, 250);

      expect(ExperienceService.levelFor(249).level, 1);
      final second = ExperienceService.levelFor(330);
      expect(second.level, 2);
      expect(second.xpIntoLevel, 80);
      expect(second.nextTitle, 'Skill Swapper');

      expect(ExperienceService.levelFor(500).title, 'Skill Swapper');
      expect(ExperienceService.levelFor(1250).title, 'Trusted Trader');
      expect(ExperienceService.levelFor(2250).title, 'Community Guide');
    });

    test('listings count only up to the limit', () {
      const source = ExperienceSource(
        label: 'Listings published',
        xpEach: ExperienceService.listingXp,
        count: 9,
        limit: ExperienceService.listingsCounted,
      );
      expect(source.xp, ExperienceService.listingXp * 5);
    });

    group('from the member\'s records', () {
      setUp(() {
        repository
          ..dataSource = MemoryDataSource()
          ..reset();
        AuthService().signIn();
      });

      test(
        'XP is the sum of its sources and rises with a completed trade',
        () async {
          final service = ExperienceService();
          final before = service.xp;
          expect(
            before,
            service.sources().fold<int>(0, (sum, source) => sum + source.xp),
          );

          expect(TradeService().byId('t-sami')!.status, TradeStatus.accepted);
          await TradeService().complete('t-sami');

          expect(service.xp, before + ExperienceService.tradeXp);
        },
      );

      testWidgets('the profile shows the level and how XP is earned', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(800, 3000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final level = ExperienceService().current();

        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pump();

        expect(
          find.text('Level ${level.level} · ${level.title}'),
          findsOneWidget,
        );
        expect(find.text('Level ${level.level}'), findsOneWidget);
        expect(
          find.text('${level.xpIntoLevel} / ${level.xpForLevel} XP'),
          findsOneWidget,
        );

        await tester.tap(find.text('Level ${level.level} · ${level.title}'));
        await tester.pumpAndSettle();
        expect(find.text('How XP works'), findsOneWidget);
        expect(find.text('Completed trades'), findsOneWidget);
      });
    });
  });

  group('rating is offered only when it can be done', () {
    setUp(() {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      AuthService().signIn();
    });

    test('a finished, unrated trade can be rated; others cannot', () {
      final reviews = ReviewService();
      expect(TradeService().byId('t-lina')!.isComplete, isTrue);
      expect(reviews.canRate('t-lina'), isTrue);
      // Already rated, and not finished.
      expect(reviews.canRate('t-omar'), isFalse);
      expect(reviews.canRate('t-sami'), isFalse);
    });
  });

  group('a dispute is sent from the dispute screen', () {
    setUp(() {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      AuthService().signIn();
    });

    testWidgets('it is saved, the trade is put on hold, and the case opens', (
      tester,
    ) async {
      await tester.pumpWidget(_appAt(AppRoutes.disputeTrade, 't-sami'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unsafe behaviour'));
      await tester.pump();
      await tester.tap(find.text('Submit dispute'));
      await tester.pumpAndSettle();

      expect(TradeService().byId('t-sami')!.status, TradeStatus.disputed);
      expect(find.text('Dispute received'), findsOneWidget);
      expect(find.textContaining('Case '), findsWidgets);
    });
  });

  group('with online trades', () {
    final originalAuth = AuthService.repository;
    late ControlledTrades trades;

    setUp(() async {
      repository
        ..dataSource = MemoryDataSource()
        ..reset();
      AuthService.repository = OnlineTestAuth();
      AuthService.deviceAccount = MemoryDeviceAccountStore(onlineTestUid);
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(
        onlineTestUid,
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
      trades = ControlledTrades(ControlledWallets());
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

    testWidgets('a trade opened before trades arrive shows loading, '
        'not "Page not found"', (tester) async {
      await tester.pumpWidget(_appAt(AppRoutes.tradeDetails, 'trade-online-1'));
      await tester.pump();

      expect(find.text('Loading…'), findsOneWidget);
      expect(find.text('Page not found'), findsNothing);

      trades.trades.add(const []);
      await tester.pump();
      expect(find.text('Page not found'), findsOneWidget);
    });

    testWidgets('a trade that failed to load can be retried', (tester) async {
      await tester.pumpWidget(_appAt(AppRoutes.tradeDetails, 'trade-online-1'));
      await tester.pump();

      trades.trades.addError(const TradeException('No connection.'));
      await tester.pump();
      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.text('No connection.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('Loading…'), findsOneWidget);
    });

    testWidgets('the level waits for trades instead of showing a low level', (
      tester,
    ) async {
      expect(ExperienceService().loadStatus.isLoading, isTrue);

      tester.view
        ..physicalSize = const Size(800, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();

      expect(find.text('Loading your level…'), findsOneWidget);
      expect(find.textContaining('Level 1'), findsNothing);
    });

    testWidgets('a listing opened while listings load shows the failure', (
      tester,
    ) async {
      final listings = _HeldListings();
      ListingService.repository = listings;
      addTearDown(() => ListingService.repository = null);

      await tester.pumpWidget(_appAt(AppRoutes.listingDetails, 'sami-1'));
      unawaited(ListingService().refresh());
      await tester.pump();
      expect(find.text('Loading…'), findsOneWidget);
      expect(find.text('Page not found'), findsNothing);

      listings.release.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.text('Check your internet connection.'), findsOneWidget);
    });
  });
}

/// Listings that wait until released, then fail.
class _HeldListings extends DemoListingRepository {
  final release = Completer<void>();

  @override
  Future<List<SkillListing>> fetchListings({String? uid}) async {
    await release.future;
    throw const ListingException('Check your internet connection.');
  }
}
