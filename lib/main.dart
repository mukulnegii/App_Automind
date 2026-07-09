import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_service.dart';

import 'firebase_options.dart';
import 'core/vehicle_health_controller.dart';
// Auth
import 'auth/login_page.dart';
import 'splash/auth_gate.dart';

// Main Screens (for future routing)
import 'tabs/main_tabs.dart';
import 'tabs/home/add_vehicle_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();  // 👈 ADD THIS LINE HERE
  VehicleHealthController().start();

  runApp(const MyApp());
  _handleColdStartNotification();   // 👈 ADD THIS LINE
}

Future<void> _handleColdStartNotification() async {
  final prefs = await SharedPreferences.getInstance();

  bool alreadyScheduled =
      prefs.getBool('startup_notification_scheduled') ?? false;

  if (!alreadyScheduled) {
    await prefs.setBool('startup_notification_scheduled', true);

    Future.delayed(const Duration(seconds: 30), () async {
      await NotificationService.showStartupFunNotification();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "AutoMind",

      theme: ThemeData(
        useMaterial3: true,

        scaffoldBackgroundColor: const Color(0xFFF6F8FC),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B132B),
          brightness: Brightness.light,
        ),

        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),

      // Named Routes (Clean Navigation)
      routes: {
        '/main': (_) => const MainTabs(),
        '/add-vehicle': (_) => const AddVehiclePage(),
      },

      // Auto Login Handling
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Logged In
          if (snapshot.hasData) {
            return const AuthGate();
          }

          // Not Logged In
          return const LoginPage();
        },
      ),
    );
  }
}
