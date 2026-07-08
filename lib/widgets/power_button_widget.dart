import 'package:flutter/material.dart';
import '../services/theft_power_controller.dart';

class PowerButtonWidget extends StatefulWidget {
  const PowerButtonWidget({super.key});

  @override
  State<PowerButtonWidget> createState() =>
      _PowerButtonWidgetState();
}

class _PowerButtonWidgetState
    extends State<PowerButtonWidget> {

  bool isOn = false;

  final controller = TheftPowerController();

  void toggle() {
    setState(() {
      isOn = !isOn;

      if (isOn) {
        controller.turnOn();
      } else {
        controller.turnOff();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggle,
      child: Icon(
        Icons.power_settings_new,
        size: 28,
        color: isOn ? Colors.red : Colors.grey,
      ),
    );
  }
}