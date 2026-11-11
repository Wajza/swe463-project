import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/blocked_members_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/listing_repository.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/saved_listings_repository.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/screens/listings/listing_details_screen.dart';
import 'package:souq_skills/screens/profile/public_member_profile_screen.dart';
import 'package:souq_skills/screens/profile/settings/blocked_members_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/safety_service.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _offline = BlockingException('Check your internet connection.');

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;
  int deletions = 0;

  @override
  String? get uid => currentUid;

  @override
  Future<void> deleteAccount() async {
    deletions++;
    await super.deleteAccount();
  }
}

/// Block lists online; loading and changes can be held or fail.
class _Blocked extends DemoBlockedMembersRepository {
  _Blocked({super.blocked});

  bool failFetch = false;
  bool failWrites = false;
  bool failUnblockAll = false;
  Completer<void>? holdFetch;
  Completer<void>? holdWrites;
  int writes = 0;

  @override
  Future<Set<String>> fetchBlockedIds(String uid) async {
    final waitFor = holdFetch;
    await waitFor?.future;
    if (failFetch) throw _offline;
    return super.fetchBlockedIds(uid);
  }

  @override
  Future<void> block(String uid, String blockedUid) async {
    await _write();
    return super.block(uid, blockedUid);
  }

  @override
  Future<void> unblock(String uid, String blockedUid) async {
    await _write();
    return super.unblock(uid, blockedUid);
  }

  @override
  Future<void> unblockAll(String uid) async {
    if (failUnblockAll) throw _offline;
    return super.unblockAll(uid);
  }

  Future<void> _write() async {
    writes++;
    final waitFor = holdWrites;
    await waitFor?.future;
    if (failWrites) throw _offline;
  }
}

User _user(String first, String last, String username, String phone) => User(
  id: User.currentUserId,
  firstName: first,
  lastName: last,
  username: username,
  phone: phone,
  city: 'Jeddah',
  isVerified: true,
);

Map<String, dynamic> _listing(String owner, String title) => {
  'ownerId': owner,
  'category': 'Cooking',
  'title': title,
  'offers': 'Baking',
  'wants': 'Piano',
  'distance': '',
  'description': '$title, in full.',
  'city': 'Riyadh',
  'availability': 'Weekends',
  'sessionsMinutes': 60,
  'onlineOnly': false,
  'womenOnly': false,
  'isPaused': false,
};

Future<void> _start(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, {String phone = '501234567'}) async {
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), phone);
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

