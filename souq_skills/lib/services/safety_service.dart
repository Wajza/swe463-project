import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/data/blocked_members_repository.dart';
import 'package:souq_skills/data/report_repository.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'member_service.dart';
import 'notification_service.dart';
import 'repository.dart';
import 'seed_data.dart';
import 'trade_service.dart';

export 'package:souq_skills/data/blocked_members_repository.dart'
    show BlockingException;
export 'package:souq_skills/data/report_repository.dart' show ReportException;

class SafetyService {
  static const complaintReceivedMessage =
      'We received your complaint. You will get feedback from us soon.';

  final Repository _repo = Repository.instance;

  /// The current member's cases, newest first.
  List<DisputeCase> cases() =>
      _repo.disputes.reversed.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  DisputeCase? caseById(String id) => _repo.find(_repo.disputes, id);

  DisputeCase? caseForTrade(String tradeId) {
    for (final item in cases()) {
      if (item.tradeId == tradeId) return item;
    }
    return null;
  }

  static BlockedMembersRepository? _blocked;

  /// Where real members' blocks are kept online: Firestore once Firebase
  /// has been initialized. Null in the offline demo, where every block
  /// stays on this device. Can be replaced, e.g. with a fake.
  static BlockedMembersRepository? get repository =>
      _blocked ??
      (Firebase.apps.isEmpty
          ? null
          : _blocked = FirebaseBlockedMembersRepository());
  static set repository(BlockedMembersRepository? value) => _blocked = value;

  /// Members whose block is being changed online right now.
  static final ValueNotifier<Set<String>> changingIds = ValueNotifier(const {});

  /// The built-in demo members, whose blocks always stay on this device.
  static final Set<String> _demoMemberIds = {
    for (final member in SeedData.demo().members) member.id,
  };

  static bool isDemoMember(String id) => _demoMemberIds.contains(id);

  /// Whether the current member blocked [memberId].
  bool isBlocked(String memberId) => _repo.blockedMemberIds.contains(memberId);

  /// The ids the current member blocked, for other features to filter by.
  Set<String> get blockedIds => Set.unmodifiable(_repo.blockedMemberIds);

  bool isChanging(String memberId) => changingIds.value.contains(memberId);

  /// Every blocked member, including any not known on this device yet, so
  /// each can be unblocked.
  List<User> blockedMembers() => [
    for (final id in _repo.blockedMemberIds)
      MemberService().byId(id) ??
          User(id: id, firstName: 'Member', lastName: ''),
  ];

  /// Blocks [memberId]. A real member is blocked online first, and only
  /// then on this device; a demo member on this device only.
  ///
  /// Throws a [BlockingException] and changes nothing if it fails, or for
  /// the current member. Taps while it is under way are ignored, and
  /// nothing changes here if another account signed in meanwhile.
  Future<void> blockMember(String memberId) =>
      _change(memberId, blocking: true);

  /// Unblocks [memberId], online first for a real member. Throws a
  /// [BlockingException] and changes nothing if it fails.
  Future<void> unblockMember(String memberId) =>
      _change(memberId, blocking: false);

  Future<void> _change(String memberId, {required bool blocking}) async {
    final uid = AuthService.repository.uid;
    if (memberId == User.currentUserId || (uid != null && memberId == uid)) {
      throw BlockingException.cannotBlockYourself;
    }
    final online = repository;
    if (online != null && !isDemoMember(memberId)) {
      if (isChanging(memberId)) return;
      if (uid == null) {
        throw const BlockingException(
          'Your session has expired. Sign in again.',
        );
      }
      changingIds.value = {...changingIds.value, memberId};
      try {
        await (blocking
            ? online.block(uid, memberId)
            : online.unblock(uid, memberId));
      } finally {
        changingIds.value = {...changingIds.value}..remove(memberId);
      }
      // Another account signed in meanwhile: its blocks are not this one's.
      if (uid != AuthService.repository.uid) return;
    }
    blocking
        ? _repo.blockedMemberIds.add(memberId)
        : _repo.blockedMemberIds.remove(memberId);
    _repo.emitChange();
  }

  /// Replaces every real member's block on this device with [fetched], the
  /// signed-in account's own list, so no account's blocks carry over to
  /// another. Demo members' blocks, which only live here, are kept. The
  /// caller publishes the change.
  void replaceOnlineBlocks(Set<String> fetched) {
    final demo = _repo.blockedMemberIds.where(isDemoMember).toSet();
    _repo.blockedMemberIds
      ..clear()
      ..addAll(demo)
      ..addAll(fetched.where((id) => !isDemoMember(id)));
  }

