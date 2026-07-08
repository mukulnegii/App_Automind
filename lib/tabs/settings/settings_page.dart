import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import Add Vehicle Page
import '../home/add_vehicle_page.dart';
import 'feedback_page.dart';
import 'vehicle_behaviour_page.dart';
import 'inventory.dart';
import 'resale.dart';
import '../home/track_service.dart';
import 'profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF4F6FA),
        foregroundColor: Colors.black,
      ),
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("vehicles")
                .where("userId", isEqualTo: user!.uid)
                .snapshots(),
            builder: (context, snapshot) {

              bool hasApprovedVehicle = false;

              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;

                hasApprovedVehicle = docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data["status"] == "approved";
                });
              }

              return SingleChildScrollView(

        child: Column(
          children: [

            const SizedBox(height: 15),

            // ================= PROFILE CARD =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [

                      // Avatar with Gradient Ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(
                            (user?.displayName != null &&
                                user!.displayName!.isNotEmpty)
                                ? user.displayName![0].toUpperCase()
                                : "U",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? "User",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? "",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios, size: 16)
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ================= SETTINGS OPTIONS =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [

                  _buildTile(
                    context,
                    icon: Icons.directions_car_rounded,
                    color: Colors.blue,
                    title: "Register Vehicle",
                    page: const AddVehiclePage(),
                  ),

                  _divider(),

                  _buildTile(
                    context,
                    icon: Icons.inventory_2_outlined,
                    color: Colors.brown,
                    title: "Inventory",
                    page: InventoryPage(),
                  ),

                  _divider(),

                  _buildTile(
                    context,
                    icon: Icons.track_changes_rounded,
                    color: Colors.indigo,
                    title: "Track Service",
                    page: const TrackServicePage(),
                    enabled: hasApprovedVehicle,
                  ),

                  _divider(),

                  _buildTile(
                    context,
                    icon: Icons.currency_rupee_rounded,
                    color: Colors.green,
                    title: "Resale Price Check",
                    page: const ResalePage(),
                    enabled: hasApprovedVehicle,
                  ),
                  _divider(),

                  _buildTile(
                    context,
                    icon: Icons.feedback_outlined,
                    color: Colors.orange,
                    title: "Feedback",
                    page: const FeedbackPage(),
                    enabled: hasApprovedVehicle,
                  ),

                  _divider(),

                  _buildTile(
                    context,
                    icon: Icons.analytics_outlined,
                    color: Colors.teal,
                    title: "Driving Behaviour",
                    page: const VehicleBehaviourPage(),
                    enabled: hasApprovedVehicle,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= LOGOUT BUTTON =================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFFF3B30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
            },
        ),
    );
  }

  // ================= DIVIDER =================
  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
    );
  }

  // ================= REUSABLE TILE =================
  Widget _buildTile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required Widget page,
        bool enabled = true,
      }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),

      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled
              ? color.withOpacity(0.12)
              : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? color : Colors.grey,
          size: 20,
        ),
      ),

      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),

      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: enabled ? Colors.black : Colors.grey,
      ),

      onTap: enabled
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      }
          : null,
    );
  }
}