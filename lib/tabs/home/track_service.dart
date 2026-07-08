import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrackServicePage extends StatelessWidget {
  const TrackServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Track Your Service",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("service_booking")
            .where("userId", isEqualTo: user.uid)
            .orderBy("bookingDate", descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Active Service Booking",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          var data = snapshot.data!.docs.first;
          final bookingData = data.data() as Map<String, dynamic>;

          String status = bookingData["status"] ?? "";
          String liveStage = bookingData["liveStage"] ?? "";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatusCard(status),
                const SizedBox(height: 25),
                _buildServiceDetails(data),
                const SizedBox(height: 25),
                _buildLiveStage(liveStage),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔵 PREMIUM STATUS CARD
  Widget _buildStatusCard(String status) {
    Color statusColor = Colors.orange;

    if (status == "completed") {
      statusColor = Colors.green;
    } else if (status == "in_process") {
      statusColor = Colors.blue;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: statusColor.withOpacity(0.2),
            child: Icon(Icons.car_repair, size: 35, color: statusColor),
          ),
          const SizedBox(height: 15),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 🛠 SERVICE DETAILS CARD
  Widget _buildServiceDetails(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _infoRow("Vehicle", data["vehicleName"] ?? "N/A"),
            _infoRow("Company", data["vehicleCompany"] ?? "N/A"),
            _infoRow("Car ID", data["carId"] ?? "N/A"),
            _infoRow("Service Type", data["serviceType"] ?? "N/A"),
            _infoRow("Service Center", data["serviceCenter"] ?? "N/A"),
            _infoRow("Slot Time", data["slotTime"] ?? "N/A"),
            _infoRow("Contact", data["contact"] ?? "N/A"),
            _infoRow("Supervisor", data["supervisorName"] ?? "Not Assigned"),
            _infoRow("Status", data["status"] ?? "N/A"),
          ],
        ),
      ),
    );
  }

  /// 📍 MODERN SERVICE PROGRESS
  Widget _buildLiveStage(String liveStage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Service Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _stageTile("Booked", liveStage == "scheduled"),
          _stageTile("In Service", liveStage == "working"),
          _stageTile("Completed", liveStage == "done"),
        ],
      ),
    );
  }

  Widget _stageTile(String title, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.check : Icons.circle,
              size: 16,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}