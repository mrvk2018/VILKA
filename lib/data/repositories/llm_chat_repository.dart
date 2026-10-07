import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../domain/llm/llm_chat_message.dart';

sealed class LlmChatResult {
  const LlmChatResult();
}

class LlmChatSuccess extends LlmChatResult {
  const LlmChatSuccess({
    required this.assistantMessage,
    this.model,
  });

  final String assistantMessage;
  final String? model;
}

class LlmChatFailure extends LlmChatResult {
  const LlmChatFailure(this.message);

  final String message;
}

abstract class LlmChatRepository {
  Future<LlmChatResult> sendUserMessage({
    required String userMessage,
    required String systemPrompt,
    required List<LlmChatMessage> history,
  });
}

/// Stateless OpenRouter `chat/completions` client.
/// Callers own conversation history and pass the last window in.
class OpenRouterLlmChatRepository implements LlmChatRepository {
  OpenRouterLlmChatRepository({
    http.Client? httpClient,
    String? apiKey,
    String? model,
  })  : _httpClient = httpClient ?? http.Client(),
        apiKey = apiKey ?? AppConfig.openRouterApiKey,
        model = model ?? AppConfig.openRouterModel;

  static const historyWindowSize = 6;
  static const _requestTimeout = Duration(seconds: 130);

  final http.Client _httpClient;
  final String apiKey;
  final String model;

  @override
  Future<LlmChatResult> sendUserMessage({
    required String userMessage,
    required String systemPrompt,
    required List<LlmChatMessage> history,
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      return const LlmChatFailure('empty_message');
    }
    if (apiKey.isEmpty) {
      return const LlmChatFailure(
        'OPENROUTER_API_KEY is empty. Pass --dart-define=OPENROUTER_API_KEY=...',
      );
    }

    final window = history.length <= historyWindowSize
        ? history
        : history.sublist(history.length - historyWindowSize);
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      for (final item in window) _toOpenRouterMessage(item),
      {'role': 'user', 'content': trimmed},
    ];

    try {
      final response = await _httpClient
          .post(
            Uri.parse(AppConfig.chatCompletionsUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://localhost',
              'X-Title': 'Vilka',
            },
            body: jsonEncode({
              'model': model,
              'messages': messages,
            }),
          )
          .timeout(_requestTimeout);

      if (AppConfig.debugLlmLogging) {
        developer.log(
          'POST ${AppConfig.chatCompletionsUrl} status=${response.statusCode} '
          'rawLen=${response.body.length}',
          name: 'OpenRouterLlmChat',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return LlmChatFailure(
          'OpenRouter HTTP ${response.statusCode}: ${_clip(response.body)}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List<dynamic>? ?? const [];
      final first =
          choices.isEmpty ? null : choices.first as Map<String, dynamic>;
      final message = first?['message'] as Map<String, dynamic>?;
      final content = (message?['content'] as String?)?.trim() ?? '';
      if (content.isEmpty) {
        return const LlmChatFailure('OpenRouter returned empty response');
      }

      return LlmChatSuccess(
        assistantMessage: content,
        model: decoded['model'] as String? ?? model,
      );
    } on TimeoutException {
      return const LlmChatFailure('OpenRouter timed out');
    } on FormatException catch (error) {
      return LlmChatFailure('invalid_json: ${error.message}');
    } catch (error) {
      return LlmChatFailure(error.toString());
    }
  }

  Map<String, String> _toOpenRouterMessage(LlmChatMessage message) {
    return switch (message) {
      LlmUserMessage(:final text) => {'role': 'user', 'content': text},
      LlmTeacherMessage(:final text) => {'role': 'assistant', 'content': text},
    };
  }

  static String _clip(String value) {
    if (value.length <= 400) {
      return value;
    }
    return value.substring(0, 400);
  }
}
