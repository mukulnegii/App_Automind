import 'package:flutter/material.dart';
import '../../services/theft_power_controller.dart';

class AlertController {
  static final ValueNotifier<bool> alertMode =
  ValueNotifier<bool>(false);

  static void toggle() {
    alertMode.value = !alertMode.value;

    if (alertMode.value) {
      TheftPowerController().turnOn();
    } else {
      TheftPowerController().turnOff();
    }
  }
}