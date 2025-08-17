import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:nagarvikas/screen/profile_screen.dart';
import 'package:nagarvikas/screen/my_complaints.dart';
import 'package:nagarvikas/screen/feedback.dart';
import 'package:nagarvikas/screen/referearn.dart';
import 'package:nagarvikas/screen/facing_issues.dart';
import 'package:nagarvikas/screen/about.dart';
import 'package:nagarvikas/screen/contact.dart';
import 'package:nagarvikas/screen/fun_game_screen.dart';
import 'package:nagarvikas/screen/login_page.dart';

import '../theme/theme_provider.dart';

class ModernAppDrawer extends StatefulWidget {
  final String language;
  final void Function(String) onLanguageChanged;
  final String Function(String) t;

  const ModernAppDrawer({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.t,
  });

  @override
  State<ModernAppDrawer> createState() => _ModernAppDrawerState();
}

class _ModernAppDrawerState extends State<ModernAppDrawer>
    with TickerProviderStateMixin {
  String _appVersion = "Loading...";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _initAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  Future<void> _loadAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: themeProvider.isDarkMode
                  ? [
                      Colors.grey[850]!,
                      Colors.grey[900]!,
                    ]
                  : [
                      const Color(0xFFF8F9FA),
                      const Color(0xFFFFFFFF),
                    ],
            ),
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(25)),
          ),
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.only(bottom: 10), // Add bottom padding
                  child: Column(
                    children: [
                      _buildLanguageSelector(),
                      const SizedBox(height: 5), // Reduced spacing
                      _buildMenuSection(),
                      const SizedBox(height: 10), // Reduced spacing
                      _buildSocialMediaSection(),
                      const SizedBox(height: 10), // Reduced spacing
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 180, // Reduced height from 200 to 180
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1565C0),
            Color(0xFF42A5F5),
            Color(0xFF81C784),
          ],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SlideInLeft(
                  duration: const Duration(milliseconds: 800),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'app_icon',
                        child: Container(
                          padding: const EdgeInsets.all(6), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            'assets/app_icon.png',
                            width: 40, // Reduced size
                            height: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "NagarVikas",
                              style: TextStyle(
                                fontSize: 24, // Reduced font size
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
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'City Development App',
                                style: TextStyle(
                                  fontSize: 11, // Reduced font size
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15), // Reduced spacing
                SlideInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 14, // Reduced icon size
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Made with ❤️ by Prateek Chourasia',
                          style: TextStyle(
                            fontSize: 11, // Reduced font size
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
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

  Widget _buildLanguageSelector() {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Container(
          margin: const EdgeInsets.all(12), // Reduced margin
          padding: const EdgeInsets.all(12), // Reduced padding
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // Reduced padding
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Color(0xFF42A5F5),
                      size: 18, // Reduced icon size
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Language / भाषा",
                    style: TextStyle(
                      fontSize: 14, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLanguageChip(
                      'English',
                      'en',
                      Icons.language,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLanguageChip(
                      'हिन्दी',
                      'hi',
                      Icons.translate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLanguageChip(String label, String langCode, IconData icon) {
    bool isSelected = widget.language == langCode;
    return GestureDetector(
      onTap: () => widget.onLanguageChanged(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 12), // Reduced padding
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                )
              : null,
          color: isSelected ? null : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1565C0)
                : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[500],
              size: 16, // Reduced icon size
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12, // Reduced font size
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final menuItems = [
      DrawerMenuItem(
        icon: Icons.person_outline,
        title: widget.t('profile'),
        page: ProfilePage(),
        color: const Color(0xFF4CAF50),
      ),
      DrawerMenuItem(
        icon: Icons.history,
        title: widget.t('my_complaints'),
        page: MyComplaintsScreen(),
        color: const Color(0xFF2196F3),
      ),
      DrawerMenuItem(
        icon: Icons.favorite_outline,
        title: widget.t('user_feedback'),
        page: FeedbackPage(),
        color: const Color(0xFFE91E63),
      ),
      DrawerMenuItem(
        icon: Icons.card_giftcard_outlined,
        title: widget.t('refer_earn'),
        page: ReferAndEarnPage(),
        color: const Color(0xFFFF9800),
      ),
      DrawerMenuItem(
        icon: Icons.report_problem_outlined,
        title: widget.t('facing_issues'),
        page: FacingIssuesPage(),
        color: const Color(0xFFFF5722),
      ),
      DrawerMenuItem(
        icon: Icons.info_outline,
        title: widget.t('about'),
        page: AboutAppPage(),
        color: const Color(0xFF9C27B0),
      ),
      DrawerMenuItem(
        icon: Icons.headset_mic_outlined,
        title: widget.t('contact'),
        page: ContactUsPage(),
        color: const Color(0xFF00BCD4),
      ),
      DrawerMenuItem(
        icon: Icons.share_outlined,
        title: widget.t('share_app'),
        color: const Color(0xFF607D8B),
        onTap: () {
          Share.share(
            'Check out this app: https://github.com/Prateek9876/NagarVikas',
            subject: 'NagarVikas App',
          );
        },
      ),
      DrawerMenuItem(
        icon: Icons.games_outlined,
        title: '2048 Game',
        color: const Color(0xFF795548),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FunGameScreen()),
          );
        },
      ),
      DrawerMenuItem(
        icon: Icons.logout_outlined,
        title: widget.t('logout'),
        color: const Color(0xFFf44336),
        onTap: () => _showLogoutDialog(),
      ),
    ];

    return Column(
      children: menuItems
          .asMap()
          .entries
          .map((entry) => FadeInUp(
                delay: Duration(milliseconds: 50 * entry.key), // Reduced delay
                child: _buildMenuItem(entry.value),
              ))
          .toList(),
    );
  }

  Widget _buildMenuItem(DrawerMenuItem item) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 2), // Reduced margins
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: item.onTap ??
                (item.page != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => item.page!),
                        );
                      }
                    : null),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 14), // Reduced padding
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), // Reduced padding
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 20, // Reduced icon size
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14, // Reduced font size
                        fontWeight: FontWeight.w500,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12, // Reduced icon size
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSocialMediaSection() {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return FadeInUp(
        duration: const Duration(milliseconds: 800),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12), // Reduced margin
          padding: const EdgeInsets.all(16), // Reduced padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeProvider.isDarkMode
                  ? [
                      Colors.grey[800]!,
                      Colors.grey[850]!,
                    ]
                  : [
                      const Color(0xFFF3E5F5),
                      const Color(0xFFE1F5FE),
                    ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFF42A5F5).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.t('follow_us'),
                style: TextStyle(
                  fontSize: 16, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12), // Reduced spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialIcon(
                    FontAwesomeIcons.facebook,
                    "https://facebook.com",
                    const Color(0xFF1877F2),
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.instagram,
                    "https://instagram.com",
                    const Color(0xFFE4405F),
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.youtube,
                    "https://youtube.com",
                    const Color(0xFFFF0000),
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.twitter,
                    "https://twitter.com",
                    const Color(0xFF1DA1F2),
                  ),
                  _buildSocialIcon(
                    FontAwesomeIcons.linkedin,
                    "https://linkedin.com/in/prateek-chourasia-in",
                    const Color(0xFF0A66C2),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSocialIcon(IconData icon, String url, Color color) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(url)),
        child: Container(
          padding: const EdgeInsets.all(10), // Reduced padding
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 20, // Reduced icon size
          ),
        ),
      );
    });
  }

  Widget _buildFooter() {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return FadeInUp(
        duration: const Duration(milliseconds: 1000),
        child: Container(
          padding: const EdgeInsets.all(16), // Reduced padding
          child: Column(
            children: [
              Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Text(
                "© 2025 NextGen Soft Labs and Prateek.\nAll Rights Reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11, // Reduced font size
                  fontWeight: FontWeight.w500,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF42A5F5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF42A5F5).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  "${widget.t('version')} $_appVersion",
                  style: const TextStyle(
                    fontSize: 11, // Reduced font size
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.t('logout_title')),
          ],
        ),
        content: Text(widget.t('logout_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              widget.t('cancel'),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final FirebaseAuth auth = FirebaseAuth.instance;
              await auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(widget.t('yes')),
          ),
        ],
      ),
    );
  }
}

class DrawerMenuItem {
  final IconData icon;
  final String title;
  final Widget? page;
  final Color color;
  final VoidCallback? onTap;

  DrawerMenuItem({
    required this.icon,
    required this.title,
    this.page,
    required this.color,
    this.onTap,
  });
}
