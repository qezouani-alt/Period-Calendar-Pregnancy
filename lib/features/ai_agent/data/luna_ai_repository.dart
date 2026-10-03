import '../../../core/ai/luna_ai_error_mapper.dart';
import '../domain/luna_ai_service.dart';
import '../domain/luna_message.dart';
import 'gemini_ai_data_source.dart';

class LunaAiRepository implements LunaAiService {
  LunaAiRepository({LunaAiDataSource? dataSource})
    : _dataSource = dataSource ?? const SecureAiDataSource();

  final LunaAiDataSource _dataSource;

  @override
  Future<String> sendMessage({
    required String userMessage,
    required List<LunaMessage> history,
  }) async {
    final text = userMessage.trim();
    if (text.isEmpty) throw const LunaAiException.emptyMessage();

    try {
      final reply = await _dataSource.generateReply(
        userMessage: text,
        history: history,
      );
      if (reply.isEmpty) throw const LunaAiException.emptyResponse();
      return reply;
    } catch (error) {
      throw LunaAiErrorMapper.map(error);
    }
  }
}
