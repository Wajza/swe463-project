import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:souq_skills/models/dispute_case.dart';

/// A report problem explained in words the member can act on.
class ReportException implements Exception {
  const ReportException(this.message);

  final String message;

  static const cannotReportYourself = ReportException(
    'You cannot report yourself.',
  );
  static const detailsTooLong = ReportException(
    'Keep the details to ${ReportDocument.maxDetailsLength} characters or '
    'fewer.',
  );
  static const reasonMissing = ReportException('Choose a reason');

  /// Already reported: one report per reporter, kind and target, forever.
  static ReportException duplicate(CaseKind kind) =>
      ReportException(switch (kind) {
        CaseKind.memberReport => 'You already reported this member.',
        CaseKind.tradeReport => 'You already reported this trade.',
        CaseKind.tradeDispute => 'You already opened a dispute for this trade.',
        CaseKind.complaint => 'You already sent this complaint.',
      });

  @override
  String toString() => message;
}

/// What a member is reporting, before it is sent.
class ReportDraft {
  const ReportDraft({
    required this.kind,
    required this.reason,
    this.details = '',
    this.memberId,
    this.tradeId,
    this.listingId,
  });

  final CaseKind kind;
  final String reason;
  final String details;

  /// The reported member's Firebase uid, for member reports.
  final String? memberId;

  /// For trade reports and disputes: the trade's id on the reporter's
  /// device. Trades are not shared online yet, so this id is only a pointer
  /// and proves nothing about the trade or who took part in it.
  final String? tradeId;

  final String? listingId;

  /// What a report of this kind is about, or null for a complaint.
  String? get targetId => switch (kind) {
    CaseKind.memberReport => memberId,
    CaseKind.tradeReport || CaseKind.tradeDispute => tradeId,
    CaseKind.complaint => null,
  };
}

/// Each member's reports, kept at the top-level `reports/{reportId}` so
/// moderators can review them with trusted server-side tools. Members can
/// only create their own and read their own; nobody can change or delete
/// them from the app, so they are kept after the reporter's account is
/// deleted.
abstract class ReportRepository {
  /// Sends [draft] as a report by [uid] and returns it. Throws a
  /// [ReportException], including [ReportException.duplicate] if [uid]
  /// already reported the same target the same way.
  Future<DisputeCase> createReport(String uid, ReportDraft draft);

  /// The reports [uid] sent, newest first. Throws a [ReportException].
  Future<List<DisputeCase>> fetchMyReports(String uid);
}

/// Converts between reports and the data stored in `reports/{reportId}`.
abstract final class ReportDocument {
  static const maxDetailsLength = 500;
  static const maxReasonLength = 60;

  /// Ids used in document paths: letters, digits, `_` and `-` only.
  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static bool isSafeId(String id) => _safeId.hasMatch(id);

  /// The fixed id of [uid]'s report of this kind about this target, so a
  /// second one is refused; null for complaints, which get a new id each.
  static String? reportIdFor(String uid, ReportDraft draft) {
    final target = draft.targetId;
    if (target == null) return null;
    if (!isSafeId(uid) || !isSafeId(target)) {
      throw const ReportException('This cannot be reported.');
    }
    return '${uid}_${draft.kind.name}_$target';
  }

  /// Checks [draft] before anything is sent.
  static void validate(String uid, ReportDraft draft) {
    final reason = draft.reason.trim();
    if (reason.isEmpty) throw ReportException.reasonMissing;
    if (reason.length > maxReasonLength) {
      throw const ReportException('Choose one of the reasons offered.');
    }
    if (draft.details.trim().length > maxDetailsLength) {
      throw ReportException.detailsTooLong;
    }
    if (draft.kind == CaseKind.memberReport) {
      final member = draft.memberId;
      if (member == null || member.isEmpty) {
        throw const ReportException('Choose a member to report.');
      }
      if (member == uid) throw ReportException.cannotReportYourself;
    }
    if ((draft.kind == CaseKind.tradeReport ||
            draft.kind == CaseKind.tradeDispute) &&
        (draft.tradeId ?? '').isEmpty) {
      throw const ReportException('Choose a trade to report.');
    }
    reportIdFor(uid, draft);
  }

  /// The fields stored for [draft] by [uid]: only those that apply, and no
  /// empty optional fields. `createdAt` is added by the server.
  static Map<String, dynamic> toData(String uid, ReportDraft draft) {
    final details = draft.details.trim();
    return {
      'reporterId': uid,
      'kind': draft.kind.name,
      'reason': draft.reason.trim(),
      if (details.isNotEmpty) 'details': details,
      if (draft.kind == CaseKind.memberReport) 'memberId': draft.memberId,
      if (draft.kind == CaseKind.tradeReport ||
          draft.kind == CaseKind.tradeDispute)
        'tradeId': draft.tradeId,
      'listingId': ?draft.listingId,
      'status': DisputeStatus.submitted.name,
    };
  }

