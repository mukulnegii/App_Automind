import 'dart:convert';
import 'package:http/http.dart' as http;

class HealthService {

  static const base =
      "https://mukkullnegiiii-automind-model.hf.space";

  static Future<Map<String, dynamic>> fetchHealth() async {

    final response = await http.get(
      Uri.parse("$base/latest-health"),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception("Failed to load vehicle health");
    }

    final data = jsonDecode(response.body);

    return {
      "health_score": (data["health_score"] ?? 0).toDouble(),
      "risk": data["risk"] ?? "UNKNOWN",
      "rul_days": (data["rul_days"] ?? 0).toDouble(),

      "engine": (data["failure_probabilities"]?["engine"] ?? 0).toDouble(),
      "brake": (data["failure_probabilities"]?["brake"] ?? 0).toDouble(),
      "battery": (data["failure_probabilities"]?["battery"] ?? 0).toDouble(),
      "gear": (data["failure_probabilities"]?["gear"] ?? 0).toDouble(),
    };
  }
}
