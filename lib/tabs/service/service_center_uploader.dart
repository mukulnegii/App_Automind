import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceCenterUploader extends StatefulWidget {
  const ServiceCenterUploader({super.key});

  @override
  State<ServiceCenterUploader> createState() =>
      _ServiceCenterUploaderState();
}

class _ServiceCenterUploaderState
    extends State<ServiceCenterUploader> {

  bool loading = false;
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> uploadCenters() async {

    setState(() => loading = true);

    WriteBatch batch = firestore.batch();

    List<String> companies = [
      "Hyundai",
      "Kia",
      "Toyota",
      "Mahindra",
      "Tata"
    ];

    Map<String, Map<String, dynamic>> states = {

      "Delhi": {
        "city": "New Delhi",
        "lat": 28.6139,
        "lng": 77.2090
      },

      "Uttar Pradesh": {
        "city": "Noida",
        "lat": 28.5355,
        "lng": 77.3910
      },

      "Haryana": {
        "city": "Gurgaon",
        "lat": 28.4595,
        "lng": 77.0266
      },

      "Rajasthan": {
        "city": "Jaipur",
        "lat": 26.9124,
        "lng": 75.7873
      },

      "Punjab": {
        "city": "Ludhiana",
        "lat": 30.9010,
        "lng": 75.8573
      },

      "Karnataka": {
        "city": "Bangalore",
        "lat": 12.9716,
        "lng": 77.5946
      },

      "Goa": {
        "city": "Panaji",
        "lat": 15.4909,
        "lng": 73.8278
      },
    };

    for (var company in companies) {

      for (var stateEntry in states.entries) {

        for (int i = 1; i <= 10; i++) {

          double latOffset = (i * 0.008);
          double lngOffset = (i * 0.008);

          DocumentReference docRef =
          firestore.collection("Service_Center_List").doc();

          batch.set(docRef, {
            "name":
            "$company ${stateEntry.value["city"]} Center $i",
            "company": company,
            "state": stateEntry.key,
            "city": stateEntry.value["city"],
            "area": "Sector $i",
            "lat": stateEntry.value["lat"] + latOffset,
            "lng": stateEntry.value["lng"] + lngOffset,
            "isActive": true,
            "createdAt": FieldValue.serverTimestamp(),
          });
        }
      }
    }

    await batch.commit();

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("350 Service Centers Uploaded ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: const Text("Upload Service Centers")),
      body: Center(
        child: ElevatedButton(
          onPressed: loading ? null : uploadCenters,
          child: loading
              ? const CircularProgressIndicator(
              color: Colors.white)
              : const Text(
              "Upload 350 Service Centers"),
        ),
      ),
    );
  }
}