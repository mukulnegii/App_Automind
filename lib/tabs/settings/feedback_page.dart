import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/book_service_page.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int rating = 0;
  String comment = "";
  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '1234567890');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  String getMessage() {
    if (rating < 3) {
      return "We sincerely apologize for your experience. Kindly let us know where we could have improved.";
    } else if (rating == 3) {
      return "Thank you for your feedback. Could you please share what made your experience neutral?";
    } else {
      return "We're glad you had a good experience! Please let us know if there is anything we can still improve.";
    }
  }

  Future<void> submitFeedback() async {
    if (rating == 0) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {

      // Fetch user name from Firestore
      final userDoc = await _firestore
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data();

      String userName = userData?["username"] ?? "Unknown";

      // Save feedback
      await _firestore.collection("feedback").add({
        "userId": user.uid,
        "userName": userName, // ✅ Added user name
        "userEmail": user.email, // optional but useful
        "rating": rating,
        "comment": comment,
        "createdAt": FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print("Feedback Error: $e");
    }

    setState(() {
      isLoading = false;
    });

    if (rating < 3) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "We're Sorry",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
              "We sincerely apologize for your experience. Our team would like to assist you further."),
          actions: [
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: makePhoneCall,
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookServicePage(),
                  ),
                );
              },
              child: const Text("Book Service"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Thank You!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
              "Your feedback has been submitted successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  Widget buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= rating ? Icons.star : Icons.star_border,
        color: index <= rating ? Colors.amber : Colors.grey.shade400,
        size: 34,
      ),
      onPressed: () {
        setState(() {
          rating = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Clean background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "Service Feedback",
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How was your service experience?",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                    List.generate(5, (index) => buildStar(index + 1)),
                  ),

                  const SizedBox(height: 20),

                  if (rating > 0) ...[
                    Text(
                      getMessage(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Write your feedback here...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        comment = value;
                      },
                    ),
                  ],

                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF1F2937), // Stable dark button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: isLoading ? null : submitFeedback,
                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "Submit Feedback",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}