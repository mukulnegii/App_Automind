import 'dart:convert';
import 'package:http/http.dart' as http;

class AlertService {

  // 🔥 your HF deployed backend
  static const String baseUrl =
      "https://mukkullnegiiii-automind-scheduling.hf.space";

  static Future<Map<String, dynamic>?> fetchAlert() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/service/suggestion"));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["ask_user"] == true) {
          return data;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
