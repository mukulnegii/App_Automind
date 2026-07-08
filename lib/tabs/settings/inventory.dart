import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _partIdController =
  TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _partData;
  bool _notFound = false;

  // ================= VERIFY FUNCTION =================

  Future<void> _verifyPart() async {
    final partId =
    _partIdController.text.trim().toUpperCase();

    if (partId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Part ID")),
      );
      return;
    }

    setState(() {
      _loading = true;
      _partData = null;
      _notFound = false;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection("part_verification")
          .doc(partId)
          .get();

      if (doc.exists) {
        setState(() {
          _partData = doc.data();
        });
      } else {
        setState(() {
          _notFound = true;
        });
      }
    } catch (e) {
      setState(() {
        _notFound = true;
      });
    }

    setState(() => _loading = false);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Genuine Part Verification",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.black,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),

            const Text(
              "Enter Part ID",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937), // darker text
              ),
            ),

            const SizedBox(height: 10),

            // INPUT FIELD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _partIdController,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFF134E5E),
                  ),
                  hintText: "Example: MSBP-SWT-301",
                  hintStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                _loading ? null : _verifyPart,
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0F766E), // rich teal
                        Color(0xFF16A34A), // emerald
                      ],
                    ),
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Verify Part",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 35),

            // RESULT CARD
            if (_partData != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.06),
                      blurRadius: 18,
                      offset:
                      const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Container(
                          padding:
                          const EdgeInsets.all(6),
                          decoration:
                          const BoxDecoration(
                            color:
                            Color(0xFFE6F9F0),
                            shape:
                            BoxShape.circle,
                          ),
                          child: Icon(
                            _partData![
                            "isGenuine"] ==
                                true
                                ? Icons
                                .verified_rounded
                                : Icons
                                .warning_amber_rounded,
                            color: _partData![
                            "isGenuine"] ==
                                true
                                ? const Color(
                                0xFF16A34A)
                                : Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _partData![
                            "isGenuine"] ==
                                true
                                ? "Genuine Company Part"
                                : "Not Genuine Part",
                            style:
                            TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                              color: _partData![
                              "isGenuine"] ==
                                  true
                                  ? const Color(
                                  0xFF065F46)
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 28),

                    _infoRow("Company",
                        _partData!["companyName"]),
                    _infoRow("Car Model",
                        _partData!["carModel"]),
                    _infoRow("Part Name",
                        _partData!["partName"]),
                  ],
                ),
              ),
            ],

            if (_notFound) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFFEE2E2),
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(
                          0xFFFCA5A5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error,
                        color: Color(
                            0xFFB91C1C)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Part Not Found\nThis part is not registered in the system.",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w600,
                          color: Color(
                              0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================= INFO ROW WIDGET =================

  Widget _infoRow(
      String title, String value) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
              fontWeight:
              FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontSize: 15,
                color:
                Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}