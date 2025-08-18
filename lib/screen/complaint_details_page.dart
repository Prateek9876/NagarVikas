import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import 'complaint_detail_page.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final String category; // 'total', 'resolved', 'pending', 'inprogress'
  final String title;
  final Color color;
  final IconData icon;

  const ComplaintDetailsPage({
    super.key,
    required this.category,
    required this.title,
    required this.color,
    required this.icon,
  });

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> totalComplaints = [];
  List<Map<String, dynamic>> resolvedComplaints = [];
  List<Map<String, dynamic>> pendingComplaints = [];
  List<Map<String, dynamic>> inProgressComplaints =
      []; // Changed from rejectedComplaints

  final List<String> categories = [
    'Total',
    'Resolved',
    'Pending',
    'In Progress'
  ]; // Updated
  final List<Color> categoryColors = [
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.blue
  ]; // Updated colors
  final List<IconData> categoryIcons = [
    Icons.all_inbox,
    Icons.check_circle,
    Icons.timelapse,
    Icons.hourglass_empty
  ]; // Updated icon

  @override
  void initState() {
    super.initState();
    _setInitialPage();
    fetchComplaintsByCategory();
  }

  void _setInitialPage() {
    // Set initial page based on the category passed
    switch (widget.category.toLowerCase()) {
      case 'total':
        _currentPage = 0;
        break;
      case 'resolved':
        _currentPage = 1;
        break;
      case 'pending':
        _currentPage = 2;
        break;
      case 'inprogress': // Updated to match the analytics dashboard
        _currentPage = 3;
        break;
    }
    _pageController = PageController(initialPage: _currentPage);
  }

  Future<void> fetchComplaintsByCategory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final complaintsRef = FirebaseDatabase.instance.ref('complaints');
      final usersRef = FirebaseDatabase.instance.ref('users');
      final snapshot = await complaintsRef.get();

      if (snapshot.exists) {
        List<Map<String, dynamic>> total = [];
        List<Map<String, dynamic>> resolved = [];
        List<Map<String, dynamic>> pending = [];
        List<Map<String, dynamic>> inProgress = []; // Changed from rejected

        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in data.entries) {
          final complaint = Map<String, dynamic>.from(entry.value);
          String userId = complaint["user_id"] ?? "Unknown";

          // Fetch user data
          DataSnapshot userSnapshot = await usersRef.child(userId).get();
          Map<String, dynamic>? userData = userSnapshot.value != null
              ? Map<String, dynamic>.from(userSnapshot.value as Map)
              : null;

          String status = (complaint["status"] ?? "Pending").toString();
          String timestamp = complaint["timestamp"] ?? "Unknown";
          String date = "Unknown", time = "Unknown";

          if (timestamp != "Unknown") {
            DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
            date = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
            time =
                "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
          }

          String? mediaUrl =
              complaint["media_url"] ?? complaint["image_url"] ?? "";
          String mediaType = (complaint["media_type"] ??
                  (complaint["image_url"] != null ? "image" : "video"))
              .toString()
              .toLowerCase();

          Map<String, dynamic> complaintData = {
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
          };

          // Add to total
          total.add(complaintData);

          // Categorize by status - Updated logic
          switch (status.toLowerCase()) {
            case 'resolved':
            case 'completed':
              resolved.add(complaintData);
              break;
            case 'pending':
              pending.add(complaintData);
              break;
            case 'in progress': // This is the main change - properly categorize in progress
              inProgress.add(complaintData);
              break;
            // Removed rejected/cancelled cases since we're not tracking them anymore
          }
        }

        setState(() {
          totalComplaints = total;
          resolvedComplaints = resolved;
          pendingComplaints = pending;
          inProgressComplaints = inProgress; // Updated
          isLoading = false;
        });
      } else {
        setState(() {
          totalComplaints = [];
          resolvedComplaints = [];
          pendingComplaints = [];
          inProgressComplaints = []; // Updated
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching complaints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getComplaintsForCategory(int index) {
    switch (index) {
      case 0:
        return totalComplaints;
      case 1:
        return resolvedComplaints;
      case 2:
        return pendingComplaints;
      case 3:
        return inProgressComplaints; // Updated
      default:
        return [];
    }
  }

  // Status color function similar to AdminDashboard
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

  // Create slide route for navigation
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode
            ? Colors.grey[900]
            : const Color(0xFFF2F7FF),
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: Text(
            'Complaint Details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: fetchComplaintsByCategory,
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        body: isLoading
            ? _buildComplaintsShimmer()
            : Column(
                children: [
                  // Category Selection Header (Not Swipeable)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(categories.length, (index) {
                        bool isSelected = _currentPage == index;
                        List<Map<String, dynamic>> complaints =
                            _getComplaintsForCategory(index);

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? categoryColors[index]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: categoryColors[index]
                                              .withAlpha(76),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcons[index],
                                    color: isSelected
                                        ? Colors.white
                                        : categoryColors[index],
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${complaints.length}',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : categoryColors[index],
                                    ),
                                  ),
                                  Text(
                                    categories[index],
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : categoryColors[index],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Page Indicator
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(categories.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 4,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? categoryColors[_currentPage]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Swipeable Content Area
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: categories.length,
                      itemBuilder: (context, pageIndex) {
                        List<Map<String, dynamic>> complaints =
                            _getComplaintsForCategory(pageIndex);
                        return _buildComplaintsList(complaints, pageIndex);
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: fetchComplaintsByCategory,
          backgroundColor: Colors.teal,
          child: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      );
    });
  }

  Widget _buildComplaintsShimmer() {
    return Column(
      children: [
        // Header shimmer
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(
                4,
                (index) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        height: 80,
                      ),
                    )),
          ),
        ),

        // Page indicator shimmer
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                4,
                (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
          ),
        ),

        // List shimmer
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintsList(
      List<Map<String, dynamic>> complaints, int categoryIndex) {
    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: categoryColors[categoryIndex].withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcons[categoryIndex],
                size: 48,
                color: categoryColors[categoryIndex].withAlpha(128),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${categories[categoryIndex].toLowerCase()} complaints found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh and check for updates',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchComplaintsByCategory,
      color: categoryColors[categoryIndex],
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: _buildComplaintCard(complaints[index], categoryIndex),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildComplaintCard(
      Map<String, dynamic> complaint, int categoryIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(complaint["status"]).withAlpha(51),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(_createSlideRoute(complaint));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Media preview
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color:
                            _getStatusColor(complaint["status"]).withAlpha(25),
                      ),
                      child: complaint["media_type"] == "image"
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                complaint["media_url"],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.broken_image_rounded,
                                  color: _getStatusColor(complaint["status"]),
                                  size: 24,
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
                    const SizedBox(width: 12),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint["issue_type"] ?? "Unknown Issue",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${complaint["city"]}, ${complaint["state"]}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status badge with proper color
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            _getStatusColor(complaint["status"]).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(complaint["status"])
                              .withAlpha(76),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        complaint["status"] ?? "Unknown",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(complaint["status"]),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  complaint["description"] ?? "No description",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Footer info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          complaint["user_name"] ?? "Unknown",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          "${complaint["date"]} ${complaint["time"]}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
