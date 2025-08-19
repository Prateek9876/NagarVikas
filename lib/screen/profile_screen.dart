import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:nagarvikas/screen/privacy_policy_page.dart';
import '../theme/theme_provider.dart';
// import 'package:nagarvikas/screen/help_center_page.dart';

/// Modern Profile Settings Page
/// A comprehensive profile and settings page with beautiful UI
/// matching the app's modern design theme with dark mode support

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  // User data variables
  String name = "Loading...";
  String email = "Loading...";
  String userId = "Loading...";
  String phoneNumber = "Not provided";
  String joinDate = "Loading...";
  int complaintsCount = 0;
  bool isLoading = true;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserData();
    _fetchComplaintsCount();
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

  /// Fetches user data from Firebase Authentication and Realtime Database
  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref().child('users').child(user.uid);

        final snapshot = await userRef.get();
        if (snapshot.exists) {
          Map<dynamic, dynamic>? data =
              snapshot.value as Map<dynamic, dynamic>?;
          setState(() {
            name = data?['name'] ?? "User";
            email = user.email ?? "No email";
            userId = user.uid;
            phoneNumber = data?['phone'] ?? user.phoneNumber ?? "Not provided";
            joinDate = _formatJoinDate(user.metadata.creationTime);
            isLoading = false;
          });
        } else {
          setState(() {
            name = user.displayName ?? "User";
            email = user.email ?? "No email";
            userId = user.uid;
            phoneNumber = user.phoneNumber ?? "Not provided";
            joinDate = _formatJoinDate(user.metadata.creationTime);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetches the count of complaints filed by the current user
  Future<void> _fetchComplaintsCount() async {
    try {
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId != null) {
        DatabaseReference ref = FirebaseDatabase.instance.ref('complaints/');

        // Listen to changes in complaints for real-time updates
        ref
            .orderByChild("user_id")
            .equalTo(currentUserId)
            .onValue
            .listen((event) {
          final data = event.snapshot.value as Map<dynamic, dynamic>?;

          if (mounted) {
            setState(() {
              complaintsCount = data?.length ?? 0;
            });
          }
        });
      }
    } catch (e) {
      // Handle error silently or show error message
      if (mounted) {
        setState(() {
          complaintsCount = 0;
        });
      }
    }
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return "Unknown";
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    String year = date.year.toString();
    return "$day/$month/$year";
  }

  String _formatUserId(String uid) {
    if (uid.isEmpty || uid == "Loading...") return uid;
    if (uid.length > 16) {
      return "${uid.substring(0, 8)}...${uid.substring(uid.length - 4)}";
    }
    return uid;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        body: Container(
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
            slivers: [
              _buildSliverAppBar(themeProvider),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildAccountSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildSupportSection(themeProvider),
                      const SizedBox(height: 30),
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

  Widget _buildSliverAppBar(ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor:
          themeProvider.isDarkMode ? Colors.grey[850] : const Color(0xFF1565C0),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeProvider.isDarkMode
                  ? [
                      Colors.grey[850]!,
                      Colors.grey[800]!,
                      Colors.grey[700]!,
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
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideInDown(
                          child: const Text(
                            "Profile & Settings",
                            style: TextStyle(
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
                            "Manage your account and preferences",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
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
          ),
        ),
      ),
      leading: const SizedBox.shrink(), // Hide default leading
    );
  }

  Widget _buildProfileSection(ThemeProvider themeProvider) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (themeProvider.isDarkMode ? Colors.black : Colors.grey)
                  .withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Avatar and Basic Info
            Row(
              children: [
                Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF42A5F5).withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading ? "Loading..." : name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoading ? "Loading..." : email,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Active",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditProfileDialog(themeProvider),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF42A5F5),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Profile Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Member Since",
                    isLoading ? "..." : joinDate,
                    Icons.calendar_today,
                    const Color(0xFF2196F3),
                    themeProvider,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    "Complaints Filed",
                    complaintsCount.toString(),
                    Icons.report,
                    const Color(0xFFFF9800),
                    themeProvider,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ThemeProvider themeProvider) {
    return _buildSection(
      "Account Information",
      Icons.person_outline,
      [
        _buildInfoTile("Full Name", name, Icons.person,
            () => _showEditDialog("name", themeProvider), themeProvider),
        _buildInfoTile(
            "Email Address", email, Icons.email, null, themeProvider),
        _buildInfoTile("Phone Number", phoneNumber, Icons.phone,
            () => _showEditDialog("phone", themeProvider), themeProvider),
        _buildInfoTile("User ID", _formatUserId(userId), Icons.fingerprint,
            null, themeProvider),
      ],
      themeProvider,
    );
  }

  Widget _buildSupportSection(ThemeProvider themeProvider) {
    return _buildSection(
      "Support & Security",
      Icons.help_outline,
      [
        _buildToggleTile(
            "Dark Mode",
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            themeProvider.isDarkMode
                ? const Color(0xFFFFB74D)
                : const Color(0xFF424242),
            themeProvider.isDarkMode,
            (value) => themeProvider.toggleTheme(),
            themeProvider),
        _buildActionTile("Change Password", Icons.lock_outline,
            const Color(0xFF2196F3), () {}, themeProvider),
        _buildActionTile("Privacy Settings", Icons.privacy_tip_outlined,
            const Color(0xFF4CAF50), () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage()));
        }, themeProvider),
        _buildActionTile(
            "Help Center", Icons.help_center_outlined, const Color(0xFFFF9800),
            () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const HelpCenterPage()),
          // );
        }, themeProvider),
        _buildActionTile("Report Issue", Icons.report_problem_outlined,
            const Color(0xFFE91E63), () {}, themeProvider),
        _buildActionTile(
            "Logout",
            Icons.logout_outlined,
            const Color(0xFFf44336),
            () => _showLogoutDialog(themeProvider),
            themeProvider),
      ],
      themeProvider,
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children,
      ThemeProvider themeProvider) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (themeProvider.isDarkMode ? Colors.black : Colors.grey)
                  .withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF42A5F5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            ...children,
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon,
      VoidCallback? onTap, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[500]
                        : Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleTile(String title, IconData icon, Color color,
      bool isToggled, ValueChanged<bool> onToggle, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isToggled,
                  onChanged: onToggle,
                  activeColor: themeProvider.isDarkMode
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFF424242),
                  activeTrackColor: themeProvider.isDarkMode
                      ? const Color(0xFFFFB74D).withOpacity(0.3)
                      : const Color(0xFF424242).withOpacity(0.3),
                  inactiveThumbColor: themeProvider.isDarkMode
                      ? Colors.grey[600]
                      : Colors.grey[400],
                  inactiveTrackColor: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  splashRadius: 20,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color,
      VoidCallback onTap, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: themeProvider.isDarkMode
                      ? Colors.grey[500]
                      : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: Color(0xFF42A5F5)),
            const SizedBox(width: 12),
            Text(
              "Edit Profile",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          "Profile editing feature will be available in the next update.",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String field, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit ${field == 'name' ? 'Name' : 'Phone Number'}",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: field == 'name' ? 'Full Name' : 'Phone Number',
            labelStyle: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color:
                    themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              "Logout",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to logout from your account?",
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final FirebaseAuth auth = FirebaseAuth.instance;
              await auth.signOut();
              // Navigate to login page - adjust route as needed
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
