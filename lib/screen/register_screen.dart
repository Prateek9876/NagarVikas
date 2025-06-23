/// RegisterScreen
/// A stateful widget that handles new user registration using Firebase Authentication.
/// Includes:
/// - Email/password input
/// - Password validation
/// - Email verification
/// - Guest login
/// - Firebase Realtime Database integration
library;


// import necessary Flutter and Firebase packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:NagarVikas/screen/login_page.dart';
import 'package:NagarVikas/screen/issue_selection.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Register screen widget
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Firebase authentication and realtime database reference
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("users");

  // Text field controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Flags for loading and password validation
  bool isLoading = false;
  bool hasUppercase = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;

  // ✅ Real-time password validation logic
  void _validatePassword(String password) {
    setState(() {
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      hasMinLength = password.length >= 8;
    });
  }

  // ✅ Handles user registration process
  Future<void> _registerUser() async {
    String password = _passwordController.text.trim();

    // Check if password meets criteria
    if (!hasMinLength || !hasUppercase || !hasSpecialChar) {
      Fluttertoast.showToast(msg: "Password does not meet the required criteria.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ✅ Create user using Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: password,
      );

      // ✅ Send email verification
      await userCredential.user!.sendEmailVerification();

      // ✅ Save user details in Firebase Realtime Database
      await _dbRef.child(userCredential.user!.uid).set({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
      });

      Fluttertoast.showToast(msg: "Registration successful! Please verify your email before logging in.");
      
      await _auth.signOut(); // Sign out the user after registration
      await Future.delayed(Duration(seconds: 2));

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle various Firebase auth errors
      String errorMessage = "An error occurred. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "Email already registered. Please log in.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email address. Please enter a valid email.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password is too weak. Try a stronger password.";
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = "Email/password accounts are disabled.";
      }

      Fluttertoast.showToast(msg: errorMessage);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Signs in the user anonymously and navigates to the issue selection screen.
  Future<void> _continueAsGuest() async {
    try {
      await _auth.signInAnonymously();
      Fluttertoast.showToast(msg: "Signed in as Guest");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IssueSelectionPage()),
      );
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  /// Builds the registration UI with animation, input fields, 
  /// and buttons for registration and guest login.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),

              // Screen Title with Animation
              FadeInUp(
                duration: Duration(milliseconds: 800),
                child: Text(
                  "Create Account",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 20),

              // Registration Illustration
              ZoomIn(
                duration: Duration(milliseconds: 800),
                child: Image.asset("assets/register.png", height: 200),
              ),

              SizedBox(height: 20),

              // Name Input Field
              FadeInUp(
                duration: Duration(milliseconds: 1000),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Enter your name",
                    labelStyle: TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),

              // Email Field
              FadeInUp(
                duration: Duration(milliseconds: 1200),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Enter your email",
                    labelStyle: TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 15),

              // Password Field with Real-time Validation
              FadeInUp(
                duration: Duration(milliseconds: 1400),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: _validatePassword,
                  decoration: InputDecoration(
                    labelText: "Enter your password",
                    labelStyle: TextStyle(color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
              ),


              SizedBox(height: 12),

              // Password Requirements List
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ZoomIn(duration: Duration(milliseconds: 800),
                  child: buildPasswordValidationItem("At least 8 characters",hasMinLength),
                  ),
                   ZoomIn(duration: Duration(milliseconds: 800),
                  child: buildPasswordValidationItem("At least 1 uppercase letter",hasUppercase),
                  ),
                   ZoomIn(duration: Duration(milliseconds: 800),
                  child: buildPasswordValidationItem("At least 1 special character",hasSpecialChar),
                  ),
                ],
),

              SizedBox(height: 37),

              // Register Button
              FadeInUp(
                duration: Duration(milliseconds: 1800),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading ? null : _registerUser,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              SizedBox(height: 15),

              // Continue as Guest Button
              FadeInUp(
                duration: Duration(milliseconds: 2000),
                child: OutlinedButton.icon(
                  onPressed: _continueAsGuest,
                  icon: Image.asset("assets/anonymous.png", height: 24),
                  label: Text("Continue as Guest", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    side: BorderSide(color: Colors.black, width: 2),
                    backgroundColor: Colors.white,
                  ),
                ),
),

              SizedBox(height: 10),

              // Redirect to Login Page if account exists
              FadeInUp(
                duration: Duration(milliseconds: 2200),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                  },
                  child: Text("Already have an account? Log in", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build password requirement item
  Widget buildPasswordValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(isValid ? Icons.check_circle : Icons.cancel, color: isValid ? Colors.green : Colors.red, size: 18),
        SizedBox(width: 8),
        Text(text, style: TextStyle(color: isValid ? Colors.green : Colors.red)),
],
);
}
}
