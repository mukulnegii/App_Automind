import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VehicleBehaviourPage extends StatefulWidget {
  const VehicleBehaviourPage({super.key});

  @override
  State<VehicleBehaviourPage> createState() =>
      _VehicleBehaviourPageState();
}

class _VehicleBehaviourPageState
    extends State<VehicleBehaviourPage> {

  int driverScore = 0;
  String behaviour = "Loading...";
  String tip = "";
  bool loading = false;

  final String apiUrl =
      "https://mukkullnegiiii-automind-behaviour.hf.space/predict-driver";

  Future<void> fetchDriverData() async {
    setState(() {
      loading = true;
      behaviour = "Loading...";
    });

    try {
      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "speed": 70,
          "accel": 2.5,
          "brake_count": 2,
          "rpm": 2800,
          "throttle": 45,
          "steering": 6,
          "road_type": 1,
          "rain": 0,
          "night": 0,
          "engine_temp": 90,
          "battery": 12.4
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          driverScore = data["driver_score"];
          behaviour = data["behaviour"];
          tip = data["tip"];
          loading = false;
        });
      } else {
        setState(() {
          behaviour = "Server Error";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        behaviour = "Connection Failed";
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDriverData();
  }

  Color getScoreColor() {
    if (driverScore > 80) return const Color(0xFF2E7D32); // deep green
    if (driverScore > 50) return const Color(0xFFED6C02); // muted orange
    return const Color(0xFFC62828); // deep red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Driving Behaviour",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Driver Score",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getScoreColor().withOpacity(0.1),
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: getScoreColor(),
                      ),
                      child: Center(
                        child: Text(
                          "$driverScore",
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Text(
                  behaviour,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                if (tip.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      tip,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF1F2937), // stable dark
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: fetchDriverData,
                    child: const Text(
                      "Refresh Score",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}