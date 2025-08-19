import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// ProfilePage
/// Displays user profile information (Name, Email, User ID)
/// fetched from Firebase Authentication and Realtime Database.

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  // Initial placeholders while data is loading
  String name = "Loading...";
  String email = "Loading...";
  String userId = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // 📡 Fetch user data when widget is initialized
  }

  /// 🔄 Fetches user data from Firebase Authentication and Realtime Database
  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Reference to the current user's data node in Realtime Database
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(user.uid);

      final snapshot = await userRef.get();
      if (snapshot.exists) {
        // Casting snapshot value safely to Map
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
        setState(() {
          name = data?['name'] ?? "N/A"; // Defaults to 'N/A' if name not found
          email = user.email ?? "N/A";
          userId = user.uid;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 📌 App bar with title
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor:
            const Color.fromARGB(255, 4, 204, 240), // Cyan-colored app bar
      ),

      // 📄 Profile content
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 👤 User avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color.fromARGB(255, 3, 3, 3),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // ℹ️ Profile info rows (name, email, UID)
            _buildProfileRow("Full Name", name),
            _buildProfileRow("Email", email),
            _buildProfileRow("User ID", userId),
          ],
        ),
      ),
    );
  }

  /// 🔧 Reusable widget to display a labeled, read-only text field
  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        readOnly: true, // Field is not editable by user; for display only
        decoration: InputDecoration(
          labelText: label, // Field label
          hintText: value, // Field value
          border: const OutlineInputBorder(), // Standard border
        ),
      ),
    );
  }
}
