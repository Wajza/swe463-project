import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/blocked_members_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/data/report_repository.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/screens/profile/public_member_profile_screen.dart';
import 'package:souq_skills/screens/profile/settings/blocked_members_screen.dart';
import 'package:souq_skills/screens/safety/report_member_screen.dart';
import 'package:souq_skills/screens/safety/safety_centre_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/services/trade_service.dart';

import 'support/memory_data_source.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';
const _offline = ReportException('Check your internet connection.');

/// The offline sign-in with a Firebase-like uid that can change.
class _Auth extends DemoAuthRepository {
  _Auth() : super(isKnownPhone: AuthService().isKnownPhone);

  String? currentUid = _maha;

  @override
  String? get uid => currentUid;
}

/// Reports online; sending and loading can be held back or fail.
class _Reports extends DemoReportRepository {
  bool failWrites = false;
  bool failFetch = false;
  Completer<void>? holdWrites;
  Completer<void>? holdFetch;
  int writes = 0;

  @override
  Future<DisputeCase> createReport(String uid, ReportDraft draft) async {
    writes++;
    final waitFor = holdWrites;
    await waitFor?.future;
    if (failWrites) throw _offline;
    return super.createReport(uid, draft);
  }

  @override
  Future<List<DisputeCase>> fetchMyReports(String uid) async {
    final waitFor = holdFetch;
    await waitFor?.future;
    if (failFetch) throw _offline;
    return super.fetchMyReports(uid);
  }
}

class _Blocked extends DemoBlockedMembersRepository {
  bool failWrites = false;

  @override
  Future<void> block(String uid, String blockedUid) async {
    if (failWrites) {
      throw const BlockingException('Check your internet connection.');
    }
    return super.block(uid, blockedUid);
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

/// Picks [reason], optionally types [details], and submits.
Future<void> _fillAndSubmit(
  WidgetTester tester,
  String reason, {
  String details = '',
  String submit = 'Submit report',
}) async {
  await tester.tap(find.text(reason));
  await tester.pump();
  if (details.isNotEmpty) {
    await tester.enterText(find.byType(TextField), details);
    await tester.pump();
  }
  await tester.tap(find.text(submit));
  await tester.pump();
}

/// The online cases on this device, i.e. not made on this device only.
List<DisputeCase> _onlineCases() => [
  for (final item in SafetyService().cases())
    if (!item.id.startsWith('c-')) item,
];

void main() {
  final repository = Repository.instance;
  final originalAuth = AuthService.repository;
  late _Auth auth;
  late DemoProfileRepository profiles;
  late _Reports reports;
  late _Blocked blocked;

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
    AuthService.profiles = profiles;
    reports = _Reports();
    SafetyService.reportRepository = reports;
    blocked = _Blocked();
    SafetyService.repository = blocked;
    AuthService().signIn();
    await MemberService().loadMembers([_sami]);
  });

  tearDown(() {
    SafetyService.reportRepository = null;
    SafetyService.repository = null;
    AuthService.profiles = null;
    AuthService.deviceAccount = null;
    AuthService.repository = originalAuth;
  });

