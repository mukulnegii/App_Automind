import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agent_response.dart';

class AgentService {

  static const String base =
      "https://mukkullnegiiii-automind-chatbot.hf.space";

  // ================= SEND AUDIO =================
  static Future<void> sendAudio(String path) async {

    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$base/send_audio"),
    );

    request.files.add(await http.MultipartFile.fromPath('file', path));

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Audio upload failed");
    }
  }

  // ================= GET FINAL RESULT =================
  static Future<AgentResponse> getResult() async {

    final res = await http.get(Uri.parse("$base/get_result"));

    if (res.statusCode != 200) {
      throw Exception("Agent response not ready");
    }

    final data = jsonDecode(res.body);
    return AgentResponse.fromJson(data);
  }

  // ================= AUDIO URL =================
  static String buildAudioUrl(String path) {
    return "$base$path";
  }
}
