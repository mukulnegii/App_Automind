import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'insurance.dart';
import '../../services/notification_service.dart';

class BookServicePage extends StatefulWidget {
  const BookServicePage({super.key});

  @override
  State<BookServicePage> createState() => _BookServicePageState();
}

class _BookServicePageState extends State<BookServicePage> {

  final TextEditingController otherServiceCtrl = TextEditingController();
  final TextEditingController contactCtrl = TextEditingController();

  String? selectedCar;
  String? selectedService;
  DateTime? selectedDate;
  DateTime? expectedCompletionDate;   // ✅ NEW
  String? selectedTime;
  String? selectedCenter;

  bool showOtherBox = false;
  bool loading = false;
  bool slotLoading = false;
  bool insuranceClaim = false;

  List<dynamic> availableSlots = [];

  final String apiUrl =
      "https://carlie-verdigrisy-drusilla.ngrok-free.dev/available-slots";

  final List<String> services = [
    "1st Service",
    "2nd Service",
    "3rd Service",
    "Other"
  ];

  final List<String> serviceCenters = [
    "AutoMind Service Hub",
    "Prime Motors",
    "SpeedFix Garage",
    "City Car Care",
  ];

  // ================= FETCH ML SLOTS =================

  Future<void> fetchSlots() async {

    if (selectedCenter == null ||
        selectedService == null ||
        selectedDate == null) return;

    if (selectedService == "Other") return;

    setState(() => slotLoading = true);

    try {

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "center": selectedCenter,
          "service_type": selectedService,
          "date": DateFormat('yyyy-MM-dd').format(selectedDate!),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availableSlots = data["slots"] ?? [];
        });
      } else {
        setState(() {
          availableSlots = [];
        });
      }

    } catch (e) {
      setState(() {
        availableSlots = [];
      });
    }

    setState(() => slotLoading = false);
  }

  // ================= DATE PICKERS =================

  Future<void> pickDate() async {

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
        selectedTime = null;
      });

      await fetchSlots();
    }
  }

  Future<void> pickExpectedDate() async {

    final date = await showDatePicker(
      context: context,
      firstDate: selectedDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      initialDate: selectedDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        expectedCompletionDate = date;
      });
    }
  }

  // ================= BOOK SERVICE =================

  Future<void> bookService() async {

    if (selectedCar == null ||
        selectedService == null ||
        selectedDate == null ||
        selectedTime == null ||
        selectedCenter == null ||
        contactCtrl.text.isEmpty ||
        expectedCompletionDate == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final vehicleDoc = await FirebaseFirestore.instance
          .collection("vehicles")
          .doc(selectedCar)
          .get();

      if (!vehicleDoc.exists) throw Exception("Vehicle not found");

      final vehicleData = vehicleDoc.data() as Map<String, dynamic>;

      final serviceName = selectedService == "Other"
          ? otherServiceCtrl.text
          : selectedService;

      final hour = int.parse(selectedTime!.split(":")[0]);

      final slotDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        hour,
      );

      await FirebaseFirestore.instance
          .collection("service_booking")
          .add({

        // USER INFO
        "userId": user.uid,
        "userEmail": user.email,
        "contact": contactCtrl.text,   // ✅ FIELD NAME FIXED

        // VEHICLE INFO
        "carId": selectedCar,
        "vehicleName": vehicleData["model"],
        "vehicleCompany": vehicleData["company"],

        // SERVICE INFO
        "serviceType": serviceName,
        "serviceCenter": selectedCenter,

        // SLOT INFO
        "bookingDate": Timestamp.fromDate(selectedDate!),
        "slotTime": selectedTime,
        "slotDateTime": Timestamp.fromDate(slotDateTime),

        // EXPECTED COMPLETION DATE (USER INPUT)
        "expectedCompletionTime":
        Timestamp.fromDate(expectedCompletionDate!),  // ✅ NEW

        // STATUS
        "status": "scheduled",
        "liveStage": "waiting",

        // FLOW
        "serviceStartTime": null,
        "actualCompletionTime": null,

        // SUPERVISOR
        "supervisorId": null,
        "supervisorName": null,

        // ML
        "mlPredicted": selectedService != "Other",
        "mlEngineVersion": "v1.0-slot-model",

        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service booked successfully ✅")),
      );
      await NotificationService.showServiceBookedNotification();

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Book Service")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Schedule Vehicle Service",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              const Text("Select Car"),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("vehicles")
                    .where("userId", isEqualTo: user!.uid)
                    .where("status", isEqualTo: "approved")
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedCar,
                    hint: const Text("Choose Car"),
                    items: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text("${data["company"]} ${data["model"]}"),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedCar = v),
                  );
                },
              ),

              const SizedBox(height: 18),

              const Text("Service Type"),

              DropdownButtonFormField<String>(
                value: selectedService,
                hint: const Text("Select Service"),
                items: services
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedService = v;
                    showOtherBox = v == "Other";
                    selectedTime = null;
                  });
                  fetchSlots();
                },
              ),

              if (showOtherBox) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: otherServiceCtrl,
                  decoration:
                  const InputDecoration(hintText: "Describe service"),
                ),
              ],
              const SizedBox(height: 18),

              const Text("Insurance Claim"),

              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text("Yes / No"),
                value: insuranceClaim,
                onChanged: (value) {
                  setState(() {
                    insuranceClaim = value;
                  });
                },
              ),

              if (insuranceClaim) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Document Submission"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InsurancePage(),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 18),

              const Text("Slot Date"),

              ListTile(
                title: Text(
                  selectedDate == null
                      ? "Select Date"
                      : DateFormat("dd MMM yyyy").format(selectedDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickDate,
              ),

              const SizedBox(height: 18),

              const Text("Expected Completion Date"),

              ListTile(
                title: Text(
                  expectedCompletionDate == null
                      ? "Select Expected Completion Date"
                      : DateFormat("dd MMM yyyy")
                      .format(expectedCompletionDate!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: pickExpectedDate,
              ),

              const SizedBox(height: 18),

              const Text("Available Slots"),

              if (slotLoading)
                const CircularProgressIndicator(),

              Wrap(
                spacing: 10,
                children: availableSlots.map((slot) {

                  bool isAvailable = slot["available"];
                  bool isSelected = selectedTime == slot["time"];

                  return ChoiceChip(
                    label: Text(slot["time"]),
                    selected: isSelected,
                    onSelected: isAvailable
                        ? (_) {
                      setState(() {
                        selectedTime = slot["time"];
                      });
                    }
                        : null,
                    selectedColor: Colors.green,
                  );

                }).toList(),
              ),

              const SizedBox(height: 18),

              const Text("Service Center"),

              DropdownButtonFormField<String>(
                value: selectedCenter,
                hint: const Text("Select Center"),
                items: serviceCenters
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedCenter = v);
                  fetchSlots();
                },
              ),

              const SizedBox(height: 18),

              const Text("Contact Number"),

              TextField(
                controller: contactCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                const InputDecoration(hintText: "Enter Contact Number"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : bookService,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Book Service"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}