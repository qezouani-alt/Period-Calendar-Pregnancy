import 'luna_message.dart';

abstract interface class LunaAiService {
  Future<String> sendMessage({
    required String userMessage,
    required List<LunaMessage> history,
  });
}
