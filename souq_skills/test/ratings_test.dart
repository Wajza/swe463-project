import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/badge_config.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/review_repository.dart';
import 'package:souq_skills/models/rating_request.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/profile/public_member_profile_screen.dart';
import 'package:souq_skills/screens/profile/reviews_screen.dart';
import 'package:souq_skills/screens/trades/rate_trade_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/badge_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/rating_summary.dart';
import 'package:souq_skills/widgets/review_card.dart';

import 'support/memory_data_source.dart';

const _me = User.currentUserId;
const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _omar = 'uid-omar';
const _offline = ReviewException('Check your internet connection.');

/// A completed trade with Sami, a real member.
const _samiTrade = 't-real-sami';
const _secondSamiTrade = 't-real-sami-2';
const _linaTrade = 't-real-lina';

/// A completed trade with a built-in demo member.
const _demoTrade = 't-demo-sami';

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

/// Reviews online; sending and loading can be held back or fail.
class _Reviews extends DemoReviewRepository {
  _Reviews({super.isPublic});

  bool failWrites = false;
  bool failFetch = false;
  Completer<void>? holdWrites;
  Completer<void>? holdFetch;
  int writes = 0;
  int fetches = 0;

  @override
  Future<Review> createReview(String uid, ReviewDraft draft) async {
    writes++;
    final waitFor = holdWrites;
    await waitFor?.future;
    if (failWrites) throw _offline;
    return super.createReview(uid, draft);
  }

  @override
  Future<List<Review>?> fetchReviewsAbout(
    String subjectUid, {
    required String viewerUid,
  }) async {
    fetches++;
    final waitFor = holdFetch;
    await waitFor?.future;
    if (failFetch) throw _offline;
    return super.fetchReviewsAbout(subjectUid, viewerUid: viewerUid);
  }

  @override
  Future<List<Review>> fetchReviewsBy(String uid) async {
    fetches++;
    final waitFor = holdFetch;
    await waitFor?.future;
    if (failFetch) throw _offline;
    return super.fetchReviewsBy(uid);
  }
}

User _user(String first, String last, String username, String phone) => User(
  id: User.currentUserId,
  firstName: first,
  lastName: last,
  username: username,
  phone: phone,
  isVerified: true,
);

/// [screen] in an app with the real routes, so screens can move on.
Widget _app(Widget screen) =>
    MaterialApp(home: screen, onGenerateRoute: AppRouter.onGenerateRoute);

ReviewDraft _draftAbout(String subject, {int rating = 5}) => ReviewDraft(
  subjectId: subject,
  rating: rating,
  contextId: 't-elsewhere',
  contextKind: ReviewContextKind.trade,
);

