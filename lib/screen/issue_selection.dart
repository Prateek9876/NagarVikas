// Importing necessary Flutter and plugin packages
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../widgets/chatbot_wrapper.dart';
import 'garbage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'water.dart';
import 'road.dart';
import 'new_entry.dart';
import 'street_light.dart';
import 'drainage.dart';
import 'animals.dart';
import 'discussion.dart';
import 'package:animate_do/animate_do.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:nagarvikas/screen/modern_app_drawer.dart'; // Add this import

// Main Stateful Widget for Issue Selection Page
class IssueSelectionPage extends StatefulWidget {
  const IssueSelectionPage({super.key});

  @override
  IssueSelectionPageState createState() => IssueSelectionPageState();
}

class IssueSelectionPageState extends State<IssueSelectionPage> {
  String _language = 'en'; // 'en' for English, 'hi' for Hindi

  // Translation map for all visible strings in this file
  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'title': 'What type of issue are you facing?',
      'garbage': 'No garbage lifting in my area.',
      'water': 'No water supply in my area.',
      'road': 'Road damage in my area.',
      'streetlight': 'Streetlights not working in my area.',
      'animals': 'Stray animals issue in my area.',
      'drainage': 'Blocked drainage in my area.',
      'other': 'Facing any other issue.',
      'processing': 'Processing...\nTaking you to the complaint page',
      'profile': 'Profile',
      'my_complaints': 'My Complaints',
      'user_feedback': 'User Feedback',
      'refer_earn': 'Refer and Earn',
      'facing_issues': 'Facing Issues in App',
      'about': 'About App',
      'contact': 'Contact Us',
      'share_app': 'Share App',
      'logout': 'Logout',
      'logout_title': 'Logout',
      'logout_content': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'yes': 'Yes',
      'follow_us': 'Follow Us On',
      'version': 'Version',
      'get_started': 'Get Started',
      'discussion': 'Discussion Forum',
    },
    'hi': {
      'title': 'आप किस प्रकार की समस्या का सामना कर रहे हैं?',
      'garbage': 'मेरे क्षेत्र में कचरा नहीं उठाया जा रहा है।',
      'water': 'मेरे क्षेत्र में पानी की आपूर्ति नहीं है।',
      'road': 'मेरे क्षेत्र में सड़क क्षतिग्रस्त है।',
      'streetlight': 'मेरे क्षेत्र में स्ट्रीटलाइट काम नहीं कर रही हैं।',
      'animals': 'मेरे क्षेत्र में आवारा जानवरों की समस्या है।',
      'drainage': 'मेरे क्षेत्र में नाली जाम है।',
      'other': 'कोई अन्य समस्या का सामना कर रहे हैं।',
      'processing': 'प्रोसेसिंग...\nआपको शिकायत पृष्ठ पर ले जाया जा रहा है',
      'profile': 'प्रोफ़ाइल',
      'my_complaints': 'मेरी शिकायतें',
      'user_feedback': 'उपयोगकर्ता प्रतिक्रिया',
      'refer_earn': 'रेफर और कमाएँ',
      'facing_issues': 'ऐप में समस्या आ रही है',
      'about': 'ऐप के बारे में',
      'contact': 'संपर्क करें',
      'share_app': 'ऐप साझा करें',
      'logout': 'लॉगआउट',
      'logout_title': 'लॉगआउट',
      'logout_content': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'yes': 'हाँ',
      'follow_us': 'हमें फॉलो करें',
      'version': 'संस्करण',
      'get_started': 'शुरू करें',
      'discussion': 'चर्चा मंच',
    },
  };

  String t(String key) => _localizedStrings[_language]![key] ?? key;

  @override
  void initState() {
    super.initState();

    // Add OneSignal trigger for in-app messages
    OneSignal.InAppMessages.addTrigger("welcoming_you", "available");

    // Save FCM Token to Firebase if user is logged in, and request notification permission if not already granted.
    getTokenAndSave();
    requestNotificationPermission();

    _showTermsAndConditionsDialogIfNeeded();
  }

  void _showTermsAndConditionsDialogIfNeeded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasAccepted = prefs.getBool('hasAcceptedTerms') ?? false;

    if (!hasAccepted) {
      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return AlertDialog(
                  backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                  title: Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "By using this app, you agree to the following terms:\n",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          "• Report issues truthfully and accurately.",
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          "• Consent to receive notifications from the app.",
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          "• Do not misuse the platform for false complaints.",
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          "• Data may be used to improve services.",
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "If you agree, tap **Accept** to proceed.",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Decline"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.isDarkMode ? Colors.teal : Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await prefs.setBool('hasAcceptedTerms', true);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text("Accept"),
                    ),
                  ],
                );
              },
            );
          },
        );
      }
    }
  }

  // Requesting Firebase Messaging notification permissions
  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Show toast only once
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasShownToast = prefs.getBool('hasShownToast') ?? false;

      if (!hasShownToast) {
        Fluttertoast.showToast(msg: "Notifications Enabled");
        await prefs.setBool('hasShownToast', true);
      }
    } else {
      // Request notification permissions if not already granted
      NotificationSettings newSettings = await messaging.requestPermission();
      if (newSettings.authorizationStatus == AuthorizationStatus.authorized) {
        Fluttertoast.showToast(msg: "Notifications Enabled");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasShownToast', true);
      }
    }
  }

  // Get and save FCM token to Firebase Realtime Database
  Future<void> getTokenAndSave() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log("User not logged in.");
      return;
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

    log("FCM Token: $token");

    DatabaseReference userRef =
        FirebaseDatabase.instance.ref("users/${user.uid}/fcmToken");

    DatabaseEvent event = await userRef.once();
    String? existingToken = event.snapshot.value as String?;

    // Save the token only if it's different
    if (existingToken == null || existingToken != token) {
      await userRef.set(token).then((_) {
        log("FCM Token saved successfully.");
      }).catchError((error) {
        log("Error saving FCM token: $error");
      });
    } else {
      log("Token already exists, no need to update.");
    }
  }

  // Building the main issue selection grid with animated cards
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : const Color.fromARGB(255, 253, 253, 253),
          drawer: ModernAppDrawer(
            language: _language,
            onLanguageChanged: (lang) {
              setState(() {
                _language = lang;
              });
            },
            t: t,
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            iconTheme: IconThemeData(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
            title: FadeInDown(
              duration: Duration(milliseconds: 1000),
              child: Text(
                t('Select the nuisance you wish to vanish 🪄'),
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
          body: ChatbotWrapper(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: [
                        ZoomIn(
                            delay: Duration(milliseconds: 200),
                            child: buildIssueCard(context, t('garbage'),
                                "assets/garbage.png", const GarbagePage(), themeProvider)),
                        ZoomIn(
                            delay: Duration(milliseconds: 400),
                            child: buildIssueCard(context, t('water'),
                                "assets/water.png", const WaterPage(), themeProvider)),
                        ZoomIn(
                            delay: Duration(milliseconds: 600),
                            child: buildIssueCard(context, t('road'),
                                "assets/road.png", const RoadPage(), themeProvider)),
                        ZoomIn(
                            delay: Duration(milliseconds: 800),
                            child: buildIssueCard(context, t('streetlight'),
                                "assets/streetlight.png", const StreetLightPage(), themeProvider)),
                        ZoomIn(
                            delay: Duration(milliseconds: 1000),
                            child: buildIssueCard(context, t('animals'),
                                "assets/animals.png", const AnimalsPage(), themeProvider)),
                        ZoomIn(
                            delay: Duration(milliseconds: 1200),
                            child: buildIssueCard(context, t('drainage'),
                                "assets/drainage.png", const DrainagePage(), themeProvider)),
                        ZoomIn(
                            delay: Duration(milliseconds: 1400),
                            child: buildIssueCard(context, t('other'),
                                "assets/newentry.png", const NewEntryPage(), themeProvider)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: themeProvider.isDarkMode ? Colors.teal : const Color.fromARGB(255, 7, 7, 7),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiscussionForum()),
              );
            },
            child: const Icon(Icons.forum, color: Colors.white),
          ),
        );
      },
    );
  }

  /// Builds a reusable issue card with an image and label, which navigates to the corresponding issue page on tap.
  Widget buildIssueCard(
      BuildContext context, String text, String imagePath, Widget page, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () => showProcessingDialog(context, page, themeProvider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black26
                  : Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showProcessingDialog(BuildContext context, Widget nextPage, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  t('Calling... \nThe Ministry of Magic 🔮'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => nextPage));
    });
  }
}
