import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';


class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  HelpCenterPageState createState() => HelpCenterPageState();
}

class HelpCenterPageState extends State<HelpCenterPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
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
            controller: _scrollController,
            slivers: [
              _buildSliverAppBar(themeProvider),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildSearchSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildQuickActionsSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildGettingStartedSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildComplaintManagementSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildAccountSettingsSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildTechnicalSupportSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildFAQSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildContactSupportSection(themeProvider),
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
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: themeProvider.isDarkMode
          ? Colors.grey[850]
          : const Color(0xFF1565C0),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                            "Help Center",
                            style: TextStyle(
                              fontSize: 24,
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
                        const SizedBox(height: 4),
                        SlideInDown(
                          delay: const Duration(milliseconds: 200),
                          child: Text(
                            "We're here to help you",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.help_center,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: const SizedBox.shrink(),
    );
  }

  Widget _buildSearchSection(ThemeProvider themeProvider) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Color(0xFF2196F3),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Search Help Articles",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "What can we help you with?",
                hintStyle: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2196F3)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: themeProvider.isDarkMode 
                    ? Colors.grey[700]?.withOpacity(0.3)
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
                ),
              ),
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(ThemeProvider themeProvider) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    "Submit Complaint",
                    Icons.add_circle,
                    const Color(0xFF4CAF50),
                    "File a new complaint",
                    themeProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    "Track Status",
                    Icons.track_changes,
                    const Color(0xFF2196F3),
                    "Check complaint progress",
                    themeProvider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    "Contact Support",
                    Icons.support_agent,
                    const Color(0xFFFF9800),
                    "Get immediate help",
                    themeProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    "Account Settings",
                    Icons.settings,
                    const Color(0xFF9C27B0),
                    "Manage your account",
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

  Widget _buildQuickActionCard(String title, IconData icon, Color color, String subtitle, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (themeProvider.isDarkMode ? Colors.black : Colors.grey)
                .withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedSection(ThemeProvider themeProvider) {
    return _buildHelpSection(
      "Getting Started",
      Icons.rocket_launch,
      const Color(0xFF4CAF50),
      [
        _buildHelpItem(
          "How to create an account",
          "Learn how to register and set up your profile",
          Icons.person_add,
          themeProvider,
        ),
        _buildHelpItem(
          "App navigation guide",
          "Understand the app interface and features",
          Icons.map,
          themeProvider,
        ),
        _buildHelpItem(
          "First-time setup",
          "Complete your profile and preferences",
          Icons.settings_applications,
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildComplaintManagementSection(ThemeProvider themeProvider) {
    return _buildHelpSection(
      "Complaint Management",
      Icons.assignment,
      const Color(0xFF2196F3),
      [
        _buildHelpItem(
          "How to submit a complaint",
          "Step-by-step guide to filing complaints",
          Icons.add_task,
          themeProvider,
        ),
        _buildHelpItem(
          "Tracking complaint status",
          "Monitor progress and updates",
          Icons.timeline,
          themeProvider,
        ),
        _buildHelpItem(
          "Attaching files and photos",
          "Add supporting documents to complaints",
          Icons.attach_file,
          themeProvider,
        ),
        _buildHelpItem(
          "Editing submitted complaints",
          "Make changes to pending complaints",
          Icons.edit,
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildAccountSettingsSection(ThemeProvider themeProvider) {
    return _buildHelpSection(
      "Account & Settings",
      Icons.account_circle,
      const Color(0xFF9C27B0),
      [
        _buildHelpItem(
          "Update profile information",
          "Change your personal details",
          Icons.edit_attributes,
          themeProvider,
        ),
        _buildHelpItem(
          "Notification preferences",
          "Manage alerts and notifications",
          Icons.notifications,
          themeProvider,
        ),
        _buildHelpItem(
          "Privacy settings",
          "Control your data and privacy options",
          Icons.privacy_tip,
          themeProvider,
        ),
        _buildHelpItem(
          "Change password",
          "Update your account security",
          Icons.lock_reset,
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildTechnicalSupportSection(ThemeProvider themeProvider) {
    return _buildHelpSection(
      "Technical Support",
      Icons.build,
      const Color(0xFFE91E63),
      [
        _buildHelpItem(
          "App not loading properly",
          "Troubleshoot loading and performance issues",
          Icons.refresh,
          themeProvider,
        ),
        _buildHelpItem(
          "Login problems",
          "Fix authentication and access issues",
          Icons.login,
          themeProvider,
        ),
        _buildHelpItem(
          "File upload errors",
          "Resolve problems with attachments",
          Icons.cloud_upload,
          themeProvider,
        ),
        _buildHelpItem(
          "Sync issues",
          "Fix data synchronization problems",
          Icons.sync_problem,
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildFAQSection(ThemeProvider themeProvider) {
    return _buildHelpSection(
      "Frequently Asked Questions",
      Icons.quiz,
      const Color(0xFFFF9800),
      [
        _buildFAQItem(
          "How long does it take to process a complaint?",
          "Complaint processing times vary by category and complexity. Typically, you can expect an initial response within 24-48 hours, with full resolution taking 5-10 business days.",
          themeProvider,
        ),
        _buildFAQItem(
          "Can I submit anonymous complaints?",
          "Yes, the app supports anonymous complaint submission. However, providing contact information helps us follow up and provide updates on your complaint status.",
          themeProvider,
        ),
        _buildFAQItem(
          "What file formats are supported for attachments?",
          "You can upload images (JPG, PNG, GIF), documents (PDF, DOC, DOCX), and video files (MP4, MOV) up to 10MB each. Maximum of 5 files per complaint.",
          themeProvider,
        ),
        _buildFAQItem(
          "How do I delete my account?",
          "To delete your account, go to Settings > Account > Delete Account. Note that this action is permanent and cannot be undone. All your data will be removed.",
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildContactSupportSection(ThemeProvider themeProvider) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Color(0xFF42A5F5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Still Need Help?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Can't find what you're looking for? Our support team is available 24/7 to help you.",
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildContactOption(
                    "Live Chat",
                    Icons.chat,
                    "Available 24/7",
                    const Color(0xFF4CAF50),
                    themeProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactOption(
                    "Email Support",
                    Icons.email,
                    "Response within 4hrs",
                    const Color(0xFF2196F3),
                    themeProvider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContactOption(
                    "Phone Support",
                    Icons.phone,
                    "Mon-Fri 9AM-6PM",
                    const Color(0xFFFF9800),
                    themeProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactOption(
                    "Video Call",
                    Icons.video_call,
                    "Schedule a session",
                    const Color(0xFF9C27B0),
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

  Widget _buildHelpSection(String title, IconData icon, Color color, List<Widget> children, ThemeProvider themeProvider) {
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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: children,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String subtitle, IconData icon, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle help item tap
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey[700]?.withOpacity(0.3)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.grey[600]!.withOpacity(0.3)
                    : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF2196F3),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: themeProvider.isDarkMode
            ? Colors.grey[700]?.withOpacity(0.3)
            : Colors.grey[50],
        collapsedBackgroundColor: themeProvider.isDarkMode
            ? Colors.grey[700]?.withOpacity(0.3)
            : Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: themeProvider.isDarkMode
                ? Colors.grey[600]!.withOpacity(0.3)
                : Colors.grey[200]!,
          ),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: themeProvider.isDarkMode
                ? Colors.grey[600]!.withOpacity(0.3)
                : Colors.grey[200]!,
          ),
        ),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        iconColor: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        collapsedIconColor: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(String title, IconData icon, String subtitle, Color color, ThemeProvider themeProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Handle contact option tap
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}