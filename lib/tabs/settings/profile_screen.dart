import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  User? user;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _loadUserData();
  }

  // ---------------- LOAD USERNAME ----------------
  Future<void> _loadUserData() async {
    if (user == null) return;

    var doc = await _firestore.collection('users').doc(user!.uid).get();

    if (doc.exists) {
      _usernameController.text = doc.data()?['username'] ?? "";
    }
  }

  // ---------------- SAVE USERNAME ----------------
  Future<void> _saveUsername() async {
    if (user == null) return;

    String username = _usernameController.text.trim();

    if (username.isEmpty) {
      _showMessage("Username cannot be empty");
      return;
    }

    setState(() => _loading = true);

    // Check if username already exists
    var check = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    // Allow same user to keep their username
    if (check.docs.isNotEmpty &&
        check.docs.first.id != user!.uid) {
      setState(() => _loading = false);
      _showMessage("Username already taken");
      return;
    }

    await _firestore.collection('users').doc(user!.uid).update({
      'username': username,
    });

    setState(() => _loading = false);

    _showMessage("Username updated successfully");
  }

  // ---------------- CHANGE PASSWORD ----------------
  Future<void> _changePassword() async {
    if (user == null) return;

    String newPassword = _newPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showMessage("Password must be at least 6 characters");
      return;
    }

    try {
      setState(() => _loading = true);

      await user!.updatePassword(newPassword);

      _newPasswordController.clear();

      _showMessage("Password updated successfully");

    } catch (e) {
      _showMessage("Re-login required to change password");
    }

    setState(() => _loading = false);
  }

  // ---------------- MESSAGE ----------------
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: user == null
          ? const Center(child: Text("No user logged in"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            // ---------------- EMAIL ----------------
            const Text(
              "Google Email",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: user!.email ?? "",
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ---------------- CHANGE PASSWORD ----------------
            const Text(
              "New Password",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter new password",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Change Password"),
              ),
            ),

            const SizedBox(height: 35),

            // ---------------- USERNAME ----------------
            const Text(
              "Username",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Enter username",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Save Username"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}