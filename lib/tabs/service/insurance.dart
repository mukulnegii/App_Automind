import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class InsurancePage extends StatefulWidget {
  const InsurancePage({super.key});

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {

  final TextEditingController _descriptionController =
  TextEditingController();

  bool _loading = false;
  File? _selectedImage;

  /// PICK IMAGE
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image Selected")),
      );
    }
  }

  /// SUBMIT
  Future<void> _submitDescription() async {

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe your situation")),
      );
      return;
    }

    setState(() => _loading = true);

    try {

      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection("insurance_requests")
          .add({
        "userId": user?.uid,
        "description": _descriptionController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      _descriptionController.clear();
      _selectedImage = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Submitted Successfully")),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Insurance Support",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [



            const SizedBox(height: 8),

            const Text(
              "Describe the accident or issue and upload supporting images.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            /// DESCRIPTION CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0,2),
                  )
                ],
              ),

              child: TextField(
                controller: _descriptionController,
                maxLines: 6,

                decoration: InputDecoration(
                  hintText: "Describe your situation...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// IMAGE UPLOAD CARD
            GestureDetector(
              onTap: _pickImage,

              child: Container(

                padding: const EdgeInsets.all(18),
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                    )
                  ],
                ),

                child: Column(
                  children: [

                    const Icon(
                      Icons.cloud_upload,
                      size: 40,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Upload FIR / Accident Image",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Tap to select image",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    if (_selectedImage != null) ...[

                      const SizedBox(height: 15),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: Image.file(
                          _selectedImage!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),

            const Spacer(),

            /// SUBMIT BUTTON
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: _loading ? null : _submitDescription,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: _loading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  "Submit Claim",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}