/// The online reviews on this device, i.e. not made on this device only.
List<Review> _onlineReviews() => [
  for (final item in Repository.instance.reviews)
    if (!item.id.startsWith('r-')) item,
];

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Auth auth;
  late DemoProfileRepository profiles;
  late _Reviews reviews;
  final hidden = <String>{};

  setUp(() async {
    repository
      ..dataSource = MemoryDataSource()
      ..reset();
    auth = _Auth();
    AuthService.repository = auth;
    AuthService.deviceAccount = MemoryDeviceAccountStore(_maha);
    profiles = DemoProfileRepository();
    await profiles.saveProfile(
      _maha,
      _user('Maha', 'Alzahrani', 'maha_z', '501234567'),
    );
    await profiles.saveProfile(
      _sami,
      _user('Sami', 'Alharbi', 'sami_a', '512345678'),
    );
    await profiles.saveProfile(
      _lina,
      _user('Lina', 'Saleh', 'lina_s', '523456789'),
    );
    AuthService.profiles = profiles;
    hidden.clear();
    reviews = _Reviews(isPublic: (uid) => !hidden.contains(uid));
    ReviewService.repository = reviews;
    AuthService().signIn();
    await MemberService().loadMembers([_sami, _lina]);
    for (final (id, member) in [
      (_samiTrade, _sami),
      (_secondSamiTrade, _sami),
      (_linaTrade, _lina),
      (_demoTrade, 'm-sami'),
    ]) {
      repository.insert(
        repository.trades,
        Trade(
          id: id,
          proposalId: 'p-$id',
          otherMemberId: member,
          offeredSkill: 'Figma',
          requestedSkill: 'Guitar basics',
          status: TradeStatus.completed,
        ),
      );
    }
  });

  tearDown(() {
    ReviewService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  RatingRequest requestFor(String tradeId) =>
      ReviewService().requestFor(tradeId)!;

  group('rating a real member', () {
    testWidgets('is saved online first, then on this device', (tester) async {
      await tester.pumpWidget(
        _app(const RateTradeScreen(contextId: _samiTrade)),
      );
      await tester.pumpAndSettle();
      final sending = reviews.holdWrites = Completer<void>();

      await tester.tap(find.byTooltip('4 stars'));
      await tester.pump();
      await tester.tap(find.text('On time'));
      await tester.pump();
      await tester.tap(find.text('Submit rating'));
      await tester.pump();

      // Nothing is shown as saved before it was.
      expect(find.text('Saving…'), findsOneWidget);
      expect(ReviewService().hasRated(_samiTrade), isFalse);

      sending.complete();
      await tester.pumpAndSettle();

      expect(find.text('Rating saved to your profile'), findsOneWidget);
      final stored = reviews.storedData('uid-maha_uid-sami')!;
      expect(stored['reviewerId'], _maha);
      expect(stored['subjectId'], _sami);
      expect(stored['rating'], 4);
      expect(stored['tags'], ['On time']);
      expect(stored['contextId'], _samiTrade);
      expect(stored['contextKind'], 'trade');
      // No names, phone numbers or other profile data.
      expect(
        stored.keys,
        everyElement(
          isIn([
            'reviewerId',
            'subjectId',
            'rating',
            'tags',
            'contextId',
            'contextKind',
            'skillTitle',
            'createdAt',
          ]),
        ),
      );
      expect(stored.values, isNot(contains('512345678')));
      expect(stored.values, isNot(contains(_me)));
      // Developer B's screens read it as before.
      expect(ReviewService().hasRated(_samiTrade), isTrue);
      expect(ReviewService().givenFor(_samiTrade)!.rating, 4);
      expect(ReviewService().givenFor(_samiTrade)!.comment, 'On time');
      expect(ReviewService().givenByCurrentUser().first.subjectId, _sami);
    });

    testWidgets('a failure keeps the form and can be retried', (tester) async {
      await tester.pumpWidget(
        _app(const RateTradeScreen(contextId: _samiTrade)),
      );
      await tester.pumpAndSettle();
      reviews.failWrites = true;

      await tester.tap(find.byTooltip('5 stars'));
      await tester.pump();
      await tester.tap(find.text('Submit rating'));
      await tester.pumpAndSettle();

      expect(
        find.text('Check your internet connection. Your rating was not saved.'),
        findsOneWidget,
      );
      expect(ReviewService().hasRated(_samiTrade), isFalse);
      expect(_onlineReviews(), isEmpty);

      reviews.failWrites = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Rating saved to your profile'), findsOneWidget);
      expect(ReviewService().hasRated(_samiTrade), isTrue);
    });

    testWidgets('tapping twice sends it once', (tester) async {
      await tester.pumpWidget(
        _app(const RateTradeScreen(contextId: _samiTrade)),
      );
      await tester.pumpAndSettle();
      final sending = reviews.holdWrites = Completer<void>();

      await tester.tap(find.byTooltip('5 stars'));
      await tester.pump();
      await tester.tap(find.text('Submit rating'));
      await tester.pump();
      await tester.tap(find.text('Saving…'), warnIfMissed: false);
      await tester.pump();
      expect(reviews.writes, 1);

      // The same rating sent again at once is the same one.
      final again = ReviewService().submitRating(
        requestFor(_samiTrade),
        5,
        const [],
      );
      sending.complete();
      await again;
      await tester.pumpAndSettle();
      expect(reviews.writes, 1);
      expect(_onlineReviews(), hasLength(1));
    });

    test('nobody can rate themselves', () async {
      for (final self in [_me, _maha]) {
        await expectLater(
          ReviewService().submitRating(
            RatingRequest(
              contextId: _samiTrade,
              subjectId: self,
              subjectName: 'Maha',
              skillTitle: '',
            ),
            5,
            const [],
          ),
          throwsA(same(ReviewException.cannotRateYourself)),
        );
      }
      expect(reviews.writes, 0);
    });

    test('a member is rated once, even for another trade', () async {
      await ReviewService().submitRating(requestFor(_samiTrade), 5, const []);

      for (final trade in [_samiTrade, _secondSamiTrade]) {
        await expectLater(
          ReviewService().submitRating(requestFor(trade), 1, const []),
          throwsA(same(ReviewException.duplicate)),
        );
      }
      expect(reviews.writes, 1);
      expect(ReviewService().receivedBy(_sami).single.rating, 5);
    });

    test('invalid stars or tags are refused before sending', () async {
      await expectLater(
        ReviewService().submitRating(requestFor(_samiTrade), 0, const []),
        throwsA(same(ReviewException.invalidRating)),
      );
      await expectLater(
        ReviewService().submitRating(requestFor(_samiTrade), 5, const ['Rude']),
        throwsA(same(ReviewException.invalidTags)),
      );
      expect(reviews.storedData('uid-maha_uid-sami'), isNull);
      expect(ReviewService().hasRated(_samiTrade), isFalse);
    });

    test('a rating given on another device is refused and loaded', () async {
      await reviews.createReview(_maha, _draftAbout(_sami, rating: 3));

      await expectLater(
        ReviewService().submitRating(requestFor(_samiTrade), 5, const []),
        throwsA(same(ReviewException.duplicate)),
      );
      await ReviewService().refreshReviews(const [_me]);

      expect(ReviewService().hasRatedMember(_sami), isTrue);
      expect(ReviewService().givenByCurrentUser().first.rating, 3);
    });

    testWidgets('the rate screen knows a member already rated elsewhere', (
      tester,
    ) async {
      await reviews.createReview(_maha, _draftAbout(_sami));

      await tester.pumpWidget(
        _app(const RateTradeScreen(contextId: _samiTrade)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Already rated'), findsOneWidget);
    });

    test(
      'a rating finishing after an account switch is not shown here',
      () async {
        final sending = reviews.holdWrites = Completer<void>();
        final rating = ReviewService().submitRating(
          requestFor(_samiTrade),
          5,
          const [],
        );
        auth.currentUid = _lina;
        sending.complete();
        await rating;

        // Saved as Maha's, online only.
        expect(reviews.storedData('uid-maha_uid-sami'), isNotNull);
        expect(_onlineReviews(), isEmpty);
        expect(ReviewService().hasRated(_samiTrade), isFalse);
      },
    );

    test('an expired session sends nothing', () async {
      auth.currentUid = null;
      await expectLater(
        ReviewService().submitRating(requestFor(_samiTrade), 5, const []),
        throwsA(isA<ReviewException>()),
      );
      expect(reviews.writes, 0);
    });
  });

  group('demo members and the offline demo', () {
    testWidgets('demo members are rated on this device only', (tester) async {
      final request = requestFor(_demoTrade);
      expect(request.subjectId, 'm-sami');

      await ReviewService().submitRating(request, 4, const ['On time']);

      expect(reviews.writes, 0);
      expect(ReviewService().hasRated(_demoTrade), isTrue);
      expect(ReviewService().givenFor(_demoTrade)!.id, startsWith('r-'));
      // The demo member still rates back.
      await tester.pump(MemberSimulator.replyDelay);
      expect(ReviewService().receivedBy(_me).first.authorId, 'm-sami');
      // And once per exchange, as before.
      await expectLater(
        ReviewService().submitRating(request, 2, const []),
        throwsA(same(ReviewException.duplicate)),
      );
    });

    testWidgets('offline, every rating stays on this device', (tester) async {
      ReviewService.repository = null;

      await ReviewService().submitRating(requestFor(_samiTrade), 5, const []);

      expect(reviews.writes, 0);
      expect(ReviewService().givenFor(_samiTrade)!.id, startsWith('r-'));
      expect(ReviewService().stateOf(_sami).status, ReviewsLoadStatus.loaded);
      await ReviewService().refreshReviews([_me, _sami]);
      expect(reviews.fetches, 0);
      // Real members are not simulated.
      await tester.pump(MemberSimulator.replyDelay);
      expect(
        ReviewService().receivedBy(_me).where((r) => r.authorId == _sami),
        isEmpty,
      );
    });

    test('the old synchronous submit still works', () {
      final before = ReviewService().givenByCurrentUser().length;
      ReviewService().submit(requestFor(_linaTrade), 5, 'Friendly');
      expect(ReviewService().givenByCurrentUser(), hasLength(before + 1));
      expect(ReviewService().hasRated(_linaTrade), isTrue);
    });
  });

  group('loading reviews', () {
    test("loads the member's own given and received reviews", () async {
      await reviews.createReview(_maha, _draftAbout(_sami, rating: 4));
      await reviews.createReview(_sami, _draftAbout(_maha, rating: 5));
      await reviews.createReview(_lina, _draftAbout(_maha, rating: 3));
      final demoReviews = repository.reviews.length;

      await ReviewService().refreshReviews(const [_me]);

      expect(ReviewService().stateOf(_me).status, ReviewsLoadStatus.loaded);
      expect(repository.reviews, hasLength(demoReviews + 3));
      final received = ReviewService().receivedBy(_me);
      expect([
        for (final r in received) r.authorId,
      ], containsAll([_sami, _lina]));
      expect(received.where((r) => r.authorId == 'm-omar'), isNotEmpty);
      expect(
        ReviewService().givenByCurrentUser().where((r) => r.subjectId == _sami),
        hasLength(1),
      );
    });

    test('loads other members once, unless refreshed', () async {
      await reviews.createReview(_lina, _draftAbout(_sami, rating: 2));

      await ReviewService().refreshReviews([_sami, 'm-omar']);
      await ReviewService().refreshReviews([_sami]);
      expect(reviews.fetches, 1);
      expect(ReviewService().averageRatingOf(_sami), 2);

      await reviews.createReview(_omar, _draftAbout(_sami, rating: 4));
      await ReviewService().refreshReviews([_sami], refresh: true);
      expect(reviews.fetches, 2);
      expect(ReviewService().averageRatingOf(_sami), 3);
      // Demo members' reviews stay as they were, without fetching.
      expect(
        ReviewService().stateOf('m-omar').status,
        ReviewsLoadStatus.loaded,
      );
      expect(ReviewService().receivedBy('m-omar'), isNotEmpty);
    });

    test('loading the same member twice at once fetches once', () async {
      final loading = reviews.holdFetch = Completer<void>();
      final first = ReviewService().refreshReviews([_sami]);
      final second = ReviewService().refreshReviews([_sami]);
      expect(ReviewService().stateOf(_sami).status, ReviewsLoadStatus.loading);
      loading.complete();
      await Future.wait([first, second]);
      expect(reviews.fetches, 1);
    });

    test('a failure is reported and can be retried', () async {
      reviews.failFetch = true;
      await ReviewService().refreshReviews(const [_me]);

      final failed = ReviewService().stateOf(_me);
      expect(failed.status, ReviewsLoadStatus.failed);
      expect(failed.message, 'Check your internet connection.');

      reviews.failFetch = false;
      await ReviewService().refreshReviews(const [_me]);
      expect(ReviewService().stateOf(_me).status, ReviewsLoadStatus.loaded);
    });

    test('a list arriving after an account switch is ignored', () async {
      await reviews.createReview(_sami, _draftAbout(_maha));
      final loading = reviews.holdFetch = Completer<void>();
      final refreshing = ReviewService().refreshReviews(const [_me]);
      auth.currentUid = _lina;
      loading.complete();
      await refreshing;

      expect(_onlineReviews(), isEmpty);
      expect(ReviewService().stateOf(_me).status, ReviewsLoadStatus.notLoaded);
    });

    test("another account starts with nothing loaded or hidden", () async {
      hidden.add(_sami);
      await ReviewService().refreshReviews([_sami]);
      expect(ReviewService().isHidden(_sami), isTrue);

      auth.currentUid = _lina;

      expect(ReviewService().isHidden(_sami), isFalse);
      expect(
        ReviewService().stateOf(_sami).status,
        ReviewsLoadStatus.notLoaded,
      );
      await ReviewService().refreshReviews([_sami]);
      expect(reviews.fetches, 2);
    });

    testWidgets('the Ratings screen loads, refreshes and retries', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3000);
      addTearDown(tester.view.resetPhysicalSize);
      repository.reviews.clear();
      reviews.failFetch = true;

      await tester.pumpWidget(_app(const ReviewsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your ratings'), findsOneWidget);
      expect(find.text('No reviews yet'), findsNothing);

      reviews.failFetch = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your ratings'), findsNothing);
      expect(find.text('No reviews yet'), findsOneWidget);

      await reviews.createReview(_sami, _draftAbout(_maha, rating: 4));
      await tester.fling(
        find.text('No reviews yet'),
        const Offset(0, 1500),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ReviewCard), findsOneWidget);
      expect(find.text('1 rating received'), findsOneWidget);
    });
  });

  group('visibility', () {
    setUp(() async {
      await reviews.createReview(_lina, _draftAbout(_sami, rating: 2));
      await reviews.createReview(_maha, _draftAbout(_sami, rating: 4));
    });

    test("a hidden member's ratings stay private, but stored", () async {
      hidden.add(_sami);
      await ReviewService().refreshReviews([_me, _sami]);

      expect(ReviewService().isHidden(_sami), isTrue);
      expect(ReviewService().receivedBy(_sami), isEmpty);
      expect(ReviewService().averageRatingOf(_sami), isNull);
      // Maha still has the rating she wrote, as the rules allow.
      expect(ReviewService().hasRatedMember(_sami), isTrue);
      expect(
        ReviewService().givenByCurrentUser().where((r) => r.subjectId == _sami),
        hasLength(1),
      );
      // Lina's rating is not on this device, but is kept online.
      expect(
        repository.reviews.where((r) => r.id == 'uid-lina_uid-sami'),
        isEmpty,
      );
      expect(reviews.storedData('uid-lina_uid-sami'), isNotNull);

      hidden.remove(_sami);
      await ReviewService().refreshReviews([_sami], refresh: true);
      expect(ReviewService().isHidden(_sami), isFalse);
      expect(ReviewService().averageRatingOf(_sami), 3);
    });

    test('the member always sees their own ratings', () async {
      hidden.add(_maha);
      await reviews.createReview(_sami, _draftAbout(_maha, rating: 5));

      await ReviewService().refreshReviews(const [_me]);

      expect(ReviewService().isHidden(_me), isFalse);
      expect(
        ReviewService().receivedBy(_me).where((r) => r.authorId == _sami),
        hasLength(1),
      );
    });

    testWidgets('profiles say when ratings are private', (tester) async {
      hidden.add(_sami);
      await tester.pumpWidget(
        _app(const PublicMemberProfileScreen(memberId: _sami)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ratings are private'), findsOneWidget);
      expect(find.byType(ReviewCard), findsNothing);
    });

    testWidgets("a public member's profile shows their ratings", (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 4000);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        _app(const PublicMemberProfileScreen(memberId: _sami)),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 ratings received'), findsOneWidget);
      expect(find.byType(ReviewCard), findsNWidgets(2));
      // Loaded once while the profile is open.
      expect(reviews.fetches, 1);
    });

    testWidgets('the summary shows loading, then the ratings', (tester) async {
      final loading = reviews.holdFetch = Completer<void>();
      await tester.pumpWidget(
        _app(const Scaffold(body: RatingSummary(memberId: _sami))),
      );
      final refreshing = ReviewService().refreshReviews([_sami]);
      await tester.pump();
      expect(find.text('Loading ratings…'), findsOneWidget);

      loading.complete();
      await refreshing;
      await tester.pump();
      expect(find.text('2 ratings received'), findsOneWidget);
    });
  });

  group('deleted accounts', () {
    testWidgets('their reviews stay, shown as by a Member', (tester) async {
      await reviews.createReview('uid-gone', _draftAbout(_maha, rating: 5));
      await ReviewService().refreshReviews(const [_me]);
      final review = ReviewService()
          .receivedBy(_me)
          .firstWhere((r) => r.authorId == 'uid-gone');

      await tester.pumpWidget(_app(Scaffold(body: ReviewCard(review: review))));

      expect(MemberService().nameOf('uid-gone'), 'Member');
      expect(find.textContaining('Member'), findsWidgets);
    });
  });

  group('badges', () {
    setUp(() {
      repository.reviews.clear();
      repository.awardedBadgeIds.clear();
      repository.notifications.clear();
    });

    bool earned(String id) =>
        BadgeService().badges().firstWhere((b) => b.id == id).isEarned;

    int notificationsFor(String title) => NotificationService()
        .all()
        .where((n) => n.title == 'Badge earned: $title')
        .length;

    test('Top Rated comes from ratings received online', () async {
      for (final author in [_sami, _lina, _omar]) {
        await reviews.createReview(author, _draftAbout(_maha, rating: 5));
      }
      expect(earned(BadgeConfig.topRated), isFalse);

      await ReviewService().refreshReviews(const [_me]);

      expect(earned(BadgeConfig.topRated), isTrue);
      expect(notificationsFor('Top Rated'), 1);
    });

    test('Helpful Reviewer comes from ratings given online', () async {
      await ReviewService().submitRating(requestFor(_samiTrade), 5, const []);
      await ReviewService().submitRating(requestFor(_linaTrade), 4, const []);
      expect(earned(BadgeConfig.helpfulReviewer), isFalse);
      await reviews.createReview(_maha, _draftAbout(_omar));

      await ReviewService().refreshReviews(const [_me], refresh: true);

      expect(earned(BadgeConfig.helpfulReviewer), isTrue);
      expect(notificationsFor('Helpful Reviewer'), 1);
    });

    test(
      'a badge no longer earned is taken away, and never announced twice',
      () async {
        // Three high ratings loaded on this device.
        for (final author in [_sami, _lina, _omar]) {
          repository.reviews.add(
            Review(
              id: '${author}_$_maha',
              authorId: author,
              subjectId: _me,
              comment: '',
              rating: 5,
              date: DateTime(2026),
            ),
          );
        }
        BadgeService().sync();
        expect(earned(BadgeConfig.topRated), isTrue);

        // Online there are only two.
        await reviews.createReview(_sami, _draftAbout(_maha, rating: 5));
        await reviews.createReview(_lina, _draftAbout(_maha, rating: 5));
        await ReviewService().refreshReviews(const [_me]);
        expect(earned(BadgeConfig.topRated), isFalse);

        await reviews.createReview(_omar, _draftAbout(_maha, rating: 5));
        await ReviewService().refreshReviews(const [_me], refresh: true);
        expect(earned(BadgeConfig.topRated), isTrue);
        expect(notificationsFor('Top Rated'), 1);
      },
    );

    test("another account's ratings never count", () async {
      for (final author in [_sami, _lina, _omar]) {
        await reviews.createReview(author, _draftAbout(_maha, rating: 5));
      }
      final loading = reviews.holdFetch = Completer<void>();
      final refreshing = ReviewService().refreshReviews(const [_me]);
      auth.currentUid = _lina;
      loading.complete();
      await refreshing;

      expect(earned(BadgeConfig.topRated), isFalse);
      expect(notificationsFor('Top Rated'), 0);
    });
  });
}
