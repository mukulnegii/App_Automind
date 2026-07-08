import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResalePage extends StatefulWidget {
  const ResalePage({super.key});

  @override
  State<ResalePage> createState() => _ResalePageState();
}

class _ResalePageState extends State<ResalePage> {

  String? selectedCar;
  double? predictedValue;

  final TextEditingController purchaseCostCtrl = TextEditingController();
  final TextEditingController kmTravelledCtrl = TextEditingController();
  final TextEditingController customPartCtrl = TextEditingController();

  List<String> selectedParts = [];

  final List<String> partOptions = [
    "Battery Replaced",
    "Tyres Replaced",
    "Clutch Replaced",
    "Engine Work",
    "Gearbox Repair"
  ];

  bool loading = false;

  // ================= CALCULATE RESALE (UNCHANGED LOGIC) =================

  Future<void> calculateResale() async {

    if (selectedCar == null ||
        purchaseCostCtrl.text.isEmpty ||
        kmTravelledCtrl.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill all required fields")),
      );
      return;
    }

    setState(() => loading = true);

    double purchaseCost = double.parse(purchaseCostCtrl.text);
    double kmTravelled = double.parse(kmTravelledCtrl.text);

    final vehicleDoc = await FirebaseFirestore.instance
        .collection("vehicles")
        .doc(selectedCar)
        .get();

    final vehicleData = vehicleDoc.data() as Map<String, dynamic>;

    int ageYears = 1;

    if (vehicleData["purchaseDate"] != null) {
      final purchaseDate = vehicleData["purchaseDate"].toDate();

      ageYears = DateTime.now()
          .difference(purchaseDate)
          .inDays ~/
          365;

      if (ageYears < 1) ageYears = 1;
    }

    double ageDepreciation = purchaseCost * (0.12 * ageYears);

    double kmFactor = (kmTravelled / 10000) * 0.005;
    double kmImpact = purchaseCost * kmFactor;

    double partsImpact = 0;

    for (String part in selectedParts) {
      if (part == "Engine Work" ||
          part == "Gearbox Repair") {
        partsImpact += purchaseCost * 0.08;
      } else {
        partsImpact += purchaseCost * 0.03;
      }
    }

    double resale =
        purchaseCost -
            ageDepreciation -
            kmImpact -
            partsImpact;

    if (resale < 0) resale = 0;

    setState(() {
      predictedValue = resale;
      loading = false;
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Resale Value Estimator",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            const Text(
              "Predict Your Car Resale Value",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 25),

            // ================= VEHICLE =================

            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Select Registered Vehicle",
                    style: TextStyle(
                        fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 12),

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
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      return DropdownButtonFormField<String>(
                        value: selectedCar,
                        decoration:
                        _inputDecoration("Choose Vehicle"),
                        items: docs.map((doc) {

                          final data =
                          doc.data() as Map<String, dynamic>;

                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                              "${data["company"]} ${data["model"]}",
                            ),
                          );

                        }).toList(),
                        onChanged: (v) =>
                            setState(() => selectedCar = v),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= COST & KM =================

            _buildCard(
              child: Column(
                children: [

                  TextField(
                    controller: purchaseCostCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                        "Original Purchase Cost (₹)"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: kmTravelledCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                        "Total Kilometers Travelled"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= PARTS =================

            _buildCard(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Parts Replaced",
                    style: TextStyle(
                        fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  ...partOptions.map((part) {
                    return CheckboxListTile(
                      contentPadding:
                      EdgeInsets.zero,
                      activeColor:
                      const Color(0xFF243B55),
                      title: Text(part),
                      value:
                      selectedParts.contains(part),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedParts.add(part);
                          } else {
                            selectedParts.remove(part);
                          }
                        });
                      },
                    );
                  }),

                  const SizedBox(height: 10),

                  TextField(
                    controller: customPartCtrl,
                    decoration: _inputDecoration(
                        "Add custom replaced part"),
                    onSubmitted: (val) {
                      if (val.isNotEmpty) {
                        setState(() {
                          selectedParts.add(val);
                          customPartCtrl.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ================= BUTTON =================

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed:
                loading ? null : calculateResale,
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF11998E),
                        Color(0xFF38EF7D)
                      ],
                    ),
                    borderRadius:
                    BorderRadius.all(
                        Radius.circular(14)),
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text(
                      "Predict Resale Value",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 35),

            // ================= RESULT =================

            if (predictedValue != null)
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1D976C),
                      Color(0xFF93F9B9)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset:
                      const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  children: [

                    const Text(
                      "Estimated Resale Value",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "₹ ${predictedValue!.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
      const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14),
    );
  }
}