  /// Before the signed-in account is deleted: removes all of its own
  /// blocks online, then its real members' blocks here. Throws a
  /// [BlockingException] if any may remain. Offline it does nothing.
  Future<void> removeAccountData() async {
    final online = repository;
    final uid = AuthService.repository.uid;
    if (online == null) return;
    if (uid == null) {
      throw const BlockingException('Your session has expired. Sign in again.');
    }
    await online.unblockAll(uid);
    _repo.blockedMemberIds.removeWhere((id) => !isDemoMember(id));
    _repo.emitChange();
  }

  // Reports are sent online first and only then shown on this device, so no
  // report is shown as sent before it was. Each throws a [ReportException]
  // if it cannot be sent, is a duplicate, or reports the current member.
  // Reports about demo members, and every report in the offline demo, are
  // kept on this device only.

  /// Reports member [memberId] for [reason], with optional [details].
  Future<DisputeCase> reportMember({
    required String memberId,
    required String reason,
    String? details,
  }) => _report(
    ReportDraft(
      kind: CaseKind.memberReport,
      reason: reason,
      details: details ?? '',
      memberId: memberId,
    ),
    localOnly: isDemoMember(memberId),
  );

  /// Reports trade [tradeId]. Trades are not shared online yet, so the id
  /// stored is this device's and cannot be checked by the server.
  Future<DisputeCase> reportTrade({
    required String tradeId,
    required String reason,
    String? details,
  }) => _report(
    ReportDraft(
      kind: CaseKind.tradeReport,
      reason: reason,
      details: details ?? '',
      tradeId: tradeId,
    ),
  );

  /// Opens a dispute online first; only once it is saved is the trade
  /// marked as disputed on this device, as [disputeTrade] does.
  ///
  /// The dispute screen still calls [disputeTrade], which stays on this
  /// device; it should switch to this method, awaiting it and showing its
  /// errors, for disputes to be shared online.
  Future<DisputeCase> submitTradeDispute({
    required String tradeId,
    required String reason,
    String? details,
  }) => _report(
    ReportDraft(
      kind: CaseKind.tradeDispute,
      reason: reason,
      details: details ?? '',
      tradeId: tradeId,
    ),
    afterSaved: () => _markDisputed(tradeId),
  );

  /// Sends a complaint about [topic], then confirms it with a notification.
  Future<DisputeCase> fileComplaint(String topic, {String? details}) async {
    final complaint = await _report(
      ReportDraft(
        kind: CaseKind.complaint,
        reason: topic,
        details: details ?? '',
      ),
    );
    NotificationService().push(
      title: 'Complaint received',
      message: complaintReceivedMessage,
      type: NotificationType.system,
      route: AppRoutes.disputeCaseDetails,
      routeArgument: complaint.id,
    );
    return complaint;
  }

  /// Opens a dispute on this device only, straight away. Kept as it was
  /// for the dispute screen; [submitTradeDispute] is the online version.
  DisputeCase disputeTrade({required String tradeId, required String reason}) {
    _markDisputed(tradeId);
    return _file(CaseKind.tradeDispute, reason, tradeId: tradeId);
  }

  void _markDisputed(String tradeId) {
    _repo.update(
      _repo.trades,
      tradeId,
      (trade) => trade.copyWith(status: TradeStatus.disputed),
    );
    // A trade with a real member is disputed for both members; the case
    // itself is already saved.
    TradeService().markDisputedOnline(tradeId).catchError((Object _) {});
  }

  static ReportRepository? _reports;

  /// Where reports are sent online: Firestore once Firebase has been
  /// initialized. Null in the offline demo, which keeps reports on this
  /// device. Can be replaced, e.g. with a fake.
  static ReportRepository? get reportRepository =>
      _reports ??
      (Firebase.apps.isEmpty ? null : _reports = FirebaseReportRepository());
  static set reportRepository(ReportRepository? value) {
    _reports = value;
    _reportsLoadedFor = null;
    _loadingReports = null;
    reportsState.value = const ReportsLoadState(ReportsLoadStatus.notLoaded);
  }

  /// Progress of [refreshReports], for the Safety Centre.
  static final ValueNotifier<ReportsLoadState> reportsState = ValueNotifier(
    const ReportsLoadState(ReportsLoadStatus.notLoaded),
  );

  static String? _reportsLoadedFor;
  static Future<void>? _loadingReports;
  static String? _loadingReportsFor;

  /// Reports being sent right now, so the same one is never sent twice.
  static final Map<String, Future<DisputeCase>> _sending = {};

  /// Whether the cases on this device can be shown: always offline, and
  /// online once the signed-in account's reports have been loaded. Until
  /// then they may be another account's.
  bool get hasCurrentReports =>
      reportRepository == null ||
      (_reportsLoadedFor != null &&
          _reportsLoadedFor == AuthService.repository.uid);

