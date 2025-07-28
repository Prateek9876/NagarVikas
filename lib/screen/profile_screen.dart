import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'change_password.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Loading...";
  String email = "Loading...";
  String userId = "Loading...";
  String? profileImageUrl;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(user.uid);

      final snapshot = await userRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
        setState(() {
          name = data?['name'] ?? "N/A";
          email = user.email ?? "N/A";
          userId = user.uid;
          profileImageUrl = data?['profileImage'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}.jpg');

        await storageRef.putFile(imageFile);
        final url = await storageRef.getDownloadURL();

        await FirebaseDatabase.instance
            .ref()
            .child('users')
            .child(user.uid)
            .update({'profileImage': url});

        setState(() {
          profileImageUrl = url;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile photo updated")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF4DD0E1),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: 2,
                color: Colors.black12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {},
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Change Photo',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel("Full Name"),
              _buildReadOnlyField(name),
              const SizedBox(height: 15),
              _buildLabel("Email"),
              _buildReadOnlyField(email),
              const SizedBox(height: 15),
              _buildLabel("User ID"),
              _buildReadOnlyField(userId),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Change Password",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
      ),
    );
  }
}
