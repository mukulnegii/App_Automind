class ChatMessage {
  final String role; // user / ai / status
  final String type; // text / audio
  final String? text;
  final String? audio;

  ChatMessage({
    required this.role,
    required this.type,
    this.text,
    this.audio,
  });
}
