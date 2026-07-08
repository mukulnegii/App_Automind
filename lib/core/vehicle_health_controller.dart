import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleHealthController {
  static final VehicleHealthController _instance =
  VehicleHealthController._internal();

  factory VehicleHealthController() => _instance;

  VehicleHealthController._internal();

  final ValueNotifier<Map<String, dynamic>?> healthData =
  ValueNotifier(null);

  Timer? _timer;

  static const String baseUrl =
      "https://vehiclehealth.onrender.com/vehicle";

  void start() {
    _fetch();
    _timer ??=
        Timer.periodic(const Duration(seconds: 6), (_) => _fetch());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch() async {
    try {
      final response =
      await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ===== EXISTING LOGIC (UNCHANGED) =====
        healthData.value = data;

        // ===== NEW ALERT STORAGE LOGIC (ADDED) =====

        final alerts = data["alerts"] as List<dynamic>?;

        if (alerts == null || alerts.isEmpty) return;

        final String fullAlert = alerts.first.toString();

        final String vehicleIdString =
            data["vehicle_id"]?.toString() ?? "";

        if (vehicleIdString.isEmpty) return;

        // Extract vehicle name (Fortuner from "Fortuner 0001")
        final String vehicleName =
            vehicleIdString
                .split(" ")
                .first;

        // Extract short issue (Engine Overheating)
        final String shortIssue =
            fullAlert
                .split(" - ")
                .first;

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        // Find matching vehicle document
        final vehicleQuery = await FirebaseFirestore.instance
            .collection("vehicles")
            .where("userId", isEqualTo: user.uid)
            .where("model", isEqualTo: vehicleName)
            .limit(1)
            .get();

        if (vehicleQuery.docs.isEmpty) return;

        final vehicleDoc = vehicleQuery.docs.first;
        final carId = vehicleDoc.id;
        final vehicleCompany =
            vehicleDoc.data()["company"] ?? "";

        // Store alert in Firestore (Demo Mode - no duplicate check)
        await FirebaseFirestore.instance
            .collection("vehicle_alerts")
            .add({
          "carId": carId,
          "vehicleName": vehicleName,
          "vehicleCompany": vehicleCompany,
          "userId": user.uid,
          "alertMessage": fullAlert,
          "shortIssue": shortIssue,
          "createdAt": FieldValue.serverTimestamp(),
          "isHandled": false,
        });
      }
    } catch (_) {}
  }
}