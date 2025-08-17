import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nagarvikas/widgets/bar_chart_widget.dart';
import 'package:nagarvikas/widgets/pie_chart_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:nagarvikas/theme/theme_provider.dart';
import 'admin_dashboard.dart';
import 'login_page.dart';
import 'complaint_details_page.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  int _selectedIndex = 1; // Analytics is selected by default
  int resolved = 0;
  int pending = 0;
  int inProgress = 0; // Changed from rejected to inProgress
  bool isLoading = true;

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

  Future<void> fetchComplaintStats() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ref = FirebaseDatabase.instance.ref('complaints');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        int res = 0, pen = 0, inProg = 0; // Changed rej to inProg
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final complaint = Map<String, dynamic>.from(value);
          final status = (complaint['status'] ?? 'Pending').toString().toLowerCase();
          if (status == 'resolved') {
            res++;
          } else if (status == 'pending') {
            pen++;
          } else if (status == 'in progress') { // Changed from rejected to in progress
            inProg++;
          }
        });

        setState(() {
          resolved = res;
          pending = pen;
          inProgress = inProg; // Changed from rejected to inProgress
          isLoading = false;
          _buildDashboardSections();
        });
      } else {
        setState(() {
          resolved = pending = inProgress = 0; // Changed rejected to inProgress
          isLoading = false;
          _buildDashboardSections();
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _buildDashboardSections() {
    final total = resolved + pending + inProgress; // Changed rejected to inProgress
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    dashboardWidgets = [
      _buildSectionHeader(Icons.insights, "Complaints Overview"),
      PieChartWidget(resolved: resolved, pending: pending, rejected: inProgress), // Note: PieChartWidget might need updating too
      const SizedBox(height: 20),
      _buildSectionHeader(Icons.bar_chart, "Monthly Complaint Trends"),
      SizedBox(
        height: 200,
        child: BarChartWidget(
          values: [
            resolved.toDouble(),
            pending.toDouble(),
            inProgress.toDouble(), // Changed from rejected
            total.toDouble(),
          ],
          labels: ['Resolved', 'Pending', 'In Progress', 'Total'], // Updated label
          colors: [Colors.green, Colors.orange, Colors.blue, Colors.purple], // Changed red to blue for In Progress
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
              _buildClickableNeumorphicCard('Total', total, Colors.purple, Icons.all_inbox, cardWidth, 'total'),
              _buildClickableNeumorphicCard('Resolved', resolved, Colors.green, Icons.check_circle, cardWidth, 'resolved'),
              _buildClickableNeumorphicCard('Pending', pending, Colors.orange, Icons.timelapse, cardWidth, 'pending'),
              _buildClickableNeumorphicCard('In Progress', inProgress, Colors.blue, Icons.hourglass_empty, cardWidth, 'inprogress'), // Updated
            ],
          );
        },
      ),
    ];
  }

  Widget _buildShimmerDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for section header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 200,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Shimmer for pie chart
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // Shimmer for bar chart header
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 250,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Shimmer for bar chart
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // Shimmer for cards
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: List.generate(4, (index) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(18),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String text) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Row(
          children: [
            Icon(icon, color: themeProvider.isDarkMode ? Colors.tealAccent : Colors.teal),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClickableNeumorphicCard(
      String title, int count, Color color, IconData icon, double width, String category) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ComplaintDetailsPage(
                  category: category,
                  title: title,
                  color: color,
                  icon: icon,
                ),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width,
            height: 130, // Increased height from 115 to 130
            padding: const EdgeInsets.all(12), // Reduced padding from 14 to 12
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFEFF3FA),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.black54 : Colors.grey.shade300,
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: themeProvider.isDarkMode ? Colors.grey.shade800 : Colors.white,
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Added this to minimize space usage
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8 to 6
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24), // Reduced from 26 to 24
                ),
                const SizedBox(height: 6), // Reduced from 8 to 6
                Text(
                  '$count',
                  style: GoogleFonts.urbanist(
                    fontSize: 20, // Reduced from 22 to 20
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4 to 2
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 11, // Reduced from 12 to 11
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Added overflow handling
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.teal,
            title: Text("Analytics Dashboard", style: GoogleFonts.poppins()),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: fetchComplaintStats,
                tooltip: 'Refresh Data',
              ),
              IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
          body: isLoading
              ? _buildShimmerDashboard()
              : RefreshIndicator(
            onRefresh: fetchComplaintStats,
            child: AnimationLimiter(
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
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: _bottomNavItems,
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
            elevation: 10,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: fetchComplaintStats,
            backgroundColor: Colors.teal,
            child: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
          ),
        );
      },
    );
  }
}
