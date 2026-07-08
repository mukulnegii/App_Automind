import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'insurance.dart';
import '../../services/notification_service.dart';
import 'package:geocoding/geocoding.dart';

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
  DateTime? expectedCompletionDate;
  String? selectedTime;
  String? selectedCenter;

  bool showOtherBox = false;
  bool loading = false;
  bool slotLoading = false;
  bool insuranceClaim = false;

  // 🔹 NEW
  bool bookingForSomeoneElse = false;
  double? referenceLat;
  double? referenceLng;
  List<Map<String, dynamic>> dynamicCenters = [];

  List<dynamic> availableSlots = [];

  final String apiUrl =
      "https://carlie-verdigrisy-drusilla.ngrok-free.dev/available-slots";

  final List<String> services = [
    "1st Service",
    "2nd Service",
    "3rd Service",
    "Other"
  ];

  // ================= DISTANCE =================

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<String?> getStateFromCoordinates(
      double lat, double lng) async {

    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        return placemarks.first.administrativeArea;
      }
    } catch (e) {
      print("Geocoding error: $e");
    }

    return null;
  }

  // ================= LOCATION =================

  Future<void> useCurrentLocation() async {

    if (selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select vehicle first")));
      return;
    }

    LocationPermission permission =
    await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position =
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    referenceLat = position.latitude;
    referenceLng = position.longitude;

    await fetchAndSortCenters();
  }

  Future<void> useLastParkedLocation() async {

    if (selectedCar == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("last_parked_location")
        .doc(selectedCar)
        .get();

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No last parked location found")));
      return;
    }

    final data = doc.data();

    referenceLat = data?['lat'];
    referenceLng = data?['lng'];

    await fetchAndSortCenters();
  }

  // ================= FETCH CENTERS =================

  Future<void> fetchAndSortCenters() async {

    if (selectedCar == null ||
        referenceLat == null ||
        referenceLng == null) return;

    final vehicleDoc = await FirebaseFirestore.instance
        .collection("vehicles")
        .doc(selectedCar)
        .get();

    final company = vehicleDoc.data()?['company'];

    // 🔹 Detect state from coordinates
    String? detectedState =
    await getStateFromCoordinates(
        referenceLat!, referenceLng!);

    if (detectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Unable to detect state")));
      return;
    }

    print("Detected State: $detectedState");

    final snapshot = await FirebaseFirestore.instance
        .collection("Service_Center_List")
        .where("company", isEqualTo: company)
        .where("state", isEqualTo: detectedState)
        .where("isActive", isEqualTo: true)
        .get();

    List<Map<String, dynamic>> centers = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      double distance = calculateDistance(
        referenceLat!,
        referenceLng!,
        data['lat'],
        data['lng'],
      );

      centers.add({
        "name": data['name'],
        "distance": distance,
      });
    }

    centers.sort(
            (a, b) => a['distance'].compareTo(b['distance']));

    setState(() {
      dynamicCenters = centers;
      if (centers.isNotEmpty) {
        selectedCenter = centers.first['name'];
      }
    });

    fetchSlots();
  }

  // ================= OLD SLOT LOGIC (UNCHANGED) =================

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
          "date": DateFormat('yyyy-MM-dd')
              .format(selectedDate!),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availableSlots = data["slots"] ?? [];
        });
      } else {
        setState(() => availableSlots = []);
      }

    } catch (e) {
      setState(() => availableSlots = []);
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

  // ================= BOOK SERVICE (UNCHANGED) =================

  Future<void> bookService() async {

    if (selectedCar == null ||
        selectedService == null ||
        selectedDate == null ||
        selectedTime == null ||
        selectedCenter == null ||
        contactCtrl.text.isEmpty ||
        expectedCompletionDate == null) {

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all fields")));
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

      final vehicleData =
      vehicleDoc.data() as Map<String, dynamic>;

      final serviceName =
      selectedService == "Other"
          ? otherServiceCtrl.text
          : selectedService;

      final hour =
      int.parse(selectedTime!.split(":")[0]);

      final slotDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        hour,
      );

      await FirebaseFirestore.instance
          .collection("service_booking")
          .add({

        "userId": user.uid,
        "userEmail": user.email,
        "contact": contactCtrl.text,

        "carId": selectedCar,
        "vehicleName": vehicleData["model"],
        "vehicleCompany": vehicleData["company"],

        "serviceType": serviceName,
        "serviceCenter": selectedCenter,

        "bookingDate":
        Timestamp.fromDate(selectedDate!),
        "slotTime": selectedTime,
        "slotDateTime":
        Timestamp.fromDate(slotDateTime),

        "expectedCompletionTime":
        Timestamp.fromDate(
            expectedCompletionDate!),

        "status": "scheduled",
        "liveStage": "waiting",

        "serviceStartTime": null,
        "actualCompletionTime": null,

        "supervisorId": null,
        "supervisorName": null,

        "mlPredicted":
        selectedService != "Other",
        "mlEngineVersion":
        "v1.0-slot-model",

        "createdAt": Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text("Service booked successfully ✅")));

      await NotificationService
          .showServiceBookedNotification();

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
          SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar:
      AppBar(title: const Text("Book Service")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [



              const SizedBox(height: 25),

              const Text("Select Car"),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("vehicles")
                    .where("userId",
                    isEqualTo: user!.uid)
                    .where("status",
                    isEqualTo: "approved")
                    .snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final docs = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: selectedCar,
                    hint:
                    const Text("Choose Car"),
                    items: docs.map((doc) {
                      final data = doc.data()
                      as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                            "${data["company"]} ${data["model"]}"),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedCar = v;
                        selectedCenter = null;
                        dynamicCenters = [];
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              const Text("Service Type"),

              DropdownButtonFormField<String>(
                value: selectedService,
                hint:
                const Text("Select Service"),
                items: services
                    .map((e) =>
                    DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedService = v;
                    showOtherBox =
                        v == "Other";
                    selectedTime = null;
                  });
                  fetchSlots();
                },
              ),

              if (showOtherBox) ...[
                const SizedBox(height: 10),
                TextField(
                  controller:
                  otherServiceCtrl,
                  decoration:
                  const InputDecoration(
                      hintText:
                      "Describe service"),
                ),
              ],

              const SizedBox(height: 18),

              // 🔹 NEW SECTION

              const Text("Booking For Someone Else"),

              SwitchListTile(
                title: Text(
                  bookingForSomeoneElse ? "Yes" : "No",
                ),
                value: bookingForSomeoneElse,
                onChanged: (value) {
                  setState(() {
                    bookingForSomeoneElse = value;
                    selectedCenter = null;
                    dynamicCenters = [];
                  });
                },
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: Text(
                  bookingForSomeoneElse
                      ? "Use Last Parked Location"
                      : "Use Current Location",
                ),
                onPressed: bookingForSomeoneElse
                    ? useLastParkedLocation
                    : useCurrentLocation,
              ),

              const SizedBox(height: 18),

              const Text("Service Center"),

              DropdownButtonFormField<String>(
                value: selectedCenter,
                hint:
                const Text("Select Center"),
                items: dynamicCenters
                    .map<DropdownMenuItem<String>>(
                        (center) {
                      final name =
                      center['name']
                      as String;
                      final distance =
                      center['distance']
                      as double;

                      return DropdownMenuItem<
                          String>(
                        value: name,
                        child: Text(
                            "$name (${distance.toStringAsFixed(1)} km)"),
                      );
                    }).toList(),
                onChanged: (v) {
                  setState(() {
                    selectedCenter = v;
                  });
                  fetchSlots();
                },
              ),

              const SizedBox(height: 18),

              // 🔹 Rest of your original UI continues unchanged



              const Text("Slot Date"),

              ListTile(
                title: Text(
                  selectedDate == null
                      ? "Select Date"
                      : DateFormat(
                      "dd MMM yyyy")
                      .format(
                      selectedDate!),
                ),
                trailing: const Icon(
                    Icons.calendar_today),
                onTap: pickDate,
              ),

              const SizedBox(height: 18),

              const Text(
                  "Expected Completion Date"),

              ListTile(
                title: Text(
                  expectedCompletionDate ==
                      null
                      ? "Select Expected Completion Date"
                      : DateFormat(
                      "dd MMM yyyy")
                      .format(
                      expectedCompletionDate!),
                ),
                trailing: const Icon(
                    Icons.calendar_month),
                onTap: pickExpectedDate,
              ),

              const SizedBox(height: 18),

              const Text("Available Slots"),

              if (slotLoading)
                const CircularProgressIndicator(),

              Wrap(
                spacing: 10,
                children:
                availableSlots.map(
                        (slot) {

                      bool isAvailable =
                      slot["available"];
                      bool isSelected =
                          selectedTime ==
                              slot["time"];

                      return ChoiceChip(
                        label: Text(
                            slot["time"]),
                        selected:
                        isSelected,
                        onSelected:
                        isAvailable
                            ? (_) {
                          setState(() {
                            selectedTime =
                            slot["time"];
                          });
                        }
                            : null,
                        selectedColor:
                        Colors.green,
                      );
                    }).toList(),
              ),

              const SizedBox(height: 18),

              const Text("Contact Number"),

              TextField(
                controller: contactCtrl,
                keyboardType:
                TextInputType.phone,
                decoration:
                const InputDecoration(
                    hintText:
                    "Enter Contact Number"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                  loading
                      ? null
                      : bookService,
                  child: loading
                      ? const CircularProgressIndicator(
                      color:
                      Colors.white)
                      : const Text(
                      "Book Service"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}