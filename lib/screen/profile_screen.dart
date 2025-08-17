import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

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
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: Text(
            "Profile",
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[850]
              : const Color.fromARGB(255, 4, 204, 240),
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 👤 User avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: themeProvider.isDarkMode
                    ? Colors.grey[700]
                    : const Color.fromARGB(255, 3, 3, 3),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
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
    });
  }

  /// 🔧 Reusable widget to display a labeled, read-only text field
  Widget _buildProfileRow(String label, String value) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: TextField(
          readOnly: true, // Field is not editable by user; for display only
          decoration: InputDecoration(
            labelText: label,
            hintText: value,
            border: const OutlineInputBorder(),
            labelStyle: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
            hintStyle: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey,
              ),
            ),
          ),
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      );
    });
  }
}
