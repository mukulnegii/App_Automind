// lib/tabs/alert/power_button_widget.dart

import 'package:flutter/material.dart';
import 'alert_controller.dart';

class PowerButtonWidget extends StatelessWidget {
  const PowerButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AlertController.alertMode,
      builder: (context, value, _) {
        return InkWell(
          onTap: AlertController.toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? Colors.red.withOpacity(0.15)
                  : Colors.transparent,
            ),
            child: Icon(
              Icons.power_settings_new,
              size: 28,
              color: value ? Colors.red : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}