import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nagarvikas/widgets/bar_chart_widget.dart';
import 'package:nagarvikas/widgets/pie_chart_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_dashboard.dart';
import 'login_page.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int _selectedIndex = 1; // Analytics is selected by default
  int resolved = 0;
  int pending = 0;
  int rejected = 0;
  bool isLoading = true;
  bool isDarkMode = false;

  List<Widget> dashboardWidgets = [];

  // Bottom navigation items
  static const List<BottomNavigationBarItem> _bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.logout),
      label: 'Logout',
    ),
  ];

  @override
  void initState() {
    super.initState();
    fetchComplaintStats();
  }

  // Handle bottom navigation item tap
  void _onItemTapped(int index) {
    if (index == 0) { // Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else if (index == 2) { // Logout
      _showLogoutDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void fetchComplaintStats() async {
    final ref = FirebaseDatabase.instance.ref('complaints');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      int res = 0, pen = 0, rej = 0;
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final complaint = Map<String, dynamic>.from(value);
        final status = (complaint['status'] ?? 'Pending').toString().toLowerCase();
        if (status == 'resolved') {
          res++;
        } else if (status == 'pending') {
          pen++;
        } else if (status == 'rejected') {
          rej++;
        }
      });

      setState(() {
        resolved = res;
        pending = pen;
        rejected = rej;
        isLoading = false;
        _buildDashboardSections();
      });
    } else {
      setState(() {
        resolved = pending = rejected = 0;
        isLoading = false;
        _buildDashboardSections();
      });
    }
  }

  void _buildDashboardSections() {
    final total = resolved + pending + rejected;

    dashboardWidgets = [
      _buildSectionHeader(Icons.insights, "Complaints Overview"),
      PieChartWidget(resolved: resolved, pending: pending, rejected: rejected),
      const SizedBox(height: 20),
      _buildSectionHeader(Icons.bar_chart, "Monthly Complaint Trends"),
      SizedBox(
        height: 200,
        child: BarChartWidget(
          values: [
            resolved.toDouble(),
            pending.toDouble(),
            rejected.toDouble(),
            total.toDouble(),
          ],
          labels: ['Resolved', 'Pending', 'Rejected', 'Total'],
          colors: [Colors.green, Colors.orange, Colors.red, Colors.blue],
        ),
      ),
      const SizedBox(height: 20),
      _buildSectionHeader(Icons.data_usage, "Complaints Summary"),
      LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          int crossAxisCount = screenWidth > 600 ? 2 : 2;
          double spacing = 12;
          double totalSpacing = spacing * (crossAxisCount - 1);
          double cardWidth = (screenWidth - totalSpacing) / crossAxisCount;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: [
              _buildNeumorphicCard('Total', total, Colors.blue, Icons.all_inbox, cardWidth),
              _buildNeumorphicCard('Resolved', resolved, Colors.green, Icons.check_circle, cardWidth),
              _buildNeumorphicCard('Pending', pending, Colors.orange, Icons.timelapse, cardWidth),
              _buildNeumorphicCard('Rejected', rejected, Colors.red, Icons.cancel, cardWidth),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildSectionHeader(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: isDarkMode ? Colors.tealAccent : Colors.teal),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildNeumorphicCard(
      String title, int count, Color color, IconData icon, double width) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: 115,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFEFF3FA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black54 : Colors.grey.shade300,
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: GoogleFonts.urbanist(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF121212))
          : ThemeData.light().copyWith(scaffoldBackgroundColor: const Color(0xFFF2F7FF)),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: Text("Analytics Dashboard", style: GoogleFonts.poppins()),
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                });
              },
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dashboardWidgets.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 30.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: dashboardWidgets[index],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        bottomNavigationBar: BottomNavigationBar(
          items: _bottomNavItems,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          elevation: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
