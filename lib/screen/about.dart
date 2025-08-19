import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/theme_provider.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode 
              ? Colors.grey[900] 
              : Colors.grey[50],
          appBar: AppBar(
            title: FadeIn(
              child: Text(
                'About NagarVikas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            centerTitle: true,
            backgroundColor: themeProvider.isDarkMode 
                ? Colors.grey[800] 
                : const Color(0xFF1565C0),
            elevation: 0,
            iconTheme: IconThemeData(
              color: themeProvider.isDarkMode ? Colors.white : Colors.white,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildAppInfoCard(themeProvider),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildFeatureSection(themeProvider),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _buildTeamSection(themeProvider),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _buildContactCard(themeProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppInfoCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: themeProvider.isDarkMode 
                ? Colors.teal[800]
                : const Color(0xFF1565C0).withOpacity(0.2),
            child: Icon(
              Icons.verified_user,
              size: 40,
              color: themeProvider.isDarkMode 
                  ? Colors.teal[200]
                  : const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'NagarVikas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'A civic issue complaint application designed to bridge the gap between citizens and municipal authorities.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(ThemeProvider themeProvider) {
    final features = [
      {
        'icon': Icons.report,
        'title': 'Easy Reporting',
        'description': 'Quickly report civic issues with photos and location',
      },
      {
        'icon': Icons.track_changes,
        'title': 'Real-time Tracking',
        'description': 'Track the status of your complaints in real-time',
      },
      {
        'icon': Icons.notifications,
        'title': 'Smart Notifications',
        'description': 'Get updates when your issues are resolved',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode 
                        ? Colors.teal[800]!.withOpacity(0.3)
                        : const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: themeProvider.isDarkMode 
                        ? Colors.teal[200]
                        : const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTeamSection(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Team',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'NagarVikas was developed by a passionate team of developers and civic enthusiasts committed to improving urban living through technology.',
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamMember(
                themeProvider,
                'Developer',
                Icons.code,
                const Color(0xFF42A5F5),
              ),
              _buildTeamMember(
                themeProvider,
                'Designer',
                Icons.design_services,
                const Color(0xFF66BB6A),
              ),
              _buildTeamMember(
                themeProvider,
                'Support',
                Icons.support_agent,
                const Color(0xFFFFA726),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(ThemeProvider themeProvider, String role, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode 
                ? color.withOpacity(0.2)
                : color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 30,
            color: themeProvider.isDarkMode 
                ? color.withOpacity(0.8)
                : color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          role,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          _buildContactItem(
            themeProvider,
            Icons.email,
            'Email',
            'support@nagarvikas.com',
            () {},
          ),
          const SizedBox(height: 10),
          _buildContactItem(
            themeProvider,
            Icons.phone,
            'Phone',
            '+1 (123) 456-7890',
            () {},
          ),
          const SizedBox(height: 10),
          _buildContactItem(
            themeProvider,
            Icons.language,
            'Website',
            'www.nagarvikas.com',
            () {},
          ),
          const SizedBox(height: 15),
          Center(
            child: Text(
              'We value your feedback!',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: themeProvider.isDarkMode ? Colors.teal[200] : const Color(0xFF1565C0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    ThemeProvider themeProvider,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode 
              ? Colors.grey[700]!.withOpacity(0.5)
              : Colors.grey[100]!.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: themeProvider.isDarkMode 
                  ? Colors.teal[200]
                  : const Color(0xFF1565C0),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}