  group('reporting a member', () {
    testWidgets('is saved online first, then shown as received', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ReportMemberScreen(memberId: _sami)));
      final sending = reports.holdWrites = Completer<void>();

      await _fillAndSubmit(
        tester,
        'Spam or scam',
        details: 'Asked me to pay outside the app.',
      );

      // Nothing is shown as sent before it was.
      expect(find.text('Sending…'), findsOneWidget);
      expect(_onlineCases(), isEmpty);

      sending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Would you also like to block Sami Alharbi?'), findsOne);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Report received'), findsOneWidget);
      expect(find.text('Asked me to pay outside the app.'), findsOneWidget);
      expect(find.text('Sami Alharbi'), findsOneWidget);
      final stored = reports.storedData(
        _maha,
        'uid-maha_memberReport_uid-sami',
      )!;
      expect(stored['details'], 'Asked me to pay outside the app.');
      expect(_onlineCases().single.memberId, _sami);
      // Never blocked without asking.
      expect(SafetyService().isBlocked(_sami), isFalse);
    });

    testWidgets('a failure keeps the form and can be retried', (tester) async {
      await tester.pumpWidget(_app(const ReportMemberScreen(memberId: _sami)));
      reports.failWrites = true;

      await _fillAndSubmit(tester, 'Harassment');
      await tester.pumpAndSettle();

      expect(find.text('Check your internet connection.'), findsOneWidget);
      expect(find.text('Submit report'), findsOneWidget);
      expect(_onlineCases(), isEmpty);

      reports.failWrites = false;
      await tester.tap(find.text('Submit report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Report received'), findsOneWidget);
      expect(_onlineCases(), hasLength(1));
    });

    testWidgets('tapping twice sends it once', (tester) async {
      await tester.pumpWidget(_app(const ReportMemberScreen(memberId: _sami)));
      final sending = reports.holdWrites = Completer<void>();

      await _fillAndSubmit(tester, 'Harassment');
      await tester.tap(find.text('Sending…'), warnIfMissed: false);
      await tester.pump();
      expect(reports.writes, 1);

      // The same report sent twice at once is sent once, too.
      final again = SafetyService().reportMember(
        memberId: _sami,
        reason: 'Harassment',
      );
      sending.complete();
      await again;
      await tester.pumpAndSettle();
      expect(reports.writes, 1);
    });

    testWidgets('a second report of the same member is refused', (
      tester,
    ) async {
      await SafetyService().reportMember(memberId: _sami, reason: 'Harassment');
      await tester.pumpWidget(_app(const ReportMemberScreen(memberId: _sami)));

      await _fillAndSubmit(tester, 'Spam or scam');
      await tester.pumpAndSettle();

      expect(find.text('You already reported this member.'), findsOneWidget);
      expect(_onlineCases(), hasLength(1));
    });

    test('nobody can report themselves', () async {
      for (final self in [User.currentUserId, _maha]) {
        await expectLater(
          SafetyService().reportMember(memberId: self, reason: 'Spam or scam'),
          throwsA(same(ReportException.cannotReportYourself)),
        );
      }
      expect(reports.writes, 0);
    });

    test('demo members are reported on this device only, once', () async {
      final report = await SafetyService().reportMember(
        memberId: 'm-omar',
        reason: 'Fake profile',
        details: 'Not a real person.',
      );

      expect(reports.writes, 0);
      expect(
        SafetyService().caseById(report.id)!.details,
        'Not a real person.',
      );
      await expectLater(
        SafetyService().reportMember(memberId: 'm-omar', reason: 'Other'),
        throwsA(
          isA<ReportException>().having(
            (e) => e.message,
            'message',
            'You already reported this member.',
          ),
        ),
      );
    });

    test('details over 500 characters are refused', () async {
      await expectLater(
        SafetyService().reportMember(
          memberId: _sami,
          reason: 'Other',
          details: 'x' * 501,
        ),
        throwsA(same(ReportException.detailsTooLong)),
      );
      expect(_onlineCases(), isEmpty);
    });

    testWidgets('blocking can be offered afterwards, and done if asked', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const ReportMemberScreen(memberId: _sami)));

      await _fillAndSubmit(tester, 'Harassment');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(find.text('Report received. Sami Alharbi was blocked.'), findsOne);
      expect(await blocked.fetchBlockedIds(_maha), {_sami});
      expect(_onlineCases(), hasLength(1));
    });

    testWidgets('a failed block does not undo the report', (tester) async {
      blocked.failWrites = true;
      await tester.pumpWidget(_app(const ReportMemberScreen(memberId: _sami)));

      await _fillAndSubmit(tester, 'Harassment');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Report received, but Sami Alharbi could not'),
        findsOneWidget,
      );
      expect(find.text('Harassment'), findsOneWidget);
      expect(
        reports.storedData(_maha, 'uid-maha_memberReport_uid-sami'),
        isNotNull,
      );
      expect(SafetyService().isBlocked(_sami), isFalse);
    });

    testWidgets('a blocked member can be reported from their profile', (
      tester,
    ) async {
      await SafetyService().blockMember(_sami);
      await tester.pumpWidget(
        _app(const PublicMemberProfileScreen(memberId: _sami)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report member'));
      await tester.pumpAndSettle();

      await _fillAndSubmit(tester, 'Harassment');
      await tester.pumpAndSettle();

      // Already blocked, so blocking is not offered again.
      expect(
        find.text('Would you also like to block Sami Alharbi?'),
        findsNothing,
      );
      expect(find.text('Report received'), findsOneWidget);
      expect(_onlineCases(), hasLength(1));
    });

    testWidgets('Blocked members offers Report next to Unblock', (
      tester,
    ) async {
      await SafetyService().blockMember(_sami);
      await tester.pumpWidget(_app(const BlockedMembersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Unblock'), findsOneWidget);
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Report member'), findsOneWidget);
    });
  });

  group('trades and complaints', () {
    test('a trade report and a complaint are sent online', () async {
      final tradeReport = await SafetyService().reportTrade(
        tradeId: 't-sami',
        reason: 'Member did not attend',
      );
      final complaint = await SafetyService().fileComplaint(
        'A trade',
        details: 'It was cancelled late.',
      );

      expect(tradeReport.id, 'uid-maha_tradeReport_t-sami');
      expect(reports.storedData(_maha, tradeReport.id)!['tradeId'], 't-sami');
      expect(
        reports.storedData(_maha, complaint.id)!['details'],
        'It was cancelled late.',
      );
      expect(
        NotificationService().all().first.message,
        SafetyService.complaintReceivedMessage,
      );
      await expectLater(
        SafetyService().reportTrade(tradeId: 't-sami', reason: 'Other'),
        throwsA(
          isA<ReportException>().having(
            (e) => e.message,
            'message',
            'You already reported this trade.',
          ),
        ),
      );
    });

    test(
      'a dispute is saved online before the trade is marked disputed',
      () async {
        final sending = reports.holdWrites = Completer<void>();
        final dispute = SafetyService().submitTradeDispute(
          tradeId: 't-sami',
          reason: 'Unsafe behaviour',
        );
        await pumpEventQueue();
        expect(
          TradeService().byId('t-sami')!.status,
          isNot(TradeStatus.disputed),
        );
        expect(_onlineCases(), isEmpty);

        sending.complete();
        final saved = await dispute;

        expect(saved.id, 'uid-maha_tradeDispute_t-sami');
        expect(TradeService().byId('t-sami')!.status, TradeStatus.disputed);
        expect(SafetyService().caseForTrade('t-sami')!.id, saved.id);
      },
    );

    test('a failed dispute leaves the trade as it was', () async {
      reports.failWrites = true;
      final before = TradeService().byId('t-sami')!.status;

      await expectLater(
        SafetyService().submitTradeDispute(
          tradeId: 't-sami',
          reason: 'Unsafe behaviour',
        ),
        throwsA(same(_offline)),
      );

      expect(TradeService().byId('t-sami')!.status, before);
      expect(_onlineCases(), isEmpty);
    });

    test("the dispute screen's synchronous dispute still works as before", () {
      final dispute = SafetyService().disputeTrade(
        tradeId: 't-sami',
        reason: 'Unsafe behaviour',
      );

      expect(TradeService().byId('t-sami')!.status, TradeStatus.disputed);
      expect(SafetyService().caseById(dispute.id), isNotNull);
      expect(dispute.id, startsWith('c-'));
      expect(reports.writes, 0);
    });
  });

  group('Safety Centre', () {
    testWidgets('shows a spinner, then the reports', (tester) async {
      await SafetyService().reportMember(memberId: _sami, reason: 'Harassment');
      final number = _onlineCases().single.caseNumber;
      repository.disputes.removeWhere((c) => !c.id.startsWith('c-'));
      SafetyService.reportRepository = reports;
      final loading = reports.holdFetch = Completer<void>();

      await tester.pumpWidget(_app(const SafetyCentreScreen()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(number), findsNothing);

      loading.complete();
      await tester.pumpAndSettle();
      expect(find.text(number), findsOneWidget);
      expect(find.textContaining('Member report • Harassment'), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);

      await tester.tap(find.text(number));
      await tester.pumpAndSettle();
      expect(find.text('Case $number'), findsOneWidget);
    });

    testWidgets('has a real empty state', (tester) async {
      repository.disputes.clear();

      await tester.pumpWidget(_app(const SafetyCentreScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No reports yet'), findsOneWidget);
    });

    testWidgets('explains a failed load, retries and refreshes', (
      tester,
    ) async {
      reports.failFetch = true;
      await tester.pumpWidget(_app(const SafetyCentreScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your reports'), findsOneWidget);
      expect(find.text('Check your internet connection.'), findsOneWidget);

      reports.failFetch = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Could not load your reports'), findsNothing);

      // Sent from another device, then pulled in.
      final elsewhere = await reports.createReport(
        _maha,
        const ReportDraft(kind: CaseKind.complaint, reason: 'My wallet'),
      );
      await tester.fling(
        find.text('Meet safely'),
        const Offset(0, 1500),
        1000,
      );
      await tester.pumpAndSettle();
      expect(find.text(elsewhere.caseNumber), findsOneWidget);
    });
  });

  group('separate accounts', () {
    test("another account never sees the previous account's reports", () async {
      await SafetyService().reportMember(memberId: _sami, reason: 'Harassment');
      await SafetyService().refreshReports();
      expect(_onlineCases(), hasLength(1));

      auth.currentUid = _lina;
      expect(SafetyService().hasCurrentReports, isFalse);
      await SafetyService().refreshReports();

      expect(SafetyService().hasCurrentReports, isTrue);
      expect(_onlineCases(), isEmpty);
      // Still Maha's online.
      expect(await reports.fetchMyReports(_maha), hasLength(1));
    });

    test('a list arriving after an account switch is ignored', () async {
      await SafetyService().reportMember(memberId: _sami, reason: 'Harassment');
      repository.disputes.removeWhere((c) => !c.id.startsWith('c-'));
      final slow = reports.holdFetch = Completer<void>();
      final loading = SafetyService().refreshReports();

      auth.currentUid = _lina;
      slow.complete();
      await loading;

      expect(_onlineCases(), isEmpty);
      expect(SafetyService().hasCurrentReports, isFalse);
    });

    test(
      'a report finishing after an account switch is not shown here',
      () async {
        final slow = reports.holdWrites = Completer<void>();
        final sending = SafetyService().reportMember(
          memberId: _sami,
          reason: 'Harassment',
        );

        auth.currentUid = _lina;
        slow.complete();
        await sending;

        expect(_onlineCases(), isEmpty);
        // It was still sent, as the account that sent it.
        expect(await reports.fetchMyReports(_maha), hasLength(1));
      },
    );
  });

  test('deleting the account keeps its reports for moderation', () async {
    final report = await SafetyService().reportMember(
      memberId: _sami,
      reason: 'Harassment',
    );

    await AuthService().deleteAccount();

    expect(repository.isSignedIn, isFalse);
    expect(reports.storedData(_maha, report.id), isNotNull);
    expect(await reports.fetchMyReports(_maha), hasLength(1));
  });
}
