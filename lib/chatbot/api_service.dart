import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl =
      "https://mukkullnegiiii-automind-model.hf.space";

  // ===============================
  // Get Latest Vehicle Health
  // ===============================
  static Future<Map<String, dynamic>> getLatestHealth() async {

    final response = await http.get(Uri.parse("$baseUrl/latest-health"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch health");
    }
  }

  // ===============================
  // Send Voice Audio
  // ===============================
  static Future<void> sendAudio(String path) async {

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/voice"),
    );

    request.files.add(await http.MultipartFile.fromPath('file', path));

    await request.send();
  }

  static String getAudioUrl() {
    return "$baseUrl/output/response_audio.mp3";
  }

  static String getAgentJson() {
    return "$baseUrl/output/voice_agent_output.json";
  }
}