Future<void> _signOut(WidgetTester tester) async {
  if (find.byTooltip('Settings').evaluate().isEmpty) {
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign out').last);
  await tester.pumpAndSettle();
}

/// Home's listing titles that are shown.
bool _onHome(String title) => find
    .descendant(of: find.byType(HomeScreen), matching: find.text(title))
    .evaluate()
    .isNotEmpty;

/// Wraps [screen] so it can show messages and be navigated from.
Widget _app(Widget screen) => MaterialApp(home: screen);

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Auth auth;
  late DemoProfileRepository profiles;
  late DemoListingRepository listings;
  late DemoSavedListingsRepository saved;
  late _Blocked blocked;

  void useBlocked(Map<String, Set<String>> initial) {
    blocked = _Blocked(blocked: initial);
    SafetyService.repository = blocked;
  }

  /// Signed in with listings, saved skills and blocks loaded, without the
  /// screens. (Member names load in the background; widget tests settle
  /// them with pumpAndSettle.)
  Future<void> signedInAndLoaded() async {
    AuthService().signIn();
    await ListingService().refresh();
  }

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
    listings = DemoListingRepository(
      documents: {
        'sami-1': _listing(_sami, 'Flutter from zero'),
        'lina-1': _listing(_lina, 'Calligraphy basics'),
        'maha-1': _listing(_maha, 'Learn Baking'),
      },
    );
    ListingService.repository = listings;
    saved = DemoSavedListingsRepository(
      saved: {
        _maha: {'sami-1', 'lina-1'},
      },
    );
    ListingService.savedRepository = saved;
    useBlocked({});
  });

  tearDown(() {
    ListingService.repository = null;
    ListingService.savedRepository = null;
    SafetyService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  group('blocking and unblocking', () {
    testWidgets('blocking from a profile saves online, then hides them', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await tester.tap(find.text('Flutter from zero'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sami Alharbi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(find.text('Sami Alharbi was blocked'), findsOneWidget);
      expect(await blocked.fetchBlockedIds(_maha), {_sami});
      expect(_onHome('Flutter from zero'), isFalse);
      expect(_onHome('Calligraphy basics'), isTrue);
      // Hidden from Saved skills, but still saved for when they are unblocked.
      expect(ListingService().saved().map((l) => l.id), ['lina-1']);
      expect(await saved.fetchSavedIds(_maha), {'sami-1', 'lina-1'});
    });

    testWidgets('a failed block changes nothing and says why', (tester) async {
      await signedInAndLoaded();
      blocked.failWrites = true;
      await tester.pumpWidget(
        _app(const PublicMemberProfileScreen(memberId: _sami)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Member profile'), findsOneWidget);
      expect(SafetyService().isBlocked(_sami), isFalse);
      expect(await blocked.fetchBlockedIds(_maha), isEmpty);
    });

    test('rapid taps send one change at a time', () async {
      await signedInAndLoaded();
      final slow = blocked.holdWrites = Completer<void>();

      final first = SafetyService().blockMember(_sami);
      final second = SafetyService().blockMember(_sami);
      slow.complete();
      await Future.wait([first, second]);

      expect(blocked.writes, 1);
      expect(SafetyService().isBlocked(_sami), isTrue);
    });

    test('nobody can block themselves', () async {
      await signedInAndLoaded();

      for (final self in [User.currentUserId, _maha]) {
        await expectLater(
          SafetyService().blockMember(self),
          throwsA(same(BlockingException.cannotBlockYourself)),
        );
      }
      expect(blocked.writes, 0);
      expect(SafetyService().blockedIds, isEmpty);
    });

    test(
      'demo members are blocked on this device only, and stay blocked',
      () async {
        await signedInAndLoaded();

        await SafetyService().blockMember('m-omar');
        await ListingService().refresh();

        expect(blocked.writes, 0);
        expect(await blocked.fetchBlockedIds(_maha), isEmpty);
        expect(SafetyService().isBlocked('m-omar'), isTrue);
      },
    );

    testWidgets("a blocked member's profile offers only Unblock", (
      tester,
    ) async {
      useBlocked({
        _maha: {_sami},
      });
      await signedInAndLoaded();
      await tester.pumpWidget(
        _app(const PublicMemberProfileScreen(memberId: _sami)),
      );
      await tester.pumpAndSettle();

      expect(find.text('You blocked this member'), findsOneWidget);
      expect(find.text('Propose a trade'), findsNothing);
      expect(find.byTooltip('Message'), findsNothing);

      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();

      expect(find.text('Sami Alharbi was unblocked'), findsOneWidget);
      expect(find.text('You blocked this member'), findsNothing);
      expect(find.text('Propose a trade'), findsOneWidget);
      expect(await blocked.fetchBlockedIds(_maha), isEmpty);
    });

    testWidgets(
      "a blocked owner's listing shows a notice and no way to reach them",
      (tester) async {
        useBlocked({
          _maha: {_sami},
        });
        await signedInAndLoaded();
        await tester.pumpWidget(
          _app(const ListingDetailsScreen(listingId: 'sami-1')),
        );
        await tester.pumpAndSettle();

        expect(find.text('You blocked this member'), findsOneWidget);
        expect(find.text('Propose a trade'), findsNothing);
        await tester.tap(find.byTooltip('More options'));
        await tester.pumpAndSettle();
        expect(find.text('Message member'), findsNothing);
        expect(find.text('Share listing'), findsOneWidget);
      },
    );
  });

  group('Blocked members', () {
    testWidgets('lists every blocked member, by name if known, and unblocks', (
      tester,
    ) async {
      useBlocked({
        _maha: {_sami, 'uid-gone'},
      });
      await signedInAndLoaded();
      await tester.pumpWidget(_app(const BlockedMembersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sami Alharbi'), findsOneWidget);
      // An account whose public profile is gone can still be unblocked.
      expect(find.textContaining('Member'), findsWidgets);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Sami Alharbi'),
          matching: find.text('Unblock'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sami Alharbi'), findsNothing);
      expect(await blocked.fetchBlockedIds(_maha), {'uid-gone'});
    });

    testWidgets('a failed unblock keeps them and says why', (tester) async {
      useBlocked({
        _maha: {_sami},
      });
      await signedInAndLoaded();
      blocked.failWrites = true;
      await tester.pumpWidget(_app(const BlockedMembersScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Sami Alharbi'), findsOneWidget);
      expect(SafetyService().isBlocked(_sami), isTrue);
    });

    testWidgets('shows an error with retry when the list cannot load', (
      tester,
    ) async {
      useBlocked({
        _maha: {_sami},
      });
      blocked.failFetch = true;
      AuthService().signIn();
      await tester.pumpWidget(_app(const BlockedMembersScreen()));
      await ListingService().refresh();
      await tester.pumpAndSettle();

      expect(find.text('Could not load skills'), findsOneWidget);
      expect(find.text('Sami Alharbi'), findsNothing);

      blocked.failFetch = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Sami Alharbi'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('Browse waits for the block list, and retries when it fails', (
      tester,
    ) async {
      useBlocked({
        _maha: {_sami},
      });
      blocked.failFetch = true;
      await _start(tester);
      await _signIn(tester);

      expect(find.text('Could not load skills'), findsOneWidget);
      expect(_onHome('Flutter from zero'), isFalse);
      expect(_onHome('Calligraphy basics'), isFalse);

      blocked.failFetch = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_onHome('Calligraphy basics'), isTrue);
      expect(_onHome('Flutter from zero'), isFalse);
    });

    testWidgets('blocks survive a refresh and signing out and back in', (
      tester,
    ) async {
      await _start(tester);
      await _signIn(tester);
      await SafetyService().blockMember(_sami);
      await tester.pumpAndSettle();

      await ListingService().refresh();
      await tester.pumpAndSettle();
      expect(_onHome('Flutter from zero'), isFalse);

      await _signOut(tester);
      await _signIn(tester);
      expect(_onHome('Flutter from zero'), isFalse);
      expect(SafetyService().isBlocked(_sami), isTrue);
    });
  });

  group('separate accounts', () {
    test("loading another account's list replaces every real block, keeping demo ones", () async {
      useBlocked({
        _maha: {_sami},
        _lina: {'uid-someone'},
      });
      await signedInAndLoaded();
      await SafetyService().blockMember('m-omar');
      expect(SafetyService().blockedIds, {_sami, 'm-omar'});

      auth.currentUid = _lina;
      await ListingService().refresh();

      expect(SafetyService().blockedIds, {'uid-someone', 'm-omar'});
    });

    testWidgets(
      "after switching accounts, the previous account's blocks never apply",
      (tester) async {
        useBlocked({
          _maha: {_sami},
        });
        await _start(tester);
        await _signIn(tester);
        expect(_onHome('Flutter from zero'), isFalse);
        await _signOut(tester);

        auth.currentUid = _lina;
        AuthService.deviceAccount = MemoryDeviceAccountStore(_lina);
        await _signIn(tester, phone: '523456789');

        expect(_onHome('Flutter from zero'), isTrue);
        expect(SafetyService().isBlocked(_sami), isFalse);
        expect(await blocked.fetchBlockedIds(_maha), {_sami});
      },
    );

    testWidgets(
      "a different account signing in starts fresh, without the previous account's demo blocks",
      (tester) async {
        useBlocked({
          _maha: {_sami},
          _lina: {'uid-someone'},
        });
        await _start(tester);
        await _signIn(tester);
        // Maha's own data on this device: a demo block and a report.
        await SafetyService().blockMember('m-omar');
        SafetyService().reportMember(memberId: 'm-omar', reason: 'Spam');
        await tester.pumpAndSettle();
        expect(SafetyService().blockedIds, {_sami, 'm-omar'});
        expect(SafetyService().cases(), isNotEmpty);
        expect(await AuthService.deviceAccount.read(), _maha);
        await _signOut(tester);

        // Lina signs in on the same device, which still belongs to Maha, so
        // AuthService._openAccount resets it with SeedData.newMember.
        auth.currentUid = _lina;
        await _signIn(tester, phone: '523456789');

        expect(await AuthService.deviceAccount.read(), _lina);
        expect(repository.currentUser.name, 'Lina Saleh');
        expect(SafetyService().isBlocked('m-omar'), isFalse);
        expect(SafetyService().isBlocked(_sami), isFalse);
        // Only Lina's own blocks, loaded from her list.
        expect(SafetyService().blockedIds, {'uid-someone'});
        expect(SafetyService().cases(), isEmpty);
        // Maha's blocks are still hers online.
        expect(await blocked.fetchBlockedIds(_maha), {_sami});
      },
    );

    test(
      'a block finishing after an account switch changes nothing here',
      () async {
        await signedInAndLoaded();
        final slow = blocked.holdWrites = Completer<void>();
        final blocking = SafetyService().blockMember(_sami);

        auth.currentUid = _lina;
        slow.complete();
        await blocking;

        expect(SafetyService().isBlocked(_sami), isFalse);
        // It was saved for the account that asked for it.
        expect(await blocked.fetchBlockedIds(_maha), {_sami});
      },
    );

    test('a block list arriving after an account switch is ignored', () async {
      useBlocked({
        _maha: {_sami},
        _lina: const {},
      });
      AuthService().signIn();
      final slow = blocked.holdFetch = Completer<void>();
      final first = ListingService().refresh();

      auth.currentUid = _lina;
      blocked.holdFetch = null;
      await ListingService().refresh();
      slow.complete();
      await first;

      expect(SafetyService().isBlocked(_sami), isFalse);
    });
  });

  group('account deletion', () {
    test("removes only this account's own blocks", () async {
      useBlocked({
        _maha: {_sami, _lina},
        _sami: {_maha},
        _lina: {_sami},
      });
      await signedInAndLoaded();

      await AuthService().deleteAccount();

      expect(await blocked.fetchBlockedIds(_maha), isEmpty);
      expect(await blocked.fetchBlockedIds(_sami), {_maha});
      expect(await blocked.fetchBlockedIds(_lina), {_sami});
      expect(auth.deletions, 1);
    });

    test('a failed cleanup stops the deletion', () async {
      useBlocked({
        _maha: {_sami},
      });
      await signedInAndLoaded();
      blocked.failUnblockAll = true;

      await expectLater(
        AuthService().deleteAccount(),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            contains('account was not deleted'),
          ),
        ),
      );

      expect(await blocked.fetchBlockedIds(_maha), {_sami});
      expect(await profiles.fetchProfile(_maha), isNotNull);
      expect(auth.deletions, 0);
      expect(repository.isSignedIn, isTrue);
    });
  });

  group("Developer B's filters, unchanged", () {
    test(
      'chats and group invites still leave out blocked demo members',
      () async {
        SafetyService.repository = null;
        ListingService.repository = null;
        ListingService.savedRepository = null;
        AuthService.profiles = null;
        AuthService().signIn();
        final group = GroupTradeService().byId('g-language')!;
        bool chatsWithSami() =>
            ChatService().conversations().any((c) => c.memberId == 'm-sami');
        expect(chatsWithSami(), isTrue);
        expect(GroupTradeService().inviteCandidates(group, 'sami'), isNotEmpty);

        // Offline, blocking stays immediate and on this device.
        final blocking = SafetyService().blockMember('m-sami');
        expect(SafetyService().isBlocked('m-sami'), isTrue);
        await blocking;

        expect(chatsWithSami(), isFalse);
        expect(GroupTradeService().inviteCandidates(group, 'sami'), isEmpty);
      },
    );

    test('group invites also leave out blocked real members', () async {
      await signedInAndLoaded();
      await MemberService().loadMembers([_sami]);
      final group = GroupTradeService().byId('g-language')!;
      expect(GroupTradeService().inviteCandidates(group, 'sami_a'), isNotEmpty);

      await SafetyService().blockMember(_sami);

      expect(GroupTradeService().inviteCandidates(group, 'sami_a'), isEmpty);
    });
  });
}
