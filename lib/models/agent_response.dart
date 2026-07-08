class AgentResponse {

  final String aiResponseText;
  final String? audioUrl;

  // Optional future fields
  final String? transcript;
  final String? emotion;
  final String? diagnosis;
  final String? bookingStatus;

  AgentResponse({
    required this.aiResponseText,
    this.audioUrl,
    this.transcript,
    this.emotion,
    this.diagnosis,
    this.bookingStatus,
  });

  factory AgentResponse.fromJson(Map<String, dynamic> json) {

    return AgentResponse(
      aiResponseText: json["ai_response_text"] ?? "No response",
      audioUrl: json["audio_url"],

      // Optional — will be null if backend doesn't send
      transcript: json["transcript"],
      emotion: json["emotion"],
      diagnosis: json["diagnosis"],
      bookingStatus: json["auto_booking"]?["status"],
    );
  }
}
