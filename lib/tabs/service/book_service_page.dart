// FULL FILE — UI POLISHED
// LOGIC UNCHANGED

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'insurance.dart';
import '../../services/notification_service.dart';

class BookServicePage extends StatefulWidget {

  final String? autoVehicleId;
  final String? autoServiceType;
  final String? autoIssue;
  final bool autoFromAlert;

  const BookServicePage({
    super.key,
    this.autoVehicleId,
    this.autoServiceType,
    this.autoIssue,
    this.autoFromAlert = false,
  });

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

  bool bookingForSomeoneElse = false;
  double? referenceLat;
  double? referenceLng;
  List<Map<String, dynamic>> dynamicCenters = [];

  List<dynamic> availableSlots = [];
  void tryFetchSlots() {
    if (selectedCenter != null &&
        selectedService != null &&
        selectedService != "Other" &&
        selectedDate != null) {

      fetchSlots();
    }
  }
  @override
  void initState() {
    super.initState();

    if (widget.autoFromAlert) {
      selectedCar = widget.autoVehicleId;
      selectedService = widget.autoServiceType;
      showOtherBox = widget.autoServiceType == "Other";

      if (widget.autoServiceType == "Other") {
        otherServiceCtrl.text = widget.autoIssue ?? "";
      }
    }
  }

