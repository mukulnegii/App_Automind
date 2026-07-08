import 'package:flutter/material.dart';
import '../../core/vehicle_health_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeHeader extends StatelessWidget {
  final User? user;
  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome back",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.displayName ?? "User",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.3,
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 60, // slightly taller
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveAlertsSection extends StatelessWidget {
  const ActiveAlertsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: VehicleHealthController().healthData,
      builder: (context, data, _) {
        if (data == null) return const SizedBox();

        final alerts = data["alerts"] as List<dynamic>? ?? [];

        if (alerts.isEmpty) {
          return const Text(
            "No active alerts",
            style: TextStyle(color: Colors.grey),
          );
        }

        return Column(
          children: alerts.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2), // softer red
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Text(alert.toString()),
            );
          }).toList(),
        );
      },
    );
  }
}

class LiveHealthCard extends StatelessWidget {
  const LiveHealthCard({super.key});

  Color color(double healthScore) {
    if (healthScore >= 80) return Colors.green;
    if (healthScore >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: VehicleHealthController().healthData,
      builder: (context, data, _) {
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final healthScore =
        (data["vehicle_health"] ?? 0).toDouble();

        final rulDays =
        (data["remaining_life_days"] ?? 0).toInt();

        final risk = healthScore >= 80
            ? "GOOD"
            : healthScore >= 60
            ? "MEDIUM"
            : "CRITICAL";

        return Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: 28, horizontal: 20), // tightened spacing
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [

                Text(
                  data["vehicle_id"] ?? "Vehicle",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Vehicle Health Score",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 25),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 160,
                      width: 160,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: healthScore / 100,
                        ),
                        duration:
                        const Duration(milliseconds: 900),
                        builder: (context, value, _) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12, // thinner ring
                            backgroundColor:
                            const Color(0xFFF0F2F5),
                            color: color(healthScore),
                          );
                        },
                      ),
                    ),

                    Column(
                      children: [
                        Text(
                          healthScore
                              .toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          risk,
                          style: TextStyle(
                            color: color(healthScore),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                //Text(
                  //"Remaining Life: $rulDays days",
                  //style: const TextStyle(
                    //fontSize: 13,
                    //color: Colors.black54,
                  //),
                //),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AlertCard extends StatelessWidget {
  final String title;
  final String level;
  final Color levelColor;
  final String description;
  final String predicted;
  final Color backgroundColor;

  const AlertCard({
    super.key,
    required this.title,
    required this.level,
    required this.levelColor,
    required this.description,
    required this.predicted,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: levelColor.withOpacity(0.15), // softer border
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              color: levelColor,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        level,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  predicted,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}