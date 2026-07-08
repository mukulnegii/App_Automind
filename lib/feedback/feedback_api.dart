import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedbackAPI {
  static const baseUrl =
      "https://mukkullnegiiii-automind-feedback.hf.space";

  // -----------------------------
  // GET QUESTION FROM BACKEND
  // -----------------------------
  static Future<Map?> getFeedbackQuestion() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/service/feedback-request"))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Feedback request error: $e");
    }
    return null;
  }

  // -----------------------------
  // SUBMIT USER FEEDBACK
  // -----------------------------
  static Future<Map?> submitFeedback(double rating, String comment) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/service/feedback"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rating": rating,
          "comment": comment,
        }),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      print("Submit feedback error: $e");
    }
    return null;
  }

  // -----------------------------
  // VOICE FOLLOWUP MESSAGE
  // -----------------------------
  static Future<String?> followupMessage() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/service/voice-followup"))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["call_user"] == true ? data["message"] : null;
      }
    } catch (e) {
      print("Voice followup error: $e");
    }
    return null;
  }
}
