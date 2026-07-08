import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../core/vehicle_health_controller.dart';
import 'notification_service.dart';

class TheftPowerController {
  static final TheftPowerController _instance =
  TheftPowerController._internal();

  factory TheftPowerController() => _instance;

  TheftPowerController._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _monitorTimer;

  bool isOn = false;
  bool alertTriggered = false;
  double? lastHealthScore;

  void turnOn() {
    if (isOn) return;

    isOn = true;
    alertTriggered = false;

    // 🔁 Check every 2 seconds
    _monitorTimer =
        Timer.periodic(const Duration(seconds: 2), (_) {
          _checkHealth();
        });
  }

  void turnOff() async {
    isOn = false;
    alertTriggered = false;
    _monitorTimer?.cancel();

    await _audioPlayer.stop();
  }

  void _checkHealth() async {
    if (!isOn) return;

    final data = VehicleHealthController().healthData.value;
    if (data == null) return;

    final double currentHealth =
    (data["vehicle_health"] ?? 0).toDouble();

    // First time just store baseline
    if (lastHealthScore == null) {
      lastHealthScore = currentHealth;
      return;
    }

    // 🚨 If health changes
    if (currentHealth != lastHealthScore) {
      if (!alertTriggered) {
        alertTriggered = true;

        await NotificationService.showTheftNotification(
          "SAFE MODE ALERT",
          "THEFT ALERT! THEFT ALERT! THEFT ALERT!",
        );

        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(
          AssetSource('audio/siren.mp3'),
        );
      }
    }

    lastHealthScore = currentHealth;
  }
}