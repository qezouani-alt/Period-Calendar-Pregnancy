import 'package:flutter/foundation.dart';

import '../../../core/ai/luna_ai_error_mapper.dart';
import '../../shared/domain/health_mode_service.dart';
import '../data/luna_ai_repository.dart';
import '../domain/luna_ai_service.dart';
import '../domain/luna_message.dart';

class LunaChatController extends ChangeNotifier {
  LunaChatController({
    required ActiveHealthContext healthContext,
    LunaAiService? repository,
  }) : _repository = repository ?? LunaAiRepository(),
       _isPregnancy = healthContext.isPregnancy,
       _messages = [
         LunaMessage(text: _greeting(healthContext.isPregnancy), isUser: false),
       ];

  final LunaAiService _repository;
  final bool _isPregnancy;
  final List<LunaMessage> _messages;
  bool _isSending = false;
  bool _isDisposed = false;
  String? _lastFailedMessage;

  List<LunaMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  bool get isPregnancy => _isPregnancy;
  String? get lastFailedMessage => _lastFailedMessage;

  List<String> get starterPrompts => _isPregnancy
      ? const [
          'What is common this week?',
          'What should I ask my doctor?',
          'How should I track symptoms?',
          'What foods should I avoid?',
        ]
      : const [
          'How can I ease cramps?',
          'What can help with PMS?',
          'How does fertility tracking work?',
          'What should I track today?',
        ];

  Future<void> send(String input, {bool retry = false}) async {
    final text = input.trim();
    if (text.isEmpty || _isSending) return;

    final history = _messages
        .where((message) => !message.isError)
        .toList(growable: true);
    if (retry &&
        history.isNotEmpty &&
        history.last.isUser &&
        history.last.text == text) {
      history.removeLast();
    }

    if (retry && _messages.isNotEmpty && _messages.last.isError) {
      _messages.removeLast();
    }
    if (!retry) _messages.add(LunaMessage(text: text, isUser: true));
    _lastFailedMessage = null;
    _isSending = true;
    _notifyListeners();

    try {
      final reply = await _repository.sendMessage(
        userMessage: text,
        history: history,
      );
      _messages.add(LunaMessage(text: reply, isUser: false));
    } on LunaAiException catch (error) {
      _lastFailedMessage = text;
      _messages.add(
        LunaMessage(text: error.message, isUser: false, isError: true),
      );
    } catch (_) {
      _lastFailedMessage = text;
      _messages.add(
        const LunaMessage(
          text: 'Luna could not connect right now. Please try again shortly.',
          isUser: false,
          isError: true,
        ),
      );
    } finally {
      _isSending = false;
      _notifyListeners();
    }
  }

  void clear() {
    _messages
      ..clear()
      ..add(LunaMessage(text: _greeting(_isPregnancy), isUser: false));
    _lastFailedMessage = null;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  static String _greeting(bool isPregnancy) => isPregnancy
      ? 'Hi, I’m Luna, your supportive women’s-health companion. I’m here to listen and share general pregnancy, wellbeing, tracking, and appointment information. You only need to share what feels comfortable in this chat. I provide general education, not diagnosis, treatment, or emergency care. What would you like help with today?'
      : 'Hi, I’m Luna, your supportive women’s-health companion. I’m here to listen and share general cycle, fertility, wellbeing, tracking, and appointment information. You only need to share what feels comfortable in this chat. I provide general education, not diagnosis, treatment, or emergency care. What would you like help with today?';
}
