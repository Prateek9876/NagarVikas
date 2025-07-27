import 'package:nagarvikas/localization/app_localizations.dart';
import 'package:nagarvikas/main.dart';
import 'package:nagarvikas/screen/about.dart';
import 'package:nagarvikas/screen/contact.dart';
import 'package:nagarvikas/screen/facing_issues.dart';
import 'package:nagarvikas/screen/login_page.dart';
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
import 'package:nagarvikas/screen/fun_game_screen.dart';
import 'dart:developer';

// Main Stateful Widget for Issue Selection Page
class IssueSelectionPage extends StatefulWidget {
  const IssueSelectionPage({super.key});

  @override
  State<IssueSelectionPage> createState() => _IssueSelectionPageState();
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
                children: [
                  Text(
                    AppLocalizations.of(context).get("termsAndConditions"),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(AppLocalizations.of(context).get("reportTruthfully")),
                  Text(
                      AppLocalizations.of(context).get("consentNotifications")),
                  Text(AppLocalizations.of(context).get("noMisusePlatform")),
                  Text(AppLocalizations.of(context)
                      .get("dataUsedImproveServices")),
                  SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context).get("agreeTapAccept"),
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 253, 253),
      drawer: AppDrawer(
        language: AppLocalizations.of(context).locale.languageCode,
        onLanguageChanged: (lang) {
          setState(() {
            MyApp.setLocale(context, Locale(lang));
          });
        },
        t: AppLocalizations.of(context).get,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
          duration: Duration(milliseconds: 1000),
          child: Text(
            AppLocalizations.of(context).get('selectNuisance') ??
                'Select Nuisance',
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
                      child: buildIssueCard(
                          context,
                          AppLocalizations.of(context).get('garbage'),
                          "assets/garbage.png",
                          const GarbagePage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 400),
                      child: buildIssueCard(
                          context,
                          AppLocalizations.of(context).get('water'),
                          "assets/water.png",
                          const WaterPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 600),
                      child: buildIssueCard(
                          context,
                          AppLocalizations.of(context).get('road'),
                          "assets/road.png",
                          const RoadPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 800),
                      child: buildIssueCard(
                          context,
                          AppLocalizations.of(context).get('streetLights'),
                          "assets/streetlight.png",
                          const StreetLightPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1000),
                      child: buildIssueCard(
                          context,
                          AppLocalizations.of(context).get('animals'),
                          "assets/animals.png",
                          const AnimalsPage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1200),
                      child: buildIssueCard(
                          context,
                          AppLocalizations.of(context).get('drainage'),
                          "assets/drainage.png",
                          const DrainagePage())),
                  ZoomIn(
                      delay: Duration(milliseconds: 1400),
                      child: buildIssueCard(
                          context,
                          AppLocalizations.of(context).get('other'),
                          "assets/newentry.png",
                          const NewEntryPage())),
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
                color: Colors.black.withAlpha((0.1 * 255).toInt()),
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
                  AppLocalizations.of(context).get('callingMinistry'),
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
      if (!context.mounted) return; // Check if the widget is still mounted
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

  @override
  AppDrawerState createState() => AppDrawerState();
}

class AppDrawerState extends State<AppDrawer> {
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
              DrawerHeader(
                decoration:
                    BoxDecoration(color: Color.fromARGB(255, 4, 204, 240)),
                child: Text(widget.t('appTitle') ?? "NagarVikas",
                    style: TextStyle(fontSize: 24, color: Colors.black)),
              ),
              // Language Switcher
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.language, color: Colors.black),
                    SizedBox(width: 8),
                    Text("Language:",
                        style: TextStyle(fontSize: 15, color: Colors.black)),
                    SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text('English',
                                  style: TextStyle(fontSize: 13)),
                              selected: widget.language == 'en',
                              onSelected: (selected) {
                                if (selected) widget.onLanguageChanged('en');
                              },
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              visualDensity: VisualDensity.compact,
                            ),
                            SizedBox(width: 6),
                            ChoiceChip(
                              label: Text('हिन्दी',
                                  style: TextStyle(fontSize: 13)),
                              selected: widget.language == 'hi',
                              onSelected: (selected) {
                                if (selected) widget.onLanguageChanged('hi');
                              },
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Drawer Items (localized)
              buildDrawerItem(
                  context, Icons.person, widget.t('profile'), ProfilePage()),
              buildDrawerItem(context, Icons.history, widget.t('spellRecords'),
                  MyComplaintsScreen()),
              buildDrawerItem(context, Icons.favorite,
                  widget.t('userfeedback'), FeedbackPage()),
              buildDrawerItem(context, Icons.card_giftcard,
                  widget.t('referearn'), ReferAndEarnPage()),
              buildDrawerItem(context, Icons.report_problem,
                  widget.t('facingissues'), FacingIssuesPage()),
              buildDrawerItem(
                  context, Icons.info, widget.t('about'), AboutAppPage()),
              buildDrawerItem(context, Icons.headset_mic, widget.t('contact'),
                  ContactUsPage()),
              buildDrawerItem(
                context,
                Icons.share,
                widget.t('shareapp'),
                null,
                onTap: () {
                  // Share.share(
                  //   'Check out this app: https://github.com/Prateek9876/nagarvikas',
                  //   subject: 'NagarVikas App',
                  // ); // Deprecated
                  SharePlus.instance.share(ShareParams(
                    text:
                        'Check out this app: https://github.com/Prateek9876/nagarvikas',
                    subject: 'NagarVikas App',
                  ));
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
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginPage()));
                            }
                          },
                          child: Text(widget.t('yes')),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 15),
                child: Text(
                  widget.t('followus'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
      splashColor:
          Colors.blue.withAlpha((0.5 * 255).toInt()), // Ripple effect color
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
