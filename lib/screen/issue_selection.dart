// Importing necessary Flutter and plugin packages
import 'package:NagarVikas/screen/about.dart';
import 'package:NagarVikas/screen/contact.dart';
import 'package:NagarVikas/screen/facing_issues.dart';
import 'package:NagarVikas/screen/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'garbage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'water.dart';
import 'road.dart';
import 'new_entry.dart';
import 'street_light.dart';
import 'drainage.dart';
import 'animals.dart';
import 'my_complaints.dart';
import 'profile_screen.dart';
import 'feedback.dart';
import 'referearn.dart';
import 'discussion.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:share_plus/share_plus.dart';

// Main Stateful Widget for Issue Selection Page
class IssueSelectionPage extends StatefulWidget {
  const IssueSelectionPage({super.key});

  @override
  _IssueSelectionPageState createState() => _IssueSelectionPageState();
}

class _IssueSelectionPageState extends State<IssueSelectionPage> {
  @override
  void initState() {
    super.initState();

    // Add OneSignal trigger for in-app messages
    OneSignal.InAppMessages.addTrigger("welcoming_you", "available");

    // Save FCM Token to Firebase if user is logged in, and request notification permission if not already granted.
    getTokenAndSave();
    requestNotificationPermission();
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
      print("User not logged in.");
      return;
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    if (token == null) {
      print("Failed to get FCM token.");
      return;
    }

    print("FCM Token: $token");

    DatabaseReference userRef =
        FirebaseDatabase.instance.ref("users/${user.uid}/fcmToken");

    DatabaseEvent event = await userRef.once();
    String? existingToken = event.snapshot.value as String?;

    // Save the token only if it's different
    if (existingToken == null || existingToken != token) {
      await userRef.set(token).then((_) {
        print("FCM Token saved successfully.");
      }).catchError((error) {
        print("Error saving FCM token: $error");
      });
    } else {
      print("Token already exists, no need to update.");
    }
  }

  // Building the main issue selection grid with animated cards
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 253, 253),
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
          duration: Duration(milliseconds: 1000),
          child: const Text(
            "What type of issue are you facing?",
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
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
                  // Each issue card has a ZoomIn animation for better user experience and smooth UI.
                  ZoomIn(
                      delay: Duration(milliseconds: 200),
                      child: buildIssueCard(
                          context,
                          "No garbage lifting in my area.",
                          "assets/garbage.png",
                          const GarbagePage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 400),
                      child: buildIssueCard(
                          context,
                          "No water supply in my area.",
                          "assets/water.png",
                          const WaterPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 600),
                      child: buildIssueCard(context, "Road damage in my area.",
                          "assets/road.png", const RoadPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 800),
                      child: buildIssueCard(
                          context,
                          "Streetlights not working in my area.",
                          "assets/streetlight.png",
                          const StreetLightPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1000),
                      child: buildIssueCard(
                          context,
                          "Stray animals issue in my area.",
                          "assets/animals.png",
                          const AnimalsPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1200),
                      child: buildIssueCard(
                          context,
                          "Blocked drainage in my area.",
                          "assets/drainage.png",
                          const DrainagePage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1400),
                      child: buildIssueCard(context, "Facing any other issue.",
                          "assets/newentry.png", const NewEntryPage())),
                ],
              ),
            ),
          ],
        ),
      ),
      // Floating Action Button to navigate to the Discussion Forum screen.
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 7, 7, 7),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DiscussionForum()),
          );
        },
        child: const Icon(Icons.forum, color: Colors.white),
      ),
    );
  }

  /// Builds a reusable issue card with an image and label, which navigates to the corresponding issue page on tap.
  Widget buildIssueCard(
      BuildContext context, String text, String imagePath, Widget page) {
    return GestureDetector(
      onTap: () => showProcessingDialog(context, page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2)
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
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shows a processing dialog before navigating to the issue detail page
void showProcessingDialog(BuildContext context, Widget nextPage) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
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
              const Text(
                "Processing...\nTaking you to the complaint page",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      );
    },
  );

  // After 2 seconds, close the dialog and navigate
  Future.delayed(const Duration(seconds: 2), () {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  });
}

// App Drawer for navigation and profile settings
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _appVersion = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

// Load app version using package_info_plus
  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(children: [
              // App title
              const DrawerHeader(
                decoration:
                    BoxDecoration(color: Color.fromARGB(255, 4, 204, 240)),
                child: Text("NagarVikas",
                    style: TextStyle(fontSize: 24, color: Colors.black)),
              ),
              // Drawer Items
              buildDrawerItem(context, Icons.person, "Profile", ProfilePage()),
              buildDrawerItem(context, Icons.history, "My Complaints",
                  MyComplaintsScreen()),
              buildDrawerItem(
                  context, Icons.favorite, "User Feedback", FeedbackPage()),
              buildDrawerItem(context, Icons.card_giftcard, "Refer and Earn",
                  ReferAndEarnPage()),
              buildDrawerItem(context, Icons.report_problem,
                  "Facing Issues in App", FacingIssuesPage()),
              buildDrawerItem(context, Icons.info, "About App", AboutAppPage()),
              buildDrawerItem(
                  context, Icons.headset_mic, "Contact Us", ContactUsPage()),
              //Share App
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share App'),
                onTap: () {
                  Share.share(
                    'Check out this app: https://github.com/Prateek9876/NagarVikas',
                    subject: 'NagarVikas App',
                  );
                },
              ),

              // Logout Option
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final FirebaseAuth auth = FirebaseAuth.instance;
                            await auth.signOut();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginPage()));
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const Divider(),

              // Social media section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 15),
                child: Text(
                  "Follow Us On",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              // Social Media Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialMediaIcon(FontAwesomeIcons.facebook,
                      "https://facebook.com", Color(0xFF1877F2)),
                  _socialMediaIcon(FontAwesomeIcons.instagram,
                      "https://instagram.com", Color(0xFFC13584)),
                  _socialMediaIcon(FontAwesomeIcons.youtube,
                      "https://youtube.com", Color(0xFFFF0000)),
                  _socialMediaIcon(FontAwesomeIcons.twitter,
                      "https://twitter.com", Color(0xFF1DA1F2)),
                  _socialMediaIcon(
                      FontAwesomeIcons.linkedin,
                      "https://linkedin.com/in/prateek-chourasia-in",
                      Color(0xFF0A66C2)),
                ],
              ),
              const SizedBox(height: 20),

              Divider(), // Divider before the footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  children: [
                    Text(
                      "© 2025 NextGen Soft Labs and Prateek.\nAll Rights Reserved.",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Version $_appVersion",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Reusable method for social media icon buttons
  Widget _socialMediaIcon(IconData icon, String url, Color color) {
    return IconButton(
      icon: FaIcon(icon, color: color, size: 35),
      onPressed: () {
        launchUrl(Uri.parse(url));
      },
    );
  }
}

// Reusable widget to build drawer items
Widget buildDrawerItem(
    BuildContext context, IconData icon, String title, Widget page) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => page)),
      splashColor: Colors.blue.withOpacity(0.5), // Ripple effect color
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.black)),
          ],
        ),
      ),
    ),
  );
}
