import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';

import 'notification_service.dart';
import 'repository.dart';

class SafetyService {
  static const complaintReceivedMessage =
      'We received your complaint. You will get feedback from us soon.';

  final Repository _repo = Repository.instance;

  List<DisputeCase> cases() => _repo.disputes.reversed.toList();

  DisputeCase? caseById(String id) => _repo.find(_repo.disputes, id);

  DisputeCase? caseForTrade(String tradeId) {
    for (final item in cases()) {
      if (item.tradeId == tradeId) return item;
    }
    return null;
  }

  List<User> blockedMembers() => _repo.members
      .where((member) => _repo.blockedMemberIds.contains(member.id))
      .toList();

  DisputeCase reportMember({
    required String memberId,
    required String reason,
  }) => _file(CaseKind.memberReport, reason, memberId: memberId);

  DisputeCase reportTrade({required String tradeId, required String reason}) =>
      _file(CaseKind.tradeReport, reason, tradeId: tradeId);

  DisputeCase disputeTrade({required String tradeId, required String reason}) {
    _repo.update(
      _repo.trades,
      tradeId,
      (trade) => trade.copyWith(status: TradeStatus.disputed),
    );
    return _file(CaseKind.tradeDispute, reason, tradeId: tradeId);
  }

  DisputeCase fileComplaint(String topic) {
    final complaint = _file(CaseKind.complaint, topic);
    NotificationService().push(
      title: 'Complaint received',
      message: complaintReceivedMessage,
      type: NotificationType.system,
      route: AppRoutes.disputeCaseDetails,
      routeArgument: complaint.id,
    );
    return complaint;
  }

  void blockMember(String memberId) {
    _repo.blockedMemberIds.add(memberId);
    _repo.emitChange();
  }

  void unblockMember(String memberId) {
    _repo.blockedMemberIds.remove(memberId);
    _repo.emitChange();
  }

  DisputeCase _file(
    CaseKind kind,
    String reason, {
    String? tradeId,
    String? memberId,
  }) {
    final report = DisputeCase(
      id: _repo.nextId('c'),
      caseNumber: 'SQ-${1000 + _repo.disputes.length}',
      kind: kind,
      reason: reason,
      tradeId: tradeId,
      memberId: memberId,
      createdAt: DateTime.now(),
    );
    _repo.insert(_repo.disputes, report);
    return report;
  }
}
