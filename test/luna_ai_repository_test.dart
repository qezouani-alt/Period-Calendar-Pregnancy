import 'package:flutter_test/flutter_test.dart';
import 'package:period/core/ai/luna_ai_error_mapper.dart';
import 'package:period/features/ai_agent/data/gemini_ai_data_source.dart';
import 'package:period/features/ai_agent/data/luna_ai_repository.dart';
import 'package:period/features/ai_agent/domain/luna_message.dart';

void main() {
  test('returns a Gemini reply for a valid message', () async {
    final dataSource = _FakeDataSource(reply: 'Hi, how can I help?');
    final repository = LunaAiRepository(dataSource: dataSource);

    final reply = await repository.sendMessage(
      userMessage: 'Hi',
      history: const [],
    );

    expect(reply, 'Hi, how can I help?');
    expect(dataSource.lastUserMessage, 'Hi');
  });

  test('rejects an empty message before contacting Gemini', () async {
    final dataSource = _FakeDataSource(reply: 'unused');
    final repository = LunaAiRepository(dataSource: dataSource);

    expect(
      () => repository.sendMessage(userMessage: '  ', history: const []),
      throwsA(isA<LunaAiException>()),
    );
    expect(dataSource.callCount, 0);
  });

  test('maps raw configuration failures to a safe message', () async {
    final repository = LunaAiRepository(
      dataSource: _FakeDataSource(error: StateError('API key invalid: secret')),
    );

    await expectLater(
      repository.sendMessage(userMessage: 'Hi', history: const []),
      throwsA(
        isA<LunaAiException>().having(
          (error) => error.message,
          'message',
          'AI service is not configured. Please contact support.',
        ),
      ),
    );
  });

  test('maps HTTP 429 to the quota message regardless of provider text', () {
    final mapped = LunaAiErrorMapper.map(
      const AiBackendException('Request rejected.', statusCode: 429),
    );

    expect(mapped.message, 'AI limit reached for now. Please try later.');
  });

  test('forwards only explicit chat history', () async {
    final dataSource = _FakeDataSource(reply: 'General information');
    final repository = LunaAiRepository(dataSource: dataSource);
    const history = [
      LunaMessage(text: 'My explicit question', isUser: true),
      LunaMessage(text: 'An earlier answer', isUser: false),
    ];

    await repository.sendMessage(userMessage: 'Continue', history: history);

    expect(dataSource.lastHistory, same(history));
  });
}

class _FakeDataSource implements LunaAiDataSource {
  _FakeDataSource({this.reply, this.error});

  final String? reply;
  final Object? error;
  int callCount = 0;
  String? lastUserMessage;
  List<LunaMessage>? lastHistory;

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<LunaMessage> history,
  }) async {
    callCount++;
    lastUserMessage = userMessage;
    lastHistory = history;
    if (error case final error?) throw error;
    return reply ?? '';
  }
}
