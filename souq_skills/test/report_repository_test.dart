import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/report_repository.dart';
import 'package:souq_skills/models/dispute_case.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';

ReportDraft _member(String memberId, {String details = ''}) => ReportDraft(
  kind: CaseKind.memberReport,
  reason: 'Spam or scam',
  memberId: memberId,
  details: details,
);

ReportDraft _trade(String tradeId, {CaseKind kind = CaseKind.tradeReport}) =>
    ReportDraft(kind: kind, reason: 'Member did not attend', tradeId: tradeId);

const _complaint = ReportDraft(kind: CaseKind.complaint, reason: 'A trade');

void main() {
  group('ReportDocument', () {
    test('stores only the fields that apply', () {
      expect(ReportDocument.toData(_maha, _member(_sami)), {
        'reporterId': _maha,
        'kind': 'memberReport',
        'reason': 'Spam or scam',
        'memberId': _sami,
        'status': 'submitted',
      });
      expect(ReportDocument.toData(_maha, _trade('t-sami')), {
        'reporterId': _maha,
        'kind': 'tradeReport',
        'reason': 'Member did not attend',
        'tradeId': 't-sami',
        'status': 'submitted',
      });
      expect(
        ReportDocument.toData(
          _maha,
          const ReportDraft(
            kind: CaseKind.complaint,
            reason: ' A trade ',
            details: '  Was late.  ',
            memberId: _sami,
            listingId: 'sami-1',
          ),
        ),
        {
          'reporterId': _maha,
          'kind': 'complaint',
          'reason': 'A trade',
          'details': 'Was late.',
          'listingId': 'sami-1',
          'status': 'submitted',
        },
      );
    });

    test('reads stored reports, tolerating odd values', () {
      final report = ReportDocument.fromData('abc', {
        'reporterId': _maha,
        'kind': 'memberReport',
        'reason': 'Harassment',
        'details': 'Rude messages.',
        'memberId': _sami,
        'status': 'underReview',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 1)),
      });
      expect(report.id, 'abc');
      expect(report.kind, CaseKind.memberReport);
      expect(report.details, 'Rude messages.');
      expect(report.memberId, _sami);
      expect(report.status, DisputeStatus.underReview);
      expect(report.createdAt, DateTime(2026, 11, 1));
      expect(report.caseNumber, ReportDocument.caseNumberFor('abc'));

      final odd = ReportDocument.fromData('odd', {
        'kind': 'praise',
        'status': 'archived',
        'reason': 7,
        'details': ['x'],
        'createdAt': DateTime(2026, 1, 2),
      });
      expect(odd.kind, CaseKind.complaint);
      expect(odd.status, DisputeStatus.submitted);
      expect(odd.reason, '');
      expect(odd.details, '');
      expect(odd.createdAt, DateTime(2026, 1, 2));
    });

    test('member and trade reports have fixed ids, complaints none', () {
      expect(
        ReportDocument.reportIdFor(_maha, _member(_sami)),
        'uid-maha_memberReport_uid-sami',
      );
      expect(
        ReportDocument.reportIdFor(_maha, _trade('t-sami')),
        'uid-maha_tradeReport_t-sami',
      );
      expect(
        ReportDocument.reportIdFor(
          _maha,
          _trade('t-sami', kind: CaseKind.tradeDispute),
        ),
        'uid-maha_tradeDispute_t-sami',
      );
      expect(ReportDocument.reportIdFor(_maha, _complaint), isNull);
    });

    test('unsafe or overlong ids are refused', () {
      for (final target in ['a/b', 'has space', '', 'x' * 129]) {
        expect(
          () => ReportDocument.reportIdFor(_maha, _trade(target)),
          throwsA(isA<ReportException>()),
          reason: target,
        );
      }
    });

    test('checks reports before they are sent', () {
      void expectRefused(ReportDraft draft, String message) => expect(
        () => ReportDocument.validate(_maha, draft),
        throwsA(
          isA<ReportException>().having((e) => e.message, 'message', message),
        ),
      );

      expectRefused(_member(_maha), 'You cannot report yourself.');
      expectRefused(
        _member(_sami, details: 'x' * 501),
        'Keep the details to 500 characters or fewer.',
      );
      expectRefused(
        const ReportDraft(kind: CaseKind.complaint, reason: '  '),
        'Choose a reason',
      );
      expectRefused(
        ReportDraft(kind: CaseKind.complaint, reason: 'x' * 61),
        'Choose one of the reasons offered.',
      );
      ReportDocument.validate(_maha, _member(_sami, details: 'x' * 500));
    });

    test('case numbers are short and stable', () {
      final number = ReportDocument.caseNumberFor('uid-maha_memberReport_x');
      expect(number, matches(RegExp(r'^SQ-[0-9A-Z]{6}$')));
      expect(ReportDocument.caseNumberFor('uid-maha_memberReport_x'), number);
      expect(ReportDocument.caseNumberFor('another'), isNot(number));
    });
  });

  group('DemoReportRepository', () {
    test('sends a report under its fixed id', () async {
      final reports = DemoReportRepository();

      final sent = await reports.createReport(_maha, _member(_sami));

      expect(sent.id, 'uid-maha_memberReport_uid-sami');
      expect(sent.status, DisputeStatus.submitted);
      expect(reports.storedData(_maha, sent.id)!['reporterId'], _maha);
    });

    test('a second report of the same target and kind is refused', () async {
      final reports = DemoReportRepository();
      await reports.createReport(_maha, _member(_sami));
      await reports.createReport(_maha, _trade('t-sami'));

      for (final (draft, message) in [
        (_member(_sami), 'You already reported this member.'),
        (_trade('t-sami'), 'You already reported this trade.'),
      ]) {
        await expectLater(
          reports.createReport(_maha, draft),
          throwsA(
            isA<ReportException>().having((e) => e.message, 'message', message),
          ),
        );
      }
      // Another kind about the same trade, or another reporter, is fine.
      await reports.createReport(
        _maha,
        _trade('t-sami', kind: CaseKind.tradeDispute),
      );
      await reports.createReport(_lina, _member(_sami));
    });

    test('complaints each get their own id', () async {
      final reports = DemoReportRepository();

      final first = await reports.createReport(_maha, _complaint);
      final second = await reports.createReport(_maha, _complaint);

      expect(first.id, isNot(second.id));
    });

    test('each reporter only gets their own reports, newest first', () async {
      final reports = DemoReportRepository();
      final older = await reports.createReport(_maha, _member(_sami));
      await reports.createReport(_lina, _member(_sami));
      final newer = await reports.createReport(_maha, _complaint);

      final mine = await reports.fetchMyReports(_maha);

      expect(mine.map((r) => r.id), [newer.id, older.id]);
      expect(await reports.fetchMyReports(_sami), isEmpty);
    });

    test('nothing is stored for a refused report', () async {
      final reports = DemoReportRepository();

      await expectLater(
        reports.createReport(_maha, _member(_maha)),
        throwsA(same(ReportException.cannotReportYourself)),
      );

      expect(await reports.fetchMyReports(_maha), isEmpty);
    });
  });
}