  /// Reads a stored report, tolerating unknown or missing values.
  static DisputeCase fromData(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return DisputeCase(
      id: id,
      caseNumber: caseNumberFor(id),
      kind: _byName(CaseKind.values, data['kind'], CaseKind.complaint),
      reason: data['reason'] is String ? data['reason'] as String : '',
      details: data['details'] is String ? data['details'] as String : '',
      memberId: data['memberId'] is String ? data['memberId'] as String : null,
      tradeId: data['tradeId'] is String ? data['tradeId'] as String : null,
      status: _byName(
        DisputeStatus.values,
        data['status'],
        DisputeStatus.submitted,
      ),
      createdAt: switch (created) {
        Timestamp() => created.toDate(),
        DateTime() => created,
        // Not yet confirmed by the server.
        _ => DateTime.now(),
      },
    );
  }

  /// A short, stable case number for report [id], e.g. `SQ-4F2K9A`.
  static String caseNumberFor(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    final code = hash.toRadixString(36).toUpperCase().padLeft(7, '0');
    return 'SQ-${code.substring(code.length - 6)}';
  }

  static T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

/// Reports in Cloud Firestore.
class FirebaseReportRepository implements ReportRepository {
  FirebaseReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// The most reports of one member fetched at once.
  static const fetchLimit = 200;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  /// Only the member's own reports: every query is filtered by reporter,
  /// which the rules require.
  Query<Map<String, dynamic>> _mine(String uid) =>
      _reports.where('reporterId', isEqualTo: uid);

  @override
  Future<DisputeCase> createReport(String uid, ReportDraft draft) async {
    ReportDocument.validate(uid, draft);
    final id = ReportDocument.reportIdFor(uid, draft);
    final data = ReportDocument.toData(uid, draft);
    return _guard(() async {
      final DocumentReference<Map<String, dynamic>> ref;
      if (id == null) {
        ref = _reports.doc();
      } else {
        // Looked up among the member's own reports, so nobody can find out
        // whether someone else reported a member; by its fields rather than
        // its id, as a lookup by id reads the document itself, which the
        // rules only allow once it exists. The rules also refuse a second
        // report with the same id.
        final existing = await _mine(uid)
            .where('kind', isEqualTo: draft.kind.name)
            .where(
              draft.kind == CaseKind.memberReport ? 'memberId' : 'tradeId',
              isEqualTo: draft.targetId,
            )
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          throw ReportException.duplicate(draft.kind);
        }
        ref = _reports.doc(id);
      }
      await ref.set({...data, 'createdAt': FieldValue.serverTimestamp()});
      return ReportDocument.fromData(ref.id, {
        ...data,
        'createdAt': DateTime.now(),
      });
    });
  }

  @override
  Future<List<DisputeCase>> fetchMyReports(String uid) => _guard(() async {
    final snapshot = await _mine(uid).limit(fetchLimit).get();
    // Sorted here: ordering by date in the query would need an index.
    return [
      for (final doc in snapshot.docs)
        ReportDocument.fromData(doc.id, doc.data()),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  /// Runs [action], turning Firestore errors into [ReportException]s.
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ReportException {
      rethrow;
    } on FirebaseException catch (error) {
      throw ReportException(switch (error.code) {
        'unavailable' => 'Check your internet connection.',
        'permission-denied' => 'Your report could not be sent.',
        _ => 'We could not reach your reports. Try again.',
      });
    } catch (_) {
      throw const ReportException(
        'We could not reach your reports. Try again.',
      );
    }
  }
}

/// Keeps each member's reports in memory, with the same rules as Firestore.
/// Used when Firebase has not been set up, such as in tests.
class DemoReportRepository implements ReportRepository {
  // Stored as data by reporter, then report id, like Firestore holds it.
  final Map<String, Map<String, Map<String, dynamic>>> _reports = {};
  int _nextId = 0;
  DateTime _lastCreated = DateTime(2000);

  /// A copy of what is stored for report [id] by [uid], or null.
  Map<String, dynamic>? storedData(String uid, String id) {
    final data = _reports[uid]?[id];
    return data == null ? null : {...data};
  }

  @override
  Future<DisputeCase> createReport(String uid, ReportDraft draft) async {
    ReportDocument.validate(uid, draft);
    final mine = _reports[uid] ??= {};
    final id = ReportDocument.reportIdFor(uid, draft) ?? 'report-${++_nextId}';
    if (mine.containsKey(id)) throw ReportException.duplicate(draft.kind);
    // Always later than the previous report, so newest-first is exact.
    final now = DateTime.now();
    _lastCreated = now.isAfter(_lastCreated)
        ? now
        : _lastCreated.add(const Duration(milliseconds: 1));
    mine[id] = {
      ...ReportDocument.toData(uid, draft),
      'createdAt': _lastCreated,
    };
    return ReportDocument.fromData(id, mine[id]!);
  }

  @override
  Future<List<DisputeCase>> fetchMyReports(String uid) async => [
    for (final MapEntry(:key, :value) in (_reports[uid] ?? {}).entries)
      ReportDocument.fromData(key, value),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
