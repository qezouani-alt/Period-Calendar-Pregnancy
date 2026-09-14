import 'dart:async';

import '../../features/ai_agent/data/gemini_ai_data_source.dart';

class LunaAiException implements Exception {
  const LunaAiException._(this.message);

  const LunaAiException.configuration()
    : this._('AI service is not configured. Please contact support.');
  const LunaAiException.emptyMessage()
    : this._('Write a message for Luna before sending.');
  const LunaAiException.emptyResponse()
    : this._('Luna did not return a response. Please try again.');
  const LunaAiException.connection()
    : this._('Connection issue. Please try again.');
  const LunaAiException.unavailable()
    : this._('Luna could not connect right now. Please try again shortly.');
  const LunaAiException.quota()
    : this._('AI limit reached for now. Please try later.');
  const LunaAiException.safety()
    : this._(
        'I can’t help with that request, but I can share general health information or help you prepare questions for a healthcare professional.',
      );

  final String message;
}

abstract final class LunaAiErrorMapper {
  static LunaAiException map(Object error) {
    if (error is LunaAiException) return error;
    if (error is TimeoutException) return const LunaAiException.connection();
    if (error is AiBackendException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const LunaAiException.configuration();
      }
      if (error.statusCode == 429) {
        return const LunaAiException.quota();
      }
      if (error.statusCode == 408) {
        return const LunaAiException.connection();
      }
      if ((error.statusCode ?? 0) >= 500) {
        return const LunaAiException.unavailable();
      }
    }

    final normalized = error.toString().toLowerCase();

    if (_containsAny(normalized, const [
      'api key',
      'api_key',
      'ai_backend_url',
      'permission_denied',
      'permission denied',
      'not configured',
      'no-app',
      'model not found',
      'not_found',
      'service api not enabled',
    ])) {
      return const LunaAiException.configuration();
    }
    if (_containsAny(normalized, const [
      'quota',
      'resource_exhausted',
      'too many requests',
      '429',
    ])) {
      return const LunaAiException.quota();
    }
    if (_containsAny(normalized, const [
      'blocked',
      'safety',
      'prohibited_content',
      'blocklist',
      'spii',
    ])) {
      return const LunaAiException.safety();
    }
    if (_containsAny(normalized, const [
      'network',
      'socket',
      'timed out',
      'timeout',
      'unavailable',
      'connection',
    ])) {
      return const LunaAiException.connection();
    }
    return const LunaAiException.unavailable();
  }

  static bool _containsAny(String value, List<String> terms) =>
      terms.any(value.contains);
}
