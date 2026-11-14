import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/models/transaction.dart';
import 'package:souq_skills/screens/listings/listing_details_screen.dart';
import 'package:souq_skills/screens/listings/listing_reviews_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/published_screen.dart';
import 'package:souq_skills/screens/profile/profile_screen.dart';
import 'package:souq_skills/screens/safety/safety_centre_screen.dart';
import 'package:souq_skills/screens/trades/trade_details_screen.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/screens/wallet/skill_credits_screen.dart';
import 'package:souq_skills/screens/wallet/wallet_screen.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/wallet_service.dart';

import 'support/memory_data_source.dart';

Widget _app(Widget screen) =>
    MaterialApp(home: screen, onGenerateRoute: AppRouter.onGenerateRoute);

/// A tall phone, so whole pages are built and can be tapped.
void _tallView(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    Repository.instance
      ..dataSource = MemoryDataSource()
      ..reset();
  });

  group('skill credits explanation', () {
    testWidgets('states the amounts the wallet actually pays', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(const SkillCreditsScreen()));

      expect(find.text('${WalletDocument.welcomeCredits}'), findsOneWidget);
      expect(find.text('+${WalletDocument.completionReward}'), findsOneWidget);
      expect(find.text('+${WalletDocument.groupReward}'), findsOneWidget);
      expect(
        find.textContaining(
          '${WalletDocument.completionReward} credits when a trade is '
          'completed, whatever its length',
        ),
        findsOneWidget,
      );
    });

    testWidgets('makes no per-hour claim', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(const SkillCreditsScreen()));

      expect(find.textContaining('per hour'), findsNothing);
      expect(find.textContaining('hour shared'), findsNothing);
    });

    testWidgets('is opened from the wallet', (tester) async {
      _tallView(tester);
      await tester.pumpWidget(_app(const WalletScreen()));

      await tester.tap(find.text('How credits work'));
      await tester.pumpAndSettle();
      expect(find.byType(SkillCreditsScreen), findsOneWidget);
    });
  });

  group('wallet', () {
    testWidgets('totals what was earned and spent, hidden with the balance', (
      tester,
    ) async {
      _tallView(tester);
      final history = WalletService().transactions();
      final earned = history
          .where((item) => item.amount > 0)
          .fold(0, (sum, item) => sum + item.amount);
      final spent = history
          .where((item) => item.amount < 0)
          .fold(0, (sum, item) => sum - item.amount);
      await tester.pumpWidget(_app(const WalletScreen()));

      expect(find.text('+$earned'), findsOneWidget);
      expect(find.text('−$spent'), findsOneWidget);

      await tester.tap(find.byTooltip('Hide balance'));
      await tester.pump();
      expect(find.text('+$earned'), findsNothing);
      expect(find.text('−$spent'), findsNothing);
      expect(find.text('••••'), findsNWidgets(3));
    });

    testWidgets('a transaction opens its details with date and reference', (
      tester,
    ) async {
      _tallView(tester);
      final welcome = WalletService().transactions().singleWhere(
        (item) => item.tradeId == null && item.amount > 0,
      );
      await tester.pumpWidget(_app(const WalletScreen()));

      await tester.tap(find.text(welcome.title));
      await tester.pumpAndSettle();

      expect(find.text('TRANSACTION DETAILS'), findsOneWidget);
      expect(find.text('+${welcome.amount} credits'), findsOneWidget);
      expect(find.text('Reference'), findsOneWidget);
      expect(find.text(welcome.id), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text(welcome.type.label), findsWidgets);
      // Not tied to a trade, so there is no trade to open.
      expect(find.text('View trade'), findsNothing);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('TRANSACTION DETAILS'), findsNothing);
    });

    testWidgets('a trade payment leads on to its trade', (tester) async {
      _tallView(tester);
      final WalletTransaction trade = WalletService().transactions().firstWhere(
        (item) => item.tradeId != null,
      );
      await tester.pumpWidget(_app(const WalletScreen()));

      await tester.tap(find.textContaining(trade.subtitle));
      await tester.pumpAndSettle();
      expect(find.text(trade.participantName!), findsOneWidget);

      await tester.tap(find.text('View trade'));
      await tester.pumpAndSettle();
      expect(find.text('TRANSACTION DETAILS'), findsNothing);
      expect(find.byType(TradeDetailsScreen), findsOneWidget);
    });
  });

  group('listing reviews', () {
    testWidgets('all of the owner\'s reviews open from the listing', (
      tester,
    ) async {
      _tallView(tester);
      final listing = ListingService().mine().first;
      final reviews = ReviewService().receivedBy(listing.ownerId);
      expect(reviews.length, greaterThan(2));
      await tester.pumpWidget(
        _app(ListingDetailsScreen(listingId: listing.id)),
      );

      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();

      expect(find.byType(ListingReviewsScreen), findsOneWidget);
      expect(find.text('${reviews.length} reviews'), findsOneWidget);
      for (final review in reviews) {
        expect(find.text(review.comment), findsOneWidget);
      }
    });

    testWidgets('shows a real empty state', (tester) async {
      final listing = ListingService().mine().first;
      Repository.instance.reviews.removeWhere(
        (item) => item.subjectId == listing.ownerId,
      );
      await tester.pumpWidget(
        _app(ListingReviewsScreen(listingId: listing.id)),
      );
      await tester.pumpAndSettle();

      expect(find.text('No reviews yet'), findsOneWidget);
    });

    testWidgets('a listing that is gone shows Not Found', (tester) async {
      await tester.pumpWidget(
        _app(const ListingReviewsScreen(listingId: 'missing')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });

  group('published', () {
    testWidgets('shows the saved listing and leads on to it', (tester) async {
      _tallView(tester);
      final listing = ListingService().mine().first;
      await tester.pumpWidget(_app(PublishedScreen(listingId: listing.id)));

      expect(find.text('Your skill is out there'), findsOneWidget);
      expect(find.text(listing.title), findsOneWidget);
      expect(find.text('Post another skill'), findsOneWidget);

      await tester.tap(find.text('View listing'));
      await tester.pumpAndSettle();
      expect(find.byType(ListingDetailsScreen), findsOneWidget);
      expect(find.text('Edit listing'), findsOneWidget);
    });
  });

  group('profile', () {
    testWidgets('shows the skills the member can share and wants to learn', (
      tester,
    ) async {
      _tallView(tester);
      final user = ProfileService().currentUser;
      await tester.pumpWidget(_app(const ProfileScreen()));

      expect(find.text('I can share'), findsOneWidget);
      expect(find.text('I want to learn'), findsOneWidget);
      for (final skill in [...user.skillsOffered, ...user.skillsWanted]) {
        expect(find.widgetWithText(Chip, skill), findsWidgets);
      }
    });
  });

  testWidgets('the Safety Centre keeps its guidance', (tester) async {
    _tallView(tester);
    await tester.pumpWidget(_app(const SafetyCentreScreen()));

    for (final label in [
      'Meet safely',
      'Keep plans in chat',
      'Protect your details',
      'Speak up',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
