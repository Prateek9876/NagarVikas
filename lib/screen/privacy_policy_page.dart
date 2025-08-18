import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

/// Privacy Policy Page
/// A comprehensive privacy policy page with beautiful UI
/// matching the app's modern design theme with dark mode support

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  PrivacyPolicyPageState createState() => PrivacyPolicyPageState();
}

class PrivacyPolicyPageState extends State<PrivacyPolicyPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
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
                      _buildIntroSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildDataCollectionSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildDataUsageSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildDataSharingSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildDataSecuritySection(themeProvider),
                      const SizedBox(height: 20),
                      _buildUserRightsSection(themeProvider),
                      const SizedBox(height: 20),
                      _buildContactSection(themeProvider),
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
                            "Privacy Policy",
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
                            "Your privacy matters to us",
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
                      Icons.privacy_tip,
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

  Widget _buildIntroSection(ThemeProvider themeProvider) {
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
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF4CAF50),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Introduction",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2196F3).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Last Updated: ${_getCurrentDate()}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This Privacy Policy describes how we collect, use, and protect your personal information when you use our complaint management application. We are committed to protecting your privacy and ensuring transparency about our data practices.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCollectionSection(ThemeProvider themeProvider) {
    return _buildSection(
      "Information We Collect",
      Icons.data_usage,
      const Color(0xFF2196F3),
      [
        _buildSubSection(
          "Personal Information",
          [
            "Full name and email address for account creation",
            "Phone number for contact purposes (optional)",
            "Profile information you choose to provide",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "Complaint Data",
          [
            "Details of complaints you submit through the app",
            "Media files (photos, documents) attached to complaints",
            "Location data if you choose to share it for complaint context",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "Technical Information",
          [
            "Device information and operating system",
            "App usage analytics and performance data",
            "Log files for troubleshooting purposes",
          ],
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildDataUsageSection(ThemeProvider themeProvider) {
    return _buildSection(
      "How We Use Your Information",
      Icons.settings,
      const Color(0xFF4CAF50),
      [
        _buildSubSection(
          "Service Provision",
          [
            "Process and manage your complaints effectively",
            "Communicate updates about your submitted complaints",
            "Provide customer support and respond to inquiries",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "App Improvement",
          [
            "Analyze usage patterns to improve app functionality",
            "Develop new features based on user needs",
            "Fix bugs and enhance app performance",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "Legal Compliance",
          [
            "Comply with applicable laws and regulations",
            "Respond to legal requests and prevent fraud",
            "Protect the rights and safety of users",
          ],
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildDataSharingSection(ThemeProvider themeProvider) {
    return _buildSection(
      "Information Sharing",
      Icons.share,
      const Color(0xFFFF9800),
      [
        _buildInfoCard(
          "We do not sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:",
          themeProvider,
        ),
        _buildSubSection(
          "Authorized Sharing",
          [
            "With relevant authorities when required by law",
            "With your explicit consent for specific purposes",
            "With service providers who assist in app functionality",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "Security Measures",
          [
            "All third-party services are bound by confidentiality agreements",
            "Data sharing is limited to what is necessary for the specified purpose",
            "We ensure adequate security measures are in place",
          ],
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildDataSecuritySection(ThemeProvider themeProvider) {
    return _buildSection(
      "Data Security",
      Icons.security,
      const Color(0xFFE91E63),
      [
        _buildInfoCard(
          "We implement industry-standard security measures to protect your personal information:",
          themeProvider,
        ),
        _buildSubSection(
          "Technical Safeguards",
          [
            "Encryption of data in transit and at rest",
            "Secure Firebase authentication and database",
            "Regular security audits and updates",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "Access Controls",
          [
            "Limited access to personal data on a need-to-know basis",
            "Multi-factor authentication for administrative access",
            "Regular monitoring for unauthorized access attempts",
          ],
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildUserRightsSection(ThemeProvider themeProvider) {
    return _buildSection(
      "Your Rights",
      Icons.account_circle,
      const Color(0xFF9C27B0),
      [
        _buildSubSection(
          "Data Access & Control",
          [
            "Access and review your personal information",
            "Update or correct inaccurate information",
            "Request deletion of your account and data",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "Privacy Choices",
          [
            "Opt-out of non-essential data collection",
            "Control notification preferences",
            "Manage app permissions on your device",
          ],
          themeProvider,
        ),
        _buildSubSection(
          "Data Portability",
          [
            "Request a copy of your data in a portable format",
            "Transfer your data to another service (where applicable)",
            "Receive information about data processing activities",
          ],
          themeProvider,
        ),
      ],
      themeProvider,
    );
  }

  Widget _buildContactSection(ThemeProvider themeProvider) {
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
                    Icons.contact_support,
                    color: Color(0xFF42A5F5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Contact Us",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Questions About Privacy?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "If you have any questions about this Privacy Policy or our data practices, please contact us:",
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(Icons.email, "privacy@complaintapp.com", themeProvider),
                  const SizedBox(height: 8),
                  _buildContactItem(Icons.phone, "+1 (555) 123-4567", themeProvider),
                  const SizedBox(height: 8),
                  _buildContactItem(Icons.location_on, "123 Privacy Street, Data City, DC 12345", themeProvider),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "We will respond to privacy inquiries within 30 days",
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF4CAF50),
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
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children, ThemeProvider themeProvider) {
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

  Widget _buildSubSection(String title, List<String> items, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: const Color(0xFF2196F3),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, ThemeProvider themeProvider) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF42A5F5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }
}