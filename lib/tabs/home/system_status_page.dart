import 'package:flutter/material.dart';
import '../../core/vehicle_health_controller.dart';

class SystemStatusPage extends StatelessWidget {
  const SystemStatusPage({super.key});

  // ================= COLOR LOGIC =================

  Color loadColor(int value) {
    if (value < 40) return Colors.green;
    if (value < 75) return Colors.orange;
    return Colors.red;
  }

  Color rulColor(int days) {
    if (days > 60) return Colors.green;
    if (days > 20) return Colors.orange;
    return Colors.red;
  }

  Color tempColor(int temp) {
    if (temp < 95) return Colors.green;
    if (temp < 110) return Colors.orange;
    return Colors.red;
  }

  Widget metricTile({
    required String title,
    required String value,
    required String emoji,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), // FULL CARD COLOR
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text("System Status"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: VehicleHealthController().healthData,
          builder: (context, data, _) {
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final vehicleId = data["vehicle_id"] ?? "Vehicle";

            final engineLoad = data["engine_load"];
            final brakeLoad = data["brake_load"];
            final gearStress = data["gear_stress"];
            final batteryLoad = data["battery_load"];
            final batteryHealth = data["battery_health_remaining"];
            final engineTemp = data["engine_temperature"];

            final engineRul = data["engine_rul_days"];
            final brakeRul = data["brake_rul_days"];
            final gearRul = data["gear_rul_days"];
            final batteryRul = data["battery_rul_days"];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔥 VEHICLE NAME
                  Text(
                    vehicleId,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Remaining Useful Life",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 15),

                  metricTile(
                    title: "Engine RUL",
                    value: "$engineRul days",
                    emoji: "⚙️",
                    color: rulColor(engineRul),
                  ),
                  metricTile(
                    title: "Brake RUL",
                    value: "$brakeRul days",
                    emoji: "🛑",
                    color: rulColor(brakeRul),
                  ),
                  metricTile(
                    title: "Gear RUL",
                    value: "$gearRul days",
                    emoji: "🔩",
                    color: rulColor(gearRul),
                  ),
                  metricTile(
                    title: "Battery RUL",
                    value: "$batteryRul days",
                    emoji: "🔋",
                    color: rulColor(batteryRul),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Live Metrics",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 15),

                  metricTile(
                    title: "Engine Load",
                    value: "$engineLoad %",
                    emoji: "⚙️",
                    color: loadColor(engineLoad),
                  ),
                  metricTile(
                    title: "Brake Load",
                    value: "$brakeLoad %",
                    emoji: "🛑",
                    color: loadColor(brakeLoad),
                  ),
                  metricTile(
                    title: "Gear Stress",
                    value: "$gearStress %",
                    emoji: "🔩",
                    color: loadColor(gearStress),
                  ),
                  metricTile(
                    title: "Battery Load",
                    value: "$batteryLoad %",
                    emoji: "🔋",
                    color: loadColor(batteryLoad),
                  ),
                  metricTile(
                    title: "Battery Health Remaining",
                    value: "$batteryHealth %",
                    emoji: "🔋",
                    color: loadColor(batteryHealth),
                  ),
                  metricTile(
                    title: "Engine Temperature",
                    value: "$engineTemp °C",
                    emoji: "🌡️",
                    color: tempColor(engineTemp),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}