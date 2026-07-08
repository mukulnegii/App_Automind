import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {

  final TextEditingController _companyCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _regCtrl = TextEditingController();

  bool _isLoading = false;
  String? _selectedPackage;

  // ================= SAVE (UNCHANGED) =================

  Future<void> _registerVehicle() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (_companyCtrl.text.isEmpty ||
        _modelCtrl.text.isEmpty ||
        _regCtrl.text.isEmpty ||
        _selectedPackage == null) {

      _showMsg("Please fill all fields including package");
      return;
    }

    try {

      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection("vehicles")
          .add({

        "userId": user.uid,
        "company": _companyCtrl.text.trim(),
        "model": _modelCtrl.text.trim(),
        "regNumber": _regCtrl.text.trim(),
        "package": _selectedPackage,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        _showMsg("Vehicle Registered Successfully ✅");
      }

    } catch (e) {
      _showMsg("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= PACKAGE DIALOG (UI IMPROVED) =================

  void _showPackageDialog() {

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [

                  const Text(
                    "Choose AutoMind Package",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _packageCard(
                    title: "🚗 AutoMind Core",
                    description:
                    "Essential AI Protection\n\n"
                        "• Vehicle Health Score\n"
                        "• Basic Predictive Alerts\n"
                        "• DTC Explanation\n"
                        "• Service Reminders",
                    value: "AutoMind Core",
                  ),

                  const SizedBox(height: 16),

                  _packageCard(
                    title: "🚀 AutoMind Pro",
                    description:
                    "Full Autonomous Intelligence\n\n"
                        "• Everything in Core\n"
                        "• Failure Risk % Prediction\n"
                        "• Advanced Root Cause Analysis\n"
                        "• Auto Service Booking\n"
                        "• Manufacturing / Recall Alerts\n"
                        "• Priority Support",
                    value: "AutoMind Pro",
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= PACKAGE CARD =================

  Widget _packageCard({
    required String title,
    required String description,
    required String value,
  }) {
    final bool isSelected = _selectedPackage == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = value;
        });

        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 230, // ✅ SAME FIXED HEIGHT FOR BOTH
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TITLE
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 12),

            // FEATURES (Scrollable inside fixed height)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color:
                    isSelected ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Selection Indicator
            Align(
              alignment: Alignment.bottomRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isSelected
                    ? const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                  key: ValueKey("selected"),
                )
                    : const SizedBox(
                  key: ValueKey("empty"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _modelCtrl.dispose();
    _regCtrl.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Register Vehicle"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            const SizedBox(height: 10),

            _modernField("Company", _companyCtrl),
            _modernField("Model", _modelCtrl),
            _modernField("Registration Number", _regCtrl),

            const SizedBox(height: 10),

            // PACKAGE SELECT

            GestureDetector(
              onTap: _showPackageDialog,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: _selectedPackage != null
                      ? const LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: _selectedPackage == null ? Colors.white : null,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _selectedPackage == null
                        ? Colors.grey.shade300
                        : Colors.black,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  children: [

                    // ICON
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _selectedPackage == null
                            ? Colors.grey.shade100
                            : Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        color: _selectedPackage == null
                            ? Colors.black54
                            : Colors.white,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // TEXT
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            _selectedPackage ?? "Choose Your Package",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedPackage == null
                                  ? Colors.black87
                                  : Colors.white,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _selectedPackage == null
                                ? "Select AutoMind plan to continue"
                                : "Package Selected",
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedPackage == null
                                  ? Colors.grey
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CHECK OR ARROW
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _selectedPackage == null
                          ? const Icon(Icons.arrow_forward_ios,
                          size: 16, key: ValueKey("arrow"))
                          : const Icon(Icons.check_circle,
                          color: Colors.greenAccent,
                          key: ValueKey("check")),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // REGISTER BUTTON

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                _isLoading ? null : _registerVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
                    : const Text(
                  "Register Vehicle",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= MODERN FIELD =================

  Widget _modernField(
      String label,
      TextEditingController controller,
      ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter $label",
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
              const BorderSide(color: Colors.black, width: 1.4),
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}