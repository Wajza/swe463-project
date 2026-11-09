import 'chat_service.dart';
import 'member_simulator.dart';

class SupportService {
  void contact({required String subject, required String message}) =>
      send('$subject: ${message.trim()}');

  void send(String message) {
    ChatService().post(ChatService.supportConversationId, message);
    MemberSimulator().replyFromSupport();
  }
}
