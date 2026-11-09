import '../models/dispute_case.dart';
import 'repository.dart';

class SafetyService {
  SafetyService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<DisputeCase> reportMember({required String memberId, required String reason, required String details}) async {
    final report = DisputeCase(memberId: memberId, reason: reason, details: details);
    _repository.disputes.add(report);
    _repository.emitChange();
    return report;
  }
  Future<DisputeCase> reportTrade({required String tradeId, required String reason, required String details}) async {
    final report = DisputeCase(tradeId: tradeId, reason: reason, details: details);
    _repository.disputes.add(report);
    _repository.emitChange();
    return report;
  }
  Future<void> blockMember(String memberId) async {
    _repository.blockedMemberIds.add(memberId);
    _repository.emitChange();
  }
  Future<void> unblockMember(String memberId) async {
    _repository.blockedMemberIds.remove(memberId);
    _repository.emitChange();
  }
}