  final String apiUrl = "https://rutilant-waspish-lacy.ngrok-free.dev/available-slots";

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
    } catch (_) {}
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

  Future<void> fetchAndSortCenters() async {

    if (selectedCar == null ||
        referenceLat == null ||
        referenceLng == null) return;

    final vehicleDoc = await FirebaseFirestore.instance
        .collection("vehicles")
        .doc(selectedCar)
        .get();

    final company = vehicleDoc.data()?['company'];

    String? detectedState =
    await getStateFromCoordinates(
        referenceLat!, referenceLng!);

    if (detectedState == null) return;

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

    tryFetchSlots();
  }

  Future<void> fetchSlots() async {

    if (selectedCenter == null ||
        selectedService == null ||
        selectedDate == null) {
      print("Slots not fetched: Missing fields");
      return;
    }

    if (selectedService == "Other") {
      print("Slots disabled for Other service");
      return;
    }

    setState(() => slotLoading = true);

    try {

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true"
        },
        body: jsonEncode({
          "center_id": selectedCenter,
          "date": DateFormat('yyyy-MM-dd').format(selectedDate!),
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

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
      print("API ERROR: $e");
      setState(() {
        availableSlots = [];
      });
    }

    setState(() => slotLoading = false);
  }

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

    tryFetchSlots();
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

  Widget sectionCard(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Book Service"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [

              sectionCard(
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    const Text("Select Vehicle",
                        style: TextStyle(
                            fontWeight:
                            FontWeight.bold)),

                    const SizedBox(height: 10),

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

                        final docs =
                            snapshot.data!.docs;

                        return DropdownButtonFormField<
                            String>(
                          value: selectedCar,
                          hint:
                          const Text(
                              "Choose Car"),
                          items: docs.map((doc) {
                            final data =
                            doc.data()
                            as Map<
                                String,
                                dynamic>;
                            return DropdownMenuItem<
                                String>(
                              value: doc.id,
                              child: Text(
                                  "${data["company"]} ${data["model"]}"),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedCar = v;
                              selectedCenter =
                              null;
                              dynamicCenters =
                              [];
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              sectionCard(
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    const Text("Service Type",
                        style: TextStyle(
                            fontWeight:
                            FontWeight.bold)),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<
                        String>(
                      value: selectedService,
                      hint: const Text(
                          "Select Service"),
                      items: services
                          .map((e) =>
                          DropdownMenuItem<
                              String>(
                            value: e,
                            child:
                            Text(e),
                          ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedService = v;
                          showOtherBox =
                              v ==
                                  "Other";
                          selectedTime =
                          null;
                        });
                        tryFetchSlots();
                      },
                    ),

                    if (showOtherBox)
                      Padding(
                        padding:
                        const EdgeInsets.only(
                            top: 10),
                        child: TextField(
                          controller:
                          otherServiceCtrl,
                          decoration:
                          const InputDecoration(
                              hintText:
                              "Describe service"),
                        ),
                      ),
                  ],
                ),
              ),

              sectionCard(
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    const Text(
                        "Booking For Someone Else",
                        style: TextStyle(
                            fontWeight:
                            FontWeight.bold)),

                    SwitchListTile(
                      contentPadding:
                      EdgeInsets.zero,
                      title: Text(
                        bookingForSomeoneElse
                            ? "Yes"
                            : "No",
                      ),
                      value:
                      bookingForSomeoneElse,
                      onChanged:
                          (value) {
                        setState(() {
                          bookingForSomeoneElse =
                              value;
                          selectedCenter =
                          null;
                          dynamicCenters =
                          [];
                        });
                      },
                    ),

                    ElevatedButton.icon(
                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        Colors.deepPurple,
                        foregroundColor:
                        Colors.white,
                      ),
                      icon: const Icon(
                          Icons.location_on),
                      label: Text(
                        bookingForSomeoneElse
                            ? "Use Last Parked Location"
                            : "Use Current Location",
                      ),
                      onPressed:
                      bookingForSomeoneElse
                          ? useLastParkedLocation
                          : useCurrentLocation,
                    ),
                  ],
                ),
              ),

              sectionCard(
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    const Text(
                        "Service Center",
                        style: TextStyle(
                            fontWeight:
                            FontWeight.bold)),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<
                        String>(
                      value: selectedCenter,
                      hint:
                      const Text(
                          "Select Center"),
                      items: dynamicCenters
                          .map<
                          DropdownMenuItem<
                              String>>(
                              (center) {
                            final name =
                            center[
                            'name']
                            as String;
                            final distance =
                            center[
                            'distance']
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
                          selectedCenter =
                              v;
                        });
                        tryFetchSlots();
                      },
                    ),
                  ],
                ),
              ),

              // INSURANCE CLAIM SECTION
              sectionCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Insurance Claim",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(insuranceClaim ? "Yes" : "No"),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
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
                  ],
                ),
              ),

              sectionCard(
                Column(
                  children: [

                    ListTile(
                      title: Text(
                        selectedDate ==
                            null
                            ? "Select Slot Date"
                            : DateFormat(
                            "dd MMM yyyy")
                            .format(
                            selectedDate!),
                      ),
                      trailing:
                      const Icon(
                          Icons.calendar_today),
                      onTap: pickDate,
                    ),

                    const Divider(),

                    ListTile(
                      title: Text(
                        expectedCompletionDate ==
                            null
                            ? "Expected Completion Date"
                            : DateFormat(
                            "dd MMM yyyy")
                            .format(
                            expectedCompletionDate!),
                      ),
                      trailing:
                      const Icon(
                          Icons.calendar_month),
                      onTap:
                      pickExpectedDate,
                    ),
                  ],
                ),
              ),

              sectionCard(
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    const Text(
                        "Available Slots",
                        style: TextStyle(
                            fontWeight:
                            FontWeight.bold)),

                    const SizedBox(
                        height: 10),

                    if (slotLoading)
                      const CircularProgressIndicator(),

                    Wrap(
                      spacing: 10,
                      children:
                      availableSlots.map(
                              (slot) {

                            bool
                            isAvailable =
                            slot[
                            "available"];
                            bool
                            isSelected =
                                selectedTime ==
                                    slot[
                                    "time"];

                            return ChoiceChip(
                              label: Text(
                                  slot[
                                  "time"]),
                              selected:
                              isSelected,
                              onSelected:
                              isAvailable
                                  ? (_) {
                                setState(
                                        () {
                                      selectedTime =
                                      slot[
                                      "time"];
                                    });
                              }
                                  : null,
                              selectedColor:
                              Colors
                                  .deepPurple,
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              sectionCard(
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    const Text(
                        "Contact Number",
                        style: TextStyle(
                            fontWeight:
                            FontWeight.bold)),
                    const SizedBox(
                        height: 10),

                    TextField(
                      controller:
                      contactCtrl,
                      keyboardType:
                      TextInputType
                          .phone,
                      decoration:
                      const InputDecoration(
                          hintText:
                          "Enter Contact Number"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                  ElevatedButton
                      .styleFrom(
                    padding:
                    const EdgeInsets
                        .symmetric(
                        vertical:
                        16),
                    backgroundColor:
                    Colors
                        .deepPurple,
                  ),
                  onPressed:
                  loading
                      ? null
                      : bookService,
                  child: loading
                      ? const CircularProgressIndicator(
                      color:
                      Colors.white)
                      : const Text(
                      "Book Service",
                      style: TextStyle(
                          fontSize:
                          16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}