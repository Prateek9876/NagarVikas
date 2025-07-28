// Importing necessary Flutter and plugin packages
import 'package:NagarVikas/screen/about.dart';
import 'package:NagarVikas/screen/contact.dart';
import 'package:NagarVikas/screen/facing_issues.dart';
import 'package:NagarVikas/screen/login_page.dart';
import 'package:flutter/material.dart';
import 'package:NagarVikas/widgets/chatbot_wrapper.dart';
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
import 'package:NagarVikas/screen/fun_game_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Main Stateful Widget for Issue Selection Page
class IssueSelectionPage extends StatefulWidget {
  const IssueSelectionPage({super.key});

  @override
  _IssueSelectionPageState createState() => _IssueSelectionPageState();
}

class _IssueSelectionPageState extends State<IssueSelectionPage> {
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              "Terms & Conditions",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "By using this app, you agree to the following terms:\n",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text("• Report issues truthfully and accurately."),
                  Text("• Consent to receive notifications from the app."),
                  Text("• Do not misuse the platform for false complaints."),
                  Text("• Data may be used to improve services."),
                  SizedBox(height: 10),
                  Text(
                    "If you agree, tap **Accept** to proceed.",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Decline"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await prefs.setBool('hasAcceptedTerms', true);
                  Navigator.of(context).pop();
                },
                child: const Text("Accept"),
              ),
            ],
          );
        },
      );
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
      print("User not logged in.");
      return;
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();

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
    return ChatbotWrapper(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 253, 253, 253),
        drawer: AppDrawer(
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
        title: FadeInDown(
          duration: Duration(milliseconds: 1000),
          child: Text(
            t('Select the nuisance you wish to vanish 🪄'),
            style: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900),
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
                      child: buildIssueCard(context, t('garbage'),
                          "assets/garbage.png", const GarbagePage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 400),
                      child: buildIssueCard(context, t('water'),
                          "assets/water.png", const WaterPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 600),
                      child: buildIssueCard(context, t('road'),
                          "assets/road.png", const RoadPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 800),
                      child: buildIssueCard(context, t('streetlight'),
                          "assets/streetlight.png", const StreetLightPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1000),
                      child: buildIssueCard(context, t('animals'),
                          "assets/animals.png", const AnimalsPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1200),
                      child: buildIssueCard(context, t('drainage'),
                          "assets/drainage.png", const DrainagePage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1400),
                      child: buildIssueCard(context, t('other'),
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

  void showProcessingDialog(BuildContext context, Widget nextPage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        );
      },
    );


    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => nextPage));
    });
  }
}

// App Drawer for navigation and profile settings
class AppDrawer extends StatefulWidget {
  final String language;
  final void Function(String) onLanguageChanged;
  final String Function(String) t;
  const AppDrawer(
      {super.key,
      required this.language,
      required this.onLanguageChanged,
      required this.t});
//sidebar enhanced
  @override
  _AppDrawerState createState() => _AppDrawerState();
}
// work done

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: ListView(children: [
                // App title with icon and "Made with ❤️ by Prateek Chourasia"
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE0F7FA),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/app_icon.png',
                            width: 38,
                            height: 38,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "NagarVikas",
                            style: TextStyle(
                              fontSize: 26,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Made with ❤️ by Prateek Chourasia',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Language Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.language, color: Colors.black87),
                      SizedBox(width: 8),
                      Text("Language:", style: TextStyle(fontSize: 15, color: Colors.black87)),
                      SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text('English', style: TextStyle(fontSize: 13)),
                                selected: widget.language == 'en',
                                onSelected: (selected) {
                                  if (selected) widget.onLanguageChanged('en');
                                },
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                visualDensity: VisualDensity.compact,
                                selectedColor: Color(0xFFE0F7FA),
                                backgroundColor: Color(0xFFF5F5F5),
                                labelStyle: TextStyle(color: widget.language == 'en' ? Colors.teal : Colors.black87),
                              ),
                              SizedBox(width: 6),
                              ChoiceChip(
                                label: Text('हिन्दी', style: TextStyle(fontSize: 13)),
                                selected: widget.language == 'hi',
                                onSelected: (selected) {
                                  if (selected) widget.onLanguageChanged('hi');
                                },
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                visualDensity: VisualDensity.compact,
                                selectedColor: Color(0xFFE0F7FA),
                                backgroundColor: Color(0xFFF5F5F5),
                                labelStyle: TextStyle(color: widget.language == 'hi' ? Colors.teal : Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Drawer Items (localized)
                ...[
                  buildDrawerItem(
                    context, Icons.person, widget.t('profile'), ProfilePage()),
                  buildDrawerItem(context, Icons.history, widget.t('Spell Records'), MyComplaintsScreen()),
                  buildDrawerItem(context, Icons.favorite, widget.t('user_feedback'), FeedbackPage()),
                  buildDrawerItem(context, Icons.card_giftcard, widget.t('refer_earn'), ReferAndEarnPage()),
                  buildDrawerItem(context, Icons.report_problem, widget.t('facing_issues'), FacingIssuesPage()),
                  buildDrawerItem(context, Icons.info, widget.t('about'), AboutAppPage()),
                  buildDrawerItem(context, Icons.headset_mic, widget.t('contact'), ContactUsPage()),
                  buildDrawerItem(
                    context,
                    Icons.share,
                    widget.t('share_app'),
                    null,
                    onTap: () {
                      Share.share(
                        'Check out this app: https://github.com/Prateek9876/NagarVikas',
                        subject: 'NagarVikas App',
                      );
                    },
                  ),
                  buildDrawerItem(
                    context,
                    Icons.games,
                    '2048 Game',
                    null,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FunGameScreen()));
                    },
                  ),
                  buildDrawerItem(
                    context,
                    Icons.logout,
                    widget.t('logout'),
                    null,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(widget.t('logout_title')),
                          content: Text(widget.t('logout_content')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(widget.t('cancel')),
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
                              child: Text(widget.t('yes')),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ].map((item) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: item,
                )).toList(),
                const Divider(color: Color(0xFFE0F7FA), thickness: 1),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 15),
                  child: Text(
                    widget.t('follow_us'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialMediaIcon(FontAwesomeIcons.facebook, "https://facebook.com", Color(0xFF1877F2)),
                    _socialMediaIcon(FontAwesomeIcons.instagram, "https://instagram.com", Color(0xFFC13584)),
                    _socialMediaIcon(FontAwesomeIcons.youtube, "https://youtube.com", Color(0xFFFF0000)),
                    _socialMediaIcon(FontAwesomeIcons.twitter, "https://twitter.com", Color(0xFF1DA1F2)),
                    _socialMediaIcon(FontAwesomeIcons.linkedin, "https://linkedin.com/in/prateek-chourasia-in", Color(0xFF0A66C2)),
                  ],
                ),
                Divider(color: Color(0xFFE0F7FA), thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: [
                      Text(
                        " 2025 NextGen Soft Labs and Prateek.\nAll Rights Reserved.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      Text(
                        "${widget.t('version')} $_appVersion",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
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
  BuildContext context, IconData icon, String title, Widget? page,
  {VoidCallback? onTap}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap ??
          (page != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => page),
                  );
                }
              : null),
      splashColor: Colors.blue.withOpacity(0.5), // Ripple effect color
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              width: 28, // or whatever width fits your icons best
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(icon, color: Colors.black),
              ),
            ),
            SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.black)),
          ],
        ),
      ),
    ),
  );
}
