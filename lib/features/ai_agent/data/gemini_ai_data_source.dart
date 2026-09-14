import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/ai/ai_safety_prompt.dart';
import '../domain/luna_message.dart';

abstract interface class LunaAiDataSource {
  Future<String> generateReply({
    required String userMessage,
    required List<LunaMessage> history,
  });
}

/// Calls the app's server-side AI proxy.
///
/// The proxy owns the provider API key. Never send a Gemini or Google API key
/// to a Flutter client or add one to the app assets.
class SecureAiDataSource implements LunaAiDataSource {
  const SecureAiDataSource({
    this.systemInstruction = lunaSafetyPrompt,
    this.endpoint = const String.fromEnvironment('AI_BACKEND_URL'),
  });

  final String systemInstruction;
  final String endpoint;

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<LunaMessage> history,
  }) async {
    if (endpoint.trim().isEmpty) {
      throw const AiBackendException('AI_BACKEND_URL is not configured.');
    }
    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        ..._contents(history),
        {
          'role': 'user',
          'parts': [
            {'text': userMessage},
          ],
        },
      ],
      'generationConfig': {'temperature': .45, 'maxOutputTokens': 1000},
    };
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await _post(body);
      } catch (error) {
        lastError = error;
        if (attempt == 2 || !_isTransient(error)) rethrow;
        await Future<void>.delayed(_retryDelay(error, attempt));
      }
    }
    throw lastError!;
  }

  Future<String> _post(Map<String, Object> body) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12);
    try {
      final uri = Uri.tryParse(endpoint.trim());
      if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
        throw const AiBackendException(
          'AI_BACKEND_URL must be a valid HTTPS URL.',
        );
      }
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final text = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiBackendException(
          _errorMessage(text),
          statusCode: response.statusCode,
          retryAfter: _retryAfter(
            response.headers.value(HttpHeaders.retryAfterHeader),
            text,
          ),
        );
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const AiBackendException(
          'AI service returned an invalid response.',
        );
      }
      final answer = _answer(decoded);
      if (answer.isEmpty) {
        throw const AiBackendException(
          'AI service returned an empty response.',
        );
      }
      return answer;
    } finally {
      client.close(force: true);
    }
  }

  static List<Map<String, Object>> _contents(List<LunaMessage> history) {
    final messages = history
        .where((item) => !item.isError && item.text.trim().isNotEmpty)
        .toList();
    while (messages.isNotEmpty && !messages.first.isUser) {
      messages.removeAt(0);
    }
    final recent = messages.length > 12
        ? messages.sublist(messages.length - 12)
        : messages;
    while (recent.isNotEmpty && !recent.first.isUser) {
      recent.removeAt(0);
    }
    return recent
        .map(
          (item) => {
            'role': item.isUser ? 'user' : 'model',
            'parts': [
              {'text': item.text},
            ],
          },
        )
        .toList();
  }

  static String _answer(Map<String, dynamic> json) {
    final directText = json['text'];
    if (directText is String && directText.trim().isNotEmpty) {
      return directText.trim();
    }
    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty || candidates.first is! Map) {
      return '';
    }
    final content = (candidates.first as Map)['content'];
    if (content is! Map || content['parts'] is! List) return '';
    return (content['parts'] as List)
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .join()
        .trim();
  }

  static String _errorMessage(String response) {
    try {
      final decoded = jsonDecode(response);
      final message = decoded is Map && decoded['error'] is Map
          ? (decoded['error'] as Map)['message']
          : null;
      if (message is String) return message;
    } on FormatException {
      // Fall back to a safe generic message for non-JSON responses.
    }
    return 'AI service request failed.';
  }

  static bool _isTransient(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is HttpException ||
      error is AiBackendException &&
          (error.statusCode == 408 || (error.statusCode ?? 0) >= 500);

  static Duration _retryDelay(Object error, int attempt) {
    if (error is AiBackendException) {
      final delay = error.retryAfter;
      if (delay != null) {
        const maximum = Duration(seconds: 30);
        return delay > maximum ? maximum : delay;
      }
    }
    return Duration(milliseconds: 500 * (attempt + 1));
  }

  static Duration? _retryAfter(String? header, String response) {
    final headerSeconds = int.tryParse(header ?? '');
    if (headerSeconds != null && headerSeconds > 0) {
      return Duration(seconds: headerSeconds);
    }

    final structured = RegExp(
      r'"retryDelay"\s*:\s*"([0-9]+(?:\.[0-9]+)?)s"',
      caseSensitive: false,
    ).firstMatch(response);
    final message = RegExp(
      r'retry in\s+([0-9]+(?:\.[0-9]+)?)s',
      caseSensitive: false,
    ).firstMatch(response);
    final seconds = double.tryParse((structured ?? message)?.group(1) ?? '');
    if (seconds == null || seconds <= 0) return null;
    return Duration(milliseconds: (seconds * 1000).ceil());
  }
}

class AiBackendException implements Exception {
  const AiBackendException(this.message, {this.statusCode, this.retryAfter});
  final String message;
  final int? statusCode;
  final Duration? retryAfter;
  @override
  String toString() => message;
}
