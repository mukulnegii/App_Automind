import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/vehicle_health_controller.dart';

class LiveSystemStatusCard extends StatelessWidget {
  const LiveSystemStatusCard({super.key});

  int percent(num value) =>
      value.clamp(0, 100).toInt();

  Color color(int p) {
    if (p < 40) return Colors.green;
    if (p < 70) return Colors.orange;
    return Colors.red;
  }

  Widget tile(String title, IconData icon, int p) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color(p),
                  shape: BoxShape.circle,
                ),
              )
            ],
          ),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            "$p %",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<
        Map<String, dynamic>?>(
      valueListenable:
      VehicleHealthController()
          .healthData,
      builder: (context, data, _) {
        if (data == null) {
          return const Center(
              child:
              CircularProgressIndicator());
        }

        final engine =
        percent(data["engine_load"] ?? 0);
        final brake =
        percent(data["brake_load"] ?? 0);
        final battery =
        percent(data["battery_load"] ?? 0);
        final gear =
        percent(data["gear_stress"] ?? 0);

        return Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                tile("Engine",
                    Icons.settings, engine),
                tile("Brakes",
                    Icons.album, brake),
                tile("Battery",
                    Icons.battery_charging_full,
                    battery),
                tile("Gear",
                    Icons.settings_applications,
                    gear),
              ],
            ),
          ],
        );
      },
    );
  }
}