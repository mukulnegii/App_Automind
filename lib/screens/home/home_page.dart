// ================= HOME PAGE =================
// FULL MERGED VERSION
// Old Logic + New Polished UI

import 'dart:async';
import 'package:flutter/material.dart';
import '../../tabs/home/add_vehicle_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../widgets/power_button_widget.dart';
import '../../core/vehicle_health_controller.dart';
import '../../chatbot/chatbot_screen.dart';
import 'home_components.dart';
import 'vehicle_main_card.dart';
import '../../tabs/service/live_system_status_card.dart';
import '../../tabs/home/system_status_page.dart';
import 'notification_screen.dart';
import '../../tabs/settings/settings_page.dart';
import '../../tabs/service/book_service_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool hasApprovedVehicle = false;

  bool _alertPopupShown = false;
  StreamSubscription<QuerySnapshot>? _alertSubscription;

  @override
  void initState() {
    super.initState();


    Future.delayed(const Duration(seconds: 30), () {
      NotificationService.showStartupFunNotification();
    });

    _listenForAlerts();
  }

  void _listenForAlerts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _alertSubscription = FirebaseFirestore.instance
        .collection("vehicle_alerts")
        .where("userId", isEqualTo: user.uid)
        .where("isHandled", isEqualTo: false)
        .orderBy("createdAt")
        .snapshots()
        .listen((snapshot) {

      if (snapshot.docs.length < 2) return;
      if (_alertPopupShown) return;

      final secondDoc = snapshot.docs[1];
      final alertData = secondDoc.data() as Map<String, dynamic>;

      _alertPopupShown = true;

      Future.delayed(const Duration(seconds: 24), () {
        if (!mounted) return;
        _showAlertPopup(alertData, secondDoc.id);
      });
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  // Softer Alert Colors (New UI)
  Color _urgencyColor(String level) {
    switch (level.toUpperCase()) {
      case "HIGH":
        return const Color(0xFFD32F2F);
      case "MEDIUM":
        return const Color(0xFFF57C00);
      case "LOW":
        return const Color(0xFF1976D2);
      default:
        return Colors.grey;
    }
  }

  Color _urgencyBg(String level) {
    switch (level.toUpperCase()) {
      case "HIGH":
        return const Color(0xFFFFF2F2);
      case "MEDIUM":
        return const Color(0xFFFFF8E6);
      case "LOW":
        return const Color(0xFFEAF4FF);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  // ===== Alert Popup =====

  void _showAlertPopup(
      Map<String, dynamic> alertData,
      String alertDocId,
      ) {

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 🔴 Icon + Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD32F2F),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Service Alert",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 🚗 Vehicle Name
                Text(
                  alertData["vehicleName"] ?? "",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Service Recommended",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 18),

                // ⏰ Slot Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.access_time_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "10:00 AM Today",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // 🔘 Buttons
                Row(
                  children: [

                    // Later
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Later"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Edit
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookServicePage(
                                autoVehicleId: alertData["carId"],
                                autoServiceType: "Other",
                                autoIssue: alertData["shortIssue"],
                                autoFromAlert: true,
                              ),
                            ),
                          );
                        },
                        child: const Text("Edit"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Confirm
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _handleAutoBooking(alertData, alertDocId);
                        },
                        child: const Text("Confirm"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Auto Booking =====

  Future<void> _handleAutoBooking(
      Map<String, dynamic> alertData,
      String alertDocId,
      ) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String carId = alertData["carId"];
    final String vehicleName = alertData["vehicleName"];
    final String vehicleCompany = alertData["vehicleCompany"];
    final String shortIssue = alertData["shortIssue"];

    final now = DateTime.now();
    final slotDateTime = DateTime(now.year, now.month, now.day, 10);

    await FirebaseFirestore.instance
        .collection("service_booking")
        .add({

      "userId": user.uid,
      "userEmail": user.email,
      "userPhone": "0000000000",

      "vehicleId": carId,
      "vehicleName": vehicleName,
      "vehicleCompany": vehicleCompany,

      "serviceType": "Other",
      "issueDescription": shortIssue,
      "serviceCenter": "Auto Assigned Center",

      "bookingDate": Timestamp.fromDate(now),
      "slotDateTime": Timestamp.fromDate(slotDateTime),
      "slotTime": "10:00",

      "expectedCompletionTime": Timestamp.fromDate(now),

      "status": "scheduled",
      "liveStage": "waiting",
      "mlPredicted": true,
      "mlEngineVersion": "v1.0-slot-model",
      "createdAt": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection("vehicle_alerts")
        .doc(alertDocId)
        .update({"isHandled": true});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Service Automatically Booked at 10:00 AM"),
      ),
    );
  }

  // ===== No Vehicle Card (Restored) =====

  Widget _noVehicleCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_car,
              size: 45, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
            "No vehicle registered",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddVehiclePage(),
                ),
              );
            },
            child: const Text("Register Vehicle"),
          ),
        ],
      ),
    );
  }

  // ===== BUILD =====

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // HEADER
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome back",
                          style: TextStyle(color: Colors.grey)),
                      Text(
                        user?.displayName ?? "User",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const PowerButtonWidget(),
                  const SizedBox(width: 15),

                  // Notifications
                  InkWell(
                    onTap: () {
                      final notifications = [
                        {
                          "title": "Subscription Expiry Notice",
                          "message": "Your subscription will end soon."
                        },
                        {
                          "title": "Service Confirmation",
                          "message": "Your service has been confirmed."
                        },
                      ];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.notifications_active, size: 26),
                  ),

                  const SizedBox(width: 15),

                  // Settings
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsPage(),
                        ),
                      );
                    },
                    child: const Icon(Icons.menu, size: 28),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              // VEHICLE STREAM
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("vehicles")
                    .where("userId", isEqualTo: user!.uid)
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _noVehicleCard(context);
                  }

                  final docs = snapshot.data!.docs;

