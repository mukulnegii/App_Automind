import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VehicleMainCard extends StatelessWidget {

  final String vehicleId;
  final String userId;
  final String company;
  final String model;
  final String reg;
  final String status;

  const VehicleMainCard({
    super.key,
    required this.vehicleId,
    required this.userId,
    required this.company,
    required this.model,
    required this.reg,
    required this.status,
  });

  // ================= DELETE VEHICLE =================

  void _handleLongPress(BuildContext context) async {

    if (status != "rejected") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only declined vehicles can be deleted"),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Vehicle"),
          content: const Text(
              "Are you sure you want to delete this vehicle?"),
          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("vehicles")
                    .doc(vehicleId)
                    .delete();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Vehicle deleted successfully"),
                  ),
                );
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= BOOKING QUERY =================

  Stream<QuerySnapshot> _bookingStream() {
    return FirebaseFirestore.instance
        .collection("service_booking")
        .where("userId", isEqualTo: userId)
        .where("vehicleId", isEqualTo: vehicleId)
        .where("status", isEqualTo: "scheduled")
        .orderBy("createdAt", descending: true)
        .limit(1)
        .snapshots();
  }

  // ================= STATUS HELPERS =================

  Color _statusColor() {
    if (status == "approved") return Colors.green;
    if (status == "rejected") return Colors.red;
    return Colors.orange;
  }

  String _statusText() {
    if (status == "approved") return "Registered";
    if (status == "rejected") return "Declined";
    return "Pending";
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onLongPress: () => _handleLongPress(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 175,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0B132B),
              Color(0xFF1C2541),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 22,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Row(
          children: [

            // Vehicle Icon Section
            Container(
              width: 110,
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 42,
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(
                      "$company $model",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Reg: $reg",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _bookingStream(),
                      builder: (context, snapshot) {

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Text(
                            "",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          );
                        }

                        final booking =
                        snapshot.data!.docs.first.data()
                        as Map<String, dynamic>;

                        final Timestamp? timestamp =
                        booking["date"];

                        final String time =
                            booking["time"] ?? "";

                        String formattedDate = "";

                        if (timestamp != null) {
                          formattedDate =
                              DateFormat("MMM d, yyyy")
                                  .format(timestamp.toDate());
                        }

                        return Text(
                          "",
                          style: const TextStyle(
                            color: Colors.lightGreenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _statusColor().withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        _statusText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}