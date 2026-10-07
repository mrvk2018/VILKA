/// Compile-time / env config. Never hardcode secrets.
class AppConfig {
  static const openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  static const openRouterModel = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'openrouter/free',
  );

  static const openRouterBaseUrl = 'https://openrouter.ai';

  static const debugLlmLogging = bool.fromEnvironment(
    'DEBUG_LLM_LOGGING',
    defaultValue: false,
  );

  static String get chatCompletionsUrl =>
      '$openRouterBaseUrl/api/v1/chat/completions';
}
