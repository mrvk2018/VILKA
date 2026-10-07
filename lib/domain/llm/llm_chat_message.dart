sealed class LlmChatMessage {
  const LlmChatMessage();
}

class LlmUserMessage extends LlmChatMessage {
  const LlmUserMessage(this.text);

  final String text;
}

class LlmTeacherMessage extends LlmChatMessage {
  const LlmTeacherMessage(this.text);

  final String text;
}