// check if any vehicle is approved
                  hasApprovedVehicle = docs.any((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data["status"] == "approved";
                  });

                  // CONTROL BACKEND POLLING
                  if (hasApprovedVehicle) {
                    VehicleHealthController().start();
                  } else {
                    VehicleHealthController().stop();
                  }

                  return Column(
                    children: [

                      SizedBox(
                        height: 190,
                        child: PageView.builder(
                          controller: PageController(viewportFraction: 0.98),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {

                            final data = docs[index].data() as Map<String, dynamic>;

                            return VehicleMainCard(
                              vehicleId: docs[index].id,
                              userId: user.uid,
                              company: data["company"] ?? "",
                              model: data["model"] ?? "",
                              reg: data["regNumber"] ?? "",
                              status: data["status"] ?? "pending",
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),  // 👈 ADD GAP HERE

                      if (hasApprovedVehicle) ...[
                        const SizedBox(height: 25),
                        const LiveHealthCard(),
                        const SizedBox(height: 35),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "System Status",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SystemStatusPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "View All",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const LiveSystemStatusCard(),

                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Active Alerts",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        const SizedBox(height: 18),

                        ValueListenableBuilder<Map<String, dynamic>?>(

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
                              children: alerts.map((alertText) {

                                final level =
                                alertText.toString().toLowerCase().contains("critical")
                                    ? "HIGH"
                                    : "MEDIUM";

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: AlertCard(
                                    title: "Vehicle Alert",
                                    level: level,
                                    levelColor: _urgencyColor(level),
                                    description: alertText.toString(),
                                    predicted: "Service recommended",
                                    backgroundColor: _urgencyBg(level),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 35),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              text: "Book Service",
                              color: const Color(0xFF2979FF),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookServicePage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ActionButton(
                              text: "Ask Assistant",
                              color: const Color(0xFF0B132B),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatbotScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                    ],
                  );

                },   // builder closed
              ),    // StreamBuilder closed

            ],
          ),
        ),
      ),
    );
  }

}