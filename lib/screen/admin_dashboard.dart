// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/theme_provider.dart';
import 'complaint_detail_page.dart';
import 'favourites.dart';
import 'login_page.dart';
import 'package:nagarvikas/screen/analytics_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // Home is selected by default
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int inProgressComplaints = 0;
  int resolvedComplaints = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];
  TextEditingController searchController = TextEditingController();
  StreamSubscription? _complaintsSubscription;

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
    _fetchComplaints();
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    DatabaseReference complaintsRef =
    FirebaseDatabase.instance.ref('complaints');
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');

    _complaintsSubscription =
        complaintsRef.onValue.listen((complaintEvent) async {
          if (!mounted) return;

          final complaintData =
          complaintEvent.snapshot.value as Map<dynamic, dynamic>?;

          if (complaintData == null) {
            if (mounted) {
              setState(() {
                totalComplaints = pendingComplaints =
                    inProgressComplaints = resolvedComplaints = 0;
                complaints = [];
                filteredComplaints = [];
                isLoading = false;
              });
            }
            return;
          }

          List<Map<String, dynamic>> loadedComplaints = [];
          int pending = 0, inProgress = 0, resolved = 0, total = 0;

          for (var entry in complaintData.entries) {
            final complaint = entry.value as Map<dynamic, dynamic>;
            String userId = complaint["user_id"] ?? "Unknown";

            DataSnapshot userSnapshot = await usersRef.child(userId).get();
            Map<String, dynamic>? userData = userSnapshot.value != null
                ? Map<String, dynamic>.from(userSnapshot.value as Map)
                : null;

            String status = complaint["status"]?.toString() ?? "Pending";
            if (status == "Pending") pending++;
            if (status == "In Progress") inProgress++;
            if (status == "Resolved") resolved++;
            total++;

            String timestamp = complaint["timestamp"] ?? "Unknown";
            String date = "Unknown", time = "Unknown";

            if (timestamp != "Unknown") {
              DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
              date = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
              time = "${dateTime.hour}:${dateTime.minute}";
            }

            String? mediaUrl =
                complaint["media_url"] ?? complaint["image_url"] ?? "";
            String mediaType = (complaint["media_type"] ??
                (complaint["image_url"] != null ? "image" : "video"))
                .toString()
                .toLowerCase();

            loadedComplaints.add({
              "id": entry.key,
              "issue_type": complaint["issue_type"] ?? "Unknown",
              "city": complaint["city"] ?? "Unknown",
              "state": complaint["state"] ?? "Unknown",
              "location": complaint["location"] ?? "Unknown",
              "description": complaint["description"] ?? "No description",
              "date": date,
              "time": time,
              "status": status,
              "media_url": (mediaUrl ?? '').isEmpty
                  ? 'https://picsum.photos/250?image=9'
                  : mediaUrl,
              "media_type": mediaType,
              "user_id": userId,
              "user_name": userData?["name"] ?? "Unknown",
              "user_email": userData?["email"] ?? "Unknown",
            });
          }

          if (mounted) {
            setState(() {
              totalComplaints = total;
              pendingComplaints = pending;
              inProgressComplaints = inProgress;
              resolvedComplaints = resolved;
              complaints = loadedComplaints;
              filteredComplaints = complaints;
              isLoading = false;
            });
          }
        });
  }

  void _searchComplaints(String query) {
    setState(() {
      filteredComplaints = complaints.where((complaint) {
        return complaint.values.any((value) =>
            value.toString().toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  Route _createSlideRoute(Map<String, dynamic> complaint) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ComplaintDetailPage(complaintId: complaint["id"]),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // Handle bottom navigation item tap
  void _onItemTapped(int index) {
    if (index == 1) {
      // Analytics
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnalyticsDashboard()),
      );
    } else if (index == 2) {
      // Logout
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF66BCF1), Color(0xFF3A8EDB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              width: double.infinity,
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                    ),
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'amritsar.gov@gmail.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.analytics, color: Colors.teal),
              title: Text(
                'Analytics',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const AnalyticsDashboard(),
                ));
              },
            ),
            const Divider(thickness: 1),
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.red),
              title: Text(
                'Favorites',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => FavoritesPage(
                    favoriteComplaints: favoriteComplaints,
                    onRemoveFavorite: _removeFavoriteFromDashboard,
                  ),
                ));
                setState(() {});
              },
            ),
            const Divider(thickness: 1),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text("Confirm Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          "Logout",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00BCD4),
                Color(0xFF0097A7),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Admin Dashboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Manage complaints & track issues",
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 50),
              onSelected: (value) async {
                if (value == 'logout') {
                  _showLogoutDialog();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF00BCD4),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? Container(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () {
                        searchController.clear();
                        _searchComplaints('');
                      },
                      child: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                    ),
                  )
                      : null,
                  hintText: "Search complaints...",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  isDense: false,
                ),
                cursorColor: const Color(0xFF4CAF50),
                cursorWidth: 2,
                cursorHeight: 20,
                onChanged: _searchComplaints,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? _buildShimmerList()
                  : filteredComplaints.isEmpty
                  ? const Center(child: Text("No complaints found."))
                  : ListView.builder(
                itemCount: filteredComplaints.length,
                itemBuilder: (ctx, index) {
                  final complaint = filteredComplaints[index];
                  final complaintId = complaint["id"] ?? complaint.hashCode.toString();
                  final isFavorite = favoriteComplaints.any((fav) =>
                  (fav["id"] ?? fav.hashCode.toString()) == complaintId);
                  return ComplaintCard(
                    complaint: complaint,
                    isFavorite: isFavorite,
                    onFavoriteToggle: () => _toggleFavorite(complaint),
                    onTap: () => Navigator.of(context).push(
                      _createSlideRoute(complaint),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        elevation: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in progress':
        return const Color(0xFF2196F3);
      case 'resolved':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFE57373);
      default:
        return Colors.grey[600]!;
    }
  }

  List<Map<String, dynamic>> favoriteComplaints = [];

  void _toggleFavorite(Map<String, dynamic> complaint) {
    setState(() {
      final complaintId = complaint["id"] ?? complaint.hashCode.toString();
      final existingIndex = favoriteComplaints.indexWhere((fav) =>
      (fav["id"] ?? fav.hashCode.toString()) == complaintId);

      if (existingIndex >= 0) {
        // Remove from favorites
        favoriteComplaints.removeAt(existingIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Add to favorites
        favoriteComplaints.add(complaint);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to favorites'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _removeFavoriteFromDashboard(Map<String, dynamic> complaint) {
    setState(() {
      final complaintId = complaint["id"] ?? complaint.hashCode.toString();
      favoriteComplaints.removeWhere((fav) =>
      (fav["id"] ?? fav.hashCode.toString()) == complaintId);
    });
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const ComplaintCard({
    Key? key,
    required this.complaint,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ComplaintDetailPage(complaintId: complaint["id"]),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Modern media preview
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: complaint["media_type"] == "image"
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      complaint["media_url"],
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.grey[500],
                              size: 24,
                            ),
                          ),
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Content section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and favorite row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              complaint["issue_type"] ?? "Unknown Issue",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (onFavoriteToggle != null)
                            GestureDetector(
                              onTap: onFavoriteToggle,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFavorite
                                      ? const Color(0xFFE57373)
                                      : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(complaint["status"]).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          complaint["status"] ?? "Unknown",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getStatusColor(complaint["status"]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location info
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "${complaint["city"] ?? "Unknown"}, ${complaint["state"] ?? "Unknown"}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in progress':
        return const Color(0xFF2196F3);
      case 'resolved':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFE57373);
      default:
        return Colors.grey[600]!;
    }
  }
}
