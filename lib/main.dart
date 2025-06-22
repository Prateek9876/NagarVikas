// 📦 Importing necessary packages and screens
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nagar_vikas/screen/register_screen.dart';
import 'package:nagar_vikas/screen/issue_selection.dart';
import 'package:nagar_vikas/screen/admin_dashboard.dart';
import 'package:nagar_vikas/screen/login_page.dart' as login;
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';

// 🔧 Background message handler for Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log("Handling a background message: ${message.messageId}");
}

void main() async {
  // ✅ Ensures Flutter is initialized before any Firebase code
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ OneSignal push notification setup
  OneSignal.initialize("70614e6d-8bbf-4ac1-8f6d-b261a128059c");
  OneSignal.Notifications.requestPermission(true);

  // ✅ Set up notification opened handler
  OneSignal.Notifications.addClickListener((event) {
    developer.log("Notification Clicked: ${event.notification.body}");
  });

  // ✅ Firebase initialization for Web and Mobile
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCjaGsLVhHmVGva75FLj6PiCv_Z74wGap4",
        authDomain: "nagarvikas-a1d4f.firebaseapp.com",
        projectId: "nagarvikas-a1d4f",
        storageBucket: "nagarvikas-a1d4f.firebasestorage.app",
        messagingSenderId: "847955234719",
        appId: "1:847955234719:web:ac2b6da7a3a0715adfb7aa",
        measurementId: "G-ZZMV642TW3",
      ),
    );
  } else {
    await Firebase.initializeApp(); // This might fail if no default options
  }
  // ✅ Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Run the app
  runApp(const MyApp());
}

// ✅ Main Application Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NagarVikas',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

// ✅ Auth Check Screen (Decides User/Admin Navigation)
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  AuthCheckScreenState createState() => AuthCheckScreenState();
}

// ✅ State for Auth Check Screen - Made public
class AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _showSplash = true;
  firebase_auth.User? user;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkLastLogin();

    // ✅ Listen for authentication state changes like(login/logout changes)
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? newUser) {
      if (mounted) {
        setState(() {
          user = newUser;
        });
      }
    });

    // ✅ Splash screen timer
    Timer(const Duration(seconds: 9), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  // ✅ Check Last Login (Fix for User Going to Admin Dashboard)
  Future<void> _checkLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool? storedIsAdmin = prefs.getBool('isAdmin');

    if (storedIsAdmin != null && mounted) {
      setState(() {
        isAdmin = storedIsAdmin;
      });
    }
  }

  // ✅ Build Method (Decides Which Screen to Show)
  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    // ✅ Redirect Based on Last Login
    if (user == null) {
      return const WelcomeScreen();
    } else {
      // ✅ Admin should only go to AdminDashboard IF they were last logged in as Admin
      if (isAdmin && user!.email!.contains("gov")) {
        return AdminDashboard();
      } else {
        return const IssueSelectionPage();
      }
    }
  }
}

// ✅ Admin Login Function (Stores Admin Status)
Future<void> handleAdminLogin(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isAdmin', true);
  
  // Check if context is still valid before navigation
  if (context.mounted) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => AdminDashboard()));
  }
}

// ✅ Logout Function (Clears Admin Status & Redirects to Login)
Future<void> handleLogout(BuildContext context) async {
  // Clear stored admin status
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isAdmin'); // ✅ Clear admin status 
  await firebase_auth.FirebaseAuth.instance.signOut(); 
  
  // Check if context is still valid before navigation
  if (context.mounted) {
    Navigator.pushReplacement( // ✅ Redirect to Login Page
        context, MaterialPageRoute(builder: (context) => const login.LoginPage())); // ✅ Fix: Use prefixed LoginPage to avoid conflicts
  }
}

/// SplashScreen - displays an animated logo on app launch
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override // Build Method for Splash Screen
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 252, 252, 252),
      body: Center(
        child: _LogoWidget(), // ✅ Fixed: Using local LogoWidget definition
      ),
    );
  }
}

/// Local LogoWidget - Simple logo display for splash screen
class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // App Logo or Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(60),
          ),
          child: const Icon(
            Icons.location_city,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        // App Name
        const Text(
          'NagarVikas',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        // Tagline
        const Text(
          'Civic Issues Made Easy',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ✅ Welcome Screen shown before registration
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override 
  WelcomeScreenState createState() => WelcomeScreenState();
}

// ✅ Made WelcomeScreenState public
class WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  void _onGetStartedPressed() {
    setState(() {
      _isLoading = true;
    });
    // ✅ Simulate a delay for loading effect
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      }
    });
  }

  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 253, 253),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Top Circle Animation
            Align(
              alignment: Alignment.topLeft,
              child: ZoomIn(
                duration: const Duration(milliseconds: 1200),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 133, 207, 239),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ✅ Main Image Animation
            ZoomIn(
              duration: const Duration(milliseconds: 1200),
              child: Image.asset(
                'assets/mobileprofile.png',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // ✅ Headline & Subtext
            FadeInUp(
              duration: const Duration(milliseconds: 1200),
              child: const Column(
                children: [
                  Text(
                    "Facing Civic Issues?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(
                      height: 10), // Space between heading and subtext
                  Text(
                    "Register your complaint now and\nget it done in few time.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),

            // ✅ Get Started Button
            FadeInUp( // Animation for button
              duration: const Duration(milliseconds: 1600),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onGetStartedPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 8, 8, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 90, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ), // ✅ Button style
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Get Started",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}