  /// Replaces the reports shown on this device with the signed-in
  /// account's own, keeping cases that only live here (demo reports and
  /// disputes opened on this device). Never throws: the outcome is in
  /// [reportsState]. Does nothing offline.
  Future<void> refreshReports() {
    final online = reportRepository;
    if (online == null) return Future.value();
    final uid = AuthService.repository.uid;
    if (_loadingReports != null && _loadingReportsFor == uid) {
      return _loadingReports!;
    }
    _loadingReportsFor = uid;
    final loading = _loadReports(online, uid);
    _loadingReports = loading;
    return loading.whenComplete(() {
      if (identical(_loadingReports, loading)) _loadingReports = null;
    });
  }

  Future<void> _loadReports(ReportRepository online, String? uid) async {
    reportsState.value = const ReportsLoadState(ReportsLoadStatus.loading);
    bool isCurrent() =>
        uid == AuthService.repository.uid &&
        identical(online, reportRepository);
    try {
      if (uid == null) {
        throw const ReportException('Your session has expired. Sign in again.');
      }
      final mine = await online.fetchMyReports(uid);
      // Results for an account that has since signed out or switched.
      if (!isCurrent()) return;
      _repo.disputes
        ..removeWhere((item) => !_isDeviceCase(item))
        ..addAll(mine);
      _repo.emitChange();
      _reportsLoadedFor = uid;
      reportsState.value = const ReportsLoadState(ReportsLoadStatus.loaded);
    } on ReportException catch (error) {
      if (!isCurrent()) return;
      reportsState.value = ReportsLoadState(
        ReportsLoadStatus.failed,
        error.message,
      );
    }
  }

  /// Cases made on this device have local ids (`c-…`). Reports sent online
  /// have their Firestore id, which never starts with `c-`: generated ids
  /// have no hyphen, and fixed ids start with the reporter's uid.
  static bool _isDeviceCase(DisputeCase item) => item.id.startsWith('c-');

  Future<DisputeCase> _report(
    ReportDraft draft, {
    bool localOnly = false,
    void Function()? afterSaved,
  }) {
    final uid = AuthService.repository.uid;
    final memberId = draft.memberId;
    if (draft.kind == CaseKind.memberReport &&
        memberId != null &&
        (memberId == User.currentUserId || memberId == uid)) {
      return Future.error(ReportException.cannotReportYourself);
    }
    final online = reportRepository;
    if (online == null || localOnly) {
      return Future.sync(() => _reportOnDevice(draft, afterSaved));
    }
    if (uid == null) {
      return Future.error(
        const ReportException('Your session has expired. Sign in again.'),
      );
    }
    // The same report already on its way: it is sent once.
    final key = '$uid ${draft.kind.name} ${draft.targetId ?? draft.reason}';
    return _sending[key] ??= _sendOnline(online, uid, draft, afterSaved)
        // A block body: returning the removed future would make this one
        // wait for itself.
        .whenComplete(() {
          _sending.remove(key);
        });
  }

  Future<DisputeCase> _sendOnline(
    ReportRepository online,
    String uid,
    ReportDraft draft,
    void Function()? afterSaved,
  ) async {
    final saved = await online.createReport(uid, draft);
    // Sent for an account that has since signed out or switched: it stays
    // that account's, and nothing changes here.
    if (uid != AuthService.repository.uid) return saved;
    afterSaved?.call();
    _repo.insert(_repo.disputes, saved);
    return saved;
  }

  /// Demo and offline reports, with the same one-report-per-target rule.
  DisputeCase _reportOnDevice(ReportDraft draft, void Function()? afterSaved) {
    ReportDocument.validate(AuthService.repository.uid ?? 'device', draft);
    final target = draft.targetId;
    if (target != null &&
        _repo.disputes.any(
          (item) =>
              item.kind == draft.kind &&
              (item.memberId == target || item.tradeId == target),
        )) {
      throw ReportException.duplicate(draft.kind);
    }
    afterSaved?.call();
    return _file(
      draft.kind,
      draft.reason.trim(),
      tradeId: draft.tradeId,
      memberId: draft.memberId,
      details: draft.details.trim(),
    );
  }

  DisputeCase _file(
    CaseKind kind,
    String reason, {
    String? tradeId,
    String? memberId,
    String details = '',
  }) {
    final report = DisputeCase(
      id: _repo.nextId('c'),
      caseNumber: 'SQ-${1000 + _repo.disputes.length}',
      kind: kind,
      reason: reason,
      tradeId: tradeId,
      memberId: memberId,
      details: details,
      createdAt: DateTime.now(),
    );
    _repo.insert(_repo.disputes, report);
    return report;
  }
}

enum ReportsLoadStatus { notLoaded, loading, loaded, failed }

/// How far loading the signed-in account's reports has got.
class ReportsLoadState {
  const ReportsLoadState(this.status, [this.error]);

  final ReportsLoadStatus status;
  final String? error;

  bool get isFailed => status == ReportsLoadStatus.failed;
}
