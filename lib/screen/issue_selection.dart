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
import 'package:nagarvikas/screen/modern_app_drawer.dart';

// Main Stateful Widget for Issue Selection Page
class IssueSelectionPage extends StatefulWidget {
  const IssueSelectionPage({super.key});

  @override
  IssueSelectionPageState createState() => IssueSelectionPageState();
}

class IssueSelectionPageState extends State<IssueSelectionPage>
    with TickerProviderStateMixin {
  String _language = 'en'; // 'en' for English, 'hi' for Hindi

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  // Translation map for all visible strings in this file
  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'title': 'What type of issue are you facing?',
      'subtitle': 'Select the category that best describes your concern',
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
      'select_issue': 'Select Issue Type',
      'calling_magic': 'Calling the Ministry of Magic 🔮',
      'processing_request': 'Processing your request...',
      'tap_to_report': 'Tap to Report',
      'choose_concern': 'Choose your concern and let\'s resolve it together',
    },
    'hi': {
      'title': 'आप किस प्रकार की समस्या का सामना कर रहे हैं?',
      'subtitle':
          'उस श्रेणी का चयन करें जो आपकी चिंता का सबसे अच्छा वर्णन करती है',
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
      'select_issue': 'समस्या प्रकार चुनें',
      'calling_magic': 'मंत्रालय को कॉल कर रहे हैं 🔮',
      'processing_request': 'आपके अनुरोध को संसाधित कर रहे हैं...',
      'tap_to_report': 'रिपोर्ट करने के लिए टैप करें',
      'choose_concern': 'अपनी चिंता चुनें और आइए इसे एक साथ हल करते हैं',
    },
  };

  String t(String key) => _localizedStrings[_language]![key] ?? key;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Add OneSignal trigger for in-app messages
    OneSignal.InAppMessages.addTrigger("welcoming_you", "available");

    // Save FCM Token to Firebase if user is logged in, and request notification permission if not already granted.
    getTokenAndSave();
    requestNotificationPermission();

    _showTermsAndConditionsDialogIfNeeded();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutBack),
    ));

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    // Start animations with slight delays to prevent stuttering
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _headerAnimationController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _cardAnimationController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
  }

  void _showTermsAndConditionsDialogIfNeeded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasAccepted = prefs.getBool('hasAcceptedTerms') ?? false;

    if (!hasAccepted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return AlertDialog(
                  backgroundColor: themeProvider.isDarkMode
                      ? Colors.grey[850]
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 10,
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: themeProvider.isDarkMode
                            ? Colors.teal[300]
                            : const Color(0xFF1565C0),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Terms & Conditions",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode
                                ? Colors.teal.withOpacity(0.1)
                                : const Color(0xFF1565C0).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeProvider.isDarkMode
                                  ? Colors.teal.withOpacity(0.3)
                                  : const Color(0xFF1565C0).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "By using this app, you agree to the following terms:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTermItem(
                          "Report issues truthfully and accurately.",
                          Icons.fact_check_outlined,
                          themeProvider,
                        ),
                        const SizedBox(height: 8),
                        _buildTermItem(
                          "Consent to receive notifications from the app.",
                          Icons.notifications_outlined,
                          themeProvider,
                        ),
                        const SizedBox(height: 8),
                        _buildTermItem(
                          "Do not misuse the platform for false complaints.",
                          Icons.block_outlined,
                          themeProvider,
                        ),
                        const SizedBox(height: 8),
                        _buildTermItem(
                          "Data may be used to improve services.",
                          Icons.analytics_outlined,
                          themeProvider,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: themeProvider.isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Tap Accept below to proceed and start using the app.",
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Decline",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: themeProvider.isDarkMode
                              ? Colors.red[300]
                              : Colors.red[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.isDarkMode
                            ? Colors.teal
                            : const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        await prefs.setBool('hasAcceptedTerms', true);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        "Accept",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildTermItem(
      String text, IconData icon, ThemeProvider themeProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: themeProvider.isDarkMode
                ? Colors.teal[300]
                : const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Requesting Firebase Messaging notification permissions
  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasShownToast = prefs.getBool('hasShownToast') ?? false;

      if (!hasShownToast) {
        Fluttertoast.showToast(msg: "Notifications Enabled");
        await prefs.setBool('hasShownToast', true);
      }
    } else {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F9FA),
          drawer: ModernAppDrawer(
            language: _language,
            onLanguageChanged: (lang) {
              setState(() {
                _language = lang;
              });
            },
            t: t,
          ),
          body: ChatbotWrapper(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: themeProvider.isDarkMode
                      ? [
                          Colors.grey[900]!,
                          Colors.grey[850]!,
                        ]
                      : [
                          const Color(0xFFF8F9FA),
                          const Color(0xFFFFFFFF),
                        ],
                ),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(themeProvider),
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _headerFadeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _headerSlideAnimation.value),
                          child: Opacity(
                            opacity: _headerFadeAnimation.value,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  _buildHeaderSection(themeProvider),
                                  const SizedBox(height: 0),
                                  _buildIssueGrid(themeProvider),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _fabScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _fabScaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode
                          ? [Colors.teal, Colors.teal[300]!]
                          : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode
                            ? Colors.teal.withOpacity(0.3)
                            : const Color(0xFF1565C0).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DiscussionForum()),
                      );
                    },
                    child: const Icon(
                      Icons.forum,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: false,
      elevation: 0,
      backgroundColor:
          themeProvider.isDarkMode ? Colors.grey[800] : const Color(0xFF1565C0),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeProvider.isDarkMode
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[700]!,
                      Colors.teal[600]!,
                    ]
                  : [
                      const Color(0xFF1565C0),
                      const Color(0xFF42A5F5),
                      const Color(0xFF81C784),
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideInDown(
                          child: Text(
                            t('select_issue'),
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SlideInDown(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            t('choose_concern'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Theme toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: const SizedBox.shrink(), // Hide default leading
    );
  }

  Widget _buildHeaderSection(ThemeProvider themeProvider) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black26
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode
                          ? [Colors.teal, Colors.teal[300]!]
                          : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode
                            ? Colors.teal.withOpacity(0.3)
                            : const Color(0xFF42A5F5).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.report_problem,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('title'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('subtitle'),
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueGrid(ThemeProvider themeProvider) {
    final issues = [
      {
        'title': t('garbage'),
        'icon': Icons.delete,
        'image': "assets/garbage.png",
        'page': const GarbagePage(),
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': t('water'),
        'icon': Icons.water_drop,
        'image': "assets/water.png",
        'page': const WaterPage(),
        'color': const Color(0xFF2196F3),
      },
      {
        'title': t('road'),
        'icon': Icons.construction,
        'image': "assets/road.png",
        'page': const RoadPage(),
        'color': const Color(0xFFFF9800),
      },
      {
        'title': t('streetlight'),
        'icon': Icons.lightbulb,
        'image': "assets/streetlight.png",
        'page': const StreetLightPage(),
        'color': const Color(0xFFFFC107),
      },
      {
        'title': t('animals'),
        'icon': Icons.pets,
        'image': "assets/animals.png",
        'page': const AnimalsPage(),
        'color': const Color(0xFF9C27B0),
      },
      {
        'title': t('drainage'),
        'icon': Icons.water,
        'image': "assets/drainage.png",
        'page': const DrainagePage(),
        'color': const Color(0xFF00BCD4),
      },
      {
        'title': t('other'),
        'icon': Icons.more_horiz,
        'image': "assets/newentry.png",
        'page': const NewEntryPage(),
        'color': const Color(0xFF607D8B),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate optimal card height based on screen size
        final double cardHeight = constraints.maxWidth > 600 ? 220 : 200;
        final double aspectRatio = (constraints.maxWidth / 2 - 16) / cardHeight;

        return AnimatedBuilder(
          animation: _cardAnimationController,
          builder: (context, child) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: aspectRatio,
              ),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                final animationDelay = (index * 100).clamp(0, 700);

                return SlideInUp(
                  duration: Duration(milliseconds: 600),
                  delay: Duration(milliseconds: animationDelay),
                  child: buildEnhancedIssueCard(
                    context,
                    themeProvider,
                    issue['title'] as String,
                    issue['image'] as String,
                    issue['page'] as Widget,
                    issue['color'] as Color,
                    issue['icon'] as IconData,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildEnhancedIssueCard(
    BuildContext context,
    ThemeProvider themeProvider,
    String text,
    String imagePath,
    Widget page,
    Color color,
    IconData icon,
  ) {
    return Hero(
      tag: 'issue_$text',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () =>
              showEnhancedProcessingDialog(context, themeProvider, page, color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: themeProvider.isDarkMode
                  ? Border.all(color: Colors.grey[700]!, width: 0.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode
                      ? Colors.black26
                      : color.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top section with image - now takes full width and height
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: themeProvider.isDarkMode
                            ? [
                                color.withOpacity(0.15),
                                color.withOpacity(0.08),
                              ]
                            : [
                                color.withOpacity(0.1),
                                color.withOpacity(0.05),
                              ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: themeProvider.isDarkMode
                                ? Colors.grey[700]?.withOpacity(0.9)
                                : Colors.white.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: themeProvider.isDarkMode
                                    ? Colors.black26
                                    : color.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Image.asset(
                              imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  icon,
                                  size: 50,
                                  color: color,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom section with text
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[800]
                          : Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode
                                ? color.withOpacity(0.2)
                                : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: themeProvider.isDarkMode
                                ? Border.all(
                                    color: color.withOpacity(0.3), width: 0.5)
                                : null,
                          ),
                          child: Text(
                            t('tap_to_report'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.isDarkMode
                                  ? color.withOpacity(0.9)
                                  : color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showEnhancedProcessingDialog(BuildContext context,
      ThemeProvider themeProvider, Widget nextPage, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode
                    ? [
                        Colors.grey[800]!,
                        Colors.grey[700]!.withOpacity(0.8),
                      ]
                    : [
                        Colors.white,
                        color.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: themeProvider.isDarkMode
                  ? Border.all(color: Colors.grey[600]!, width: 0.5)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: themeProvider.isDarkMode
                          ? [Colors.teal, Colors.teal[300]!]
                          : [color, color.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode
                            ? Colors.teal.withOpacity(0.3)
                            : color.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t('calling_magic'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.teal : color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t('processing_request'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.isDarkMode ? Colors.teal : color,
                    ),
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
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }
}
