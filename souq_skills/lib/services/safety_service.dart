import 'package:souq_skills/models/dispute_case.dart';
import 'package:souq_skills/models/trade.dart';
import 'package:souq_skills/models/user.dart';

import 'repository.dart';

class SafetyService {
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
    required String details,
  }) => _file(CaseKind.memberReport, reason, details, memberId: memberId);

  DisputeCase reportTrade({
    required String tradeId,
    required String reason,
    required String details,
  }) => _file(CaseKind.tradeReport, reason, details, tradeId: tradeId);

  DisputeCase disputeTrade({
    required String tradeId,
    required String reason,
    required String details,
  }) {
    _repo.update(
      _repo.trades,
      tradeId,
      (trade) => trade.copyWith(status: TradeStatus.disputed),
    );
    return _file(CaseKind.tradeDispute, reason, details, tradeId: tradeId);
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
    String reason,
    String details, {
    String? tradeId,
    String? memberId,
  }) {
    final report = DisputeCase(
      id: _repo.nextId('c'),
      caseNumber: 'SQ-${1000 + _repo.disputes.length}',
      kind: kind,
      reason: reason,
      details: details.trim(),
      tradeId: tradeId,
      memberId: memberId,
      createdAt: DateTime.now(),
    );
    _repo.insert(_repo.disputes, report);
    return report;
  }
}
