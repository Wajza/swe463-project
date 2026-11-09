import '../models/message.dart';
import 'repository.dart';

class SupportService {
  SupportService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<void> contactSupport({required String subject, required String message}) async {
    _repository.messages.add(Message(text: '$subject: $message', isFromCurrentUser: true));
    _repository.emitChange();
  }
  Future<void> sendMessage(String caseId, String message) async {
    _repository.messages.add(Message(id: caseId, text: message, isFromCurrentUser: true));
    _repository.emitChange();
  }
}
