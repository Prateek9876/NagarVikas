// 📦 Importing necessary packages and screens
import 'package:NagarVikas/service/ConnectivityService.dart';
import 'package:NagarVikas/widgets/bottom_nav_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:NagarVikas/screen/register_screen.dart';
import 'package:NagarVikas/screen/issue_selection.dart';
import 'package:NagarVikas/screen/admin_dashboard.dart';
import 'package:NagarVikas/screen/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:NagarVikas/screen/logo.dart';
import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:NagarVikas/theme/theme_provider.dart';

// 🔧 Background message handler for Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  // ✅ Ensures Flutter is initialized before any Firebase code
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ OneSignal push notification setup
  OneSignal.initialize("70614e6d-8bbf-4ac1-8f6d-b261a128059c");
  OneSignal.Notifications.requestPermission(true);

  // ✅ Set up notification opened handler
  OneSignal.Notifications.addClickListener((event) {
    print("Notification Clicked: ${event.notification.body}");
  });

  // ✅ Firebase initialization for Web and Mobile
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
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
  await ConnectivityService().initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// ✅ Main Application Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NagarVikas',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: ConnectivityOverlay(child: const AuthCheckScreen()),
    );
  }
}

// ✅ Auth Check Screen (Decides User/Admin Navigation)
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

// ✅ State for Auth Check Screen
class _AuthCheckScreenState extends State<AuthCheckScreen> {
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
      setState(() {
        user = newUser;
      });
    });

    // ✅ Splash screen timer
    Timer(const Duration(seconds: 9), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  // ✅ Check Last Login (Fix for User Going to Admin Dashboard)
  Future<void> _checkLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool? storedIsAdmin = prefs.getBool('isAdmin');

    if (storedIsAdmin != null) {
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
      if (isAdmin && user!.email?.contains("gov") == true) {
        return AdminDashboard();
      } else {
        return const BottomNavBar();
      }
    }
  }
}

// ✅ Admin Login Function (Stores Admin Status)
Future<void> handleAdminLogin(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isAdmin', true);
  Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => AdminDashboard()));
}

// ✅ Logout Function (Clears Admin Status & Redirects to Login)
Future<void> handleLogout(BuildContext context) async {
  // Clear stored admin status
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('isAdmin'); // ✅ Clear admin status
  await firebase_auth.FirebaseAuth.instance.signOut();
  Navigator.pushReplacement(
      // ✅ Redirect to Login Page
      context,
      MaterialPageRoute(
          builder: (context) =>
              const LoginPage())); // ✅ Fix: Use const for LoginPage to avoid unnecessary rebuilds
}

/// SplashScreen - displays an animated logo on app launch
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override // Build Method for Splash Screen
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      body: Center(
        child: LogoWidget(),
      ),
    );
  }
}

// ✅ Welcome Screen shown before registration
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  void _onGetStartedPressed() {
    setState(() {
      _isLoading = true;
    });
    // ✅ Simulate a delay for loading effect
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      ).then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 253, 253),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => SwitchListTile(
                title: const Text("Dark Mode"),
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
                secondary: const Icon(Icons.dark_mode),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => handleLogout(context),
            ),
          ],
        ),
      ),
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
              child: Column(
                children: [
                  const Text(
                    "Facing Civic Issues?",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(
                      height: 10), // Space between heading and subtext
                  const Text(
                    "Register your complaint now and\nget it done in few time..",
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
            FadeInUp(
              // Animation for button
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
