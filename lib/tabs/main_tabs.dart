import 'package:flutter/material.dart';
import '../screens/home/home_page.dart';

class MainTabs extends StatelessWidget {
  const MainTabs({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly load Home (No bottom tabs)
    return const HomePage();
  }
}