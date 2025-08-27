import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/theme_provider.dart';
import 'complaint_detail_page.dart';
import 'discussion/discussion.dart';
import 'admin_drawer.dart'; // Import the drawer component

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int inProgressComplaints = 0;
  int resolvedComplaints = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];
  TextEditingController searchController = TextEditingController();
  String selectedStatus = 'All';
  StreamSubscription? _complaintsSubscription;

  // Enhanced animation controllers
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardOpacityAnimation;
  late AnimationController _headerAnimationController;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerOpacityAnimation;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchScaleAnimation;
  late Animation<double> _searchOpacityAnimation;
  late AnimationController _listAnimationController;
  late Animation<double> _listOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchComplaints();
    _startInitialAnimations();
  }

  void _initializeAnimations() {
    // FAB animation controller
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Card animation controller
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Header animation controller
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));
    _headerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Search animation controller
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _searchScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _searchOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // List animation controller
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _listOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  void _startInitialAnimations() {
    // Start header animation immediately
    _headerAnimationController.forward();

    // Start search animation after a short delay
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) _searchAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    searchController.dispose();
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
    _headerAnimationController.dispose();
    _searchAnimationController.dispose();
    _listAnimationController.dispose();
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
          // Start list animation when loading is complete
          _listAnimationController.forward();
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

        // Start card and list animations when data is loaded
        _cardAnimationController.forward();
        _listAnimationController.forward();
      }
    });
  }

  void _searchComplaints(String query) {
    _applyFilters();
  }

  void _applyFilters() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredComplaints = complaints.where((complaint) {
        final matchesStatus = selectedStatus == 'All' ||
            complaint['status'].toString().toLowerCase() ==
                selectedStatus.toLowerCase();
        final matchesQuery = query.isEmpty ||
            complaint.values.any((value) =>
                value.toString().toLowerCase().contains(query));
        return matchesStatus && matchesQuery;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDarkMode = themeProvider.isDarkMode;

        return Scaffold(
          drawer: AdminDrawer(
            favoriteComplaints: favoriteComplaints,
            onRemoveFavorite: _removeFavoriteFromDashboard,
          ),
          backgroundColor: isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F9FA),
          appBar: _buildAnimatedAppBar(isDarkMode, themeProvider),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDarkMode
                    ? [Colors.grey[900]!, Colors.grey[850]!]
                    : [const Color(0xFFF8F9FA), const Color(0xFFFFFFFF)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Animated Search and Filter Section
                  _buildAnimatedSearchSection(isDarkMode),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _listAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _listOpacityAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - _listOpacityAnimation.value) * 20),
                            child: _buildComplaintsList(isDarkMode),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          floatingActionButton: _buildAnimatedFAB(isDarkMode),
        );
      },
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar(bool isDarkMode, ThemeProvider themeProvider) {
    return AppBar(
      toolbarHeight: 80,
      elevation: 0,
      flexibleSpace: AnimatedBuilder(
        animation: _headerAnimationController,
        builder: (context, child) {
          return SlideTransition(
            position: _headerSlideAnimation,
            child: FadeTransition(
              opacity: _headerOpacityAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [Colors.teal, Colors.teal[300]!]
                        : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDarkMode ? Colors.teal : const Color(0xFF1565C0)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      title: AnimatedBuilder(
        animation: _headerAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _headerOpacityAnimation,
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 600 + (100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Admin Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Manage complaints & track issues",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _headerOpacityAnimation,
              child: Transform.translate(
                offset: Offset(30 * (1 - _headerOpacityAnimation.value), 0),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedSearchSection(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _searchAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _searchScaleAnimation.value,
          child: Opacity(
            opacity: _searchOpacityAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Field with enhanced animation
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 700 + 200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[750] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.search_rounded,
                              color: isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                              size: 20,
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
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                                size: 18,
                              ),
                            ),
                          )
                              : null,
                          hintText: "Search complaints...",
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        cursorColor: isDarkMode ? Colors.teal : const Color(0xFF1565C0),
                        onChanged: _searchComplaints,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Dropdown with animation
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 700 + 400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[750] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                            size: 24,
                          ),
                          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          items: ['All', 'Pending', 'In Progress', 'Resolved']
                              .map((status) => DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getFilterStatusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  status,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStatus = value;
                              });
                              _applyFilters();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComplaintsList(bool isDarkMode) {
    if (isLoading) {
      return _buildShimmerList();
    }

    if (filteredComplaints.isEmpty) {
      return Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[800]?.withOpacity(0.5)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "No complaints found",
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try adjusting your search or filter criteria",
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredComplaints.length,
      itemBuilder: (ctx, index) {
        final complaint = filteredComplaints[index];
        final complaintId = complaint["id"] ?? complaint.hashCode.toString();
        final isFavorite = favoriteComplaints.any(
            (fav) => (fav["id"] ?? fav.hashCode.toString()) == complaintId);

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100).clamp(0, 500)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: ComplaintCard(
            complaint: complaint,
            isFavorite: isFavorite,
            onFavoriteToggle: () => _toggleFavorite(complaint),
            onTap: () => Navigator.of(context).push(
              _createSlideRoute(complaint),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedFAB(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _fabScaleAnimation,
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: _fabScaleAnimation.value * value,
              child: Transform.rotate(
                angle: (1 - value) * 0.5,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.teal, Colors.teal[300]!]
                    : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDarkMode ? Colors.teal : const Color(0xFF1565C0)).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                _fabAnimationController.forward().then((_) {
                  _fabAnimationController.reverse();
                });
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const DiscussionForum(isAdmin: true),
                ));
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.forum_rounded, color: Colors.white, size: 26),
              tooltip: 'Discussion Forum',
            ),
          ),
        );
      },
    );
  }

  Color _getFilterStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in progress':
        return const Color(0xFF2196F3);
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'all':
        return Colors.grey[500]!;
      default:
        return Colors.grey[500]!;
    }
  }

  List<Map<String, dynamic>> favoriteComplaints = [];

  void _toggleFavorite(Map<String, dynamic> complaint) {
    setState(() {
      final complaintId = complaint["id"] ?? complaint.hashCode.toString();
      final existingIndex = favoriteComplaints.indexWhere(
          (fav) => (fav["id"] ?? fav.hashCode.toString()) == complaintId);

      if (existingIndex >= 0) {
        // Remove from favorites
        favoriteComplaints.removeAt(existingIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.heart_broken, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Removed from favorites', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Add to favorites
        favoriteComplaints.add(complaint);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Added to favorites', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _removeFavoriteFromDashboard(Map<String, dynamic> complaint) {
    setState(() {
      final complaintId = complaint["id"] ?? complaint.hashCode.toString();
      favoriteComplaints.removeWhere(
          (fav) => (fav["id"] ?? fav.hashCode.toString()) == complaintId);
    });
  }

  Widget _buildShimmerList() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: 6,
          itemBuilder: (context, index) => TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[700]!
                      : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Animated shimmer container
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 1500),
                      tween: Tween(begin: 0.3, end: 0.7),
                      builder: (context, value, child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 1500),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                (themeProvider.isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!).withOpacity(value),
                                (themeProvider.isDarkMode
                                    ? Colors.grey[600]!
                                    : Colors.grey[200]!).withOpacity(value),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Animated shimmer bars
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1500),
                            tween: Tween(begin: 0.3, end: 0.7),
                            builder: (context, value, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 1500),
                                height: 18,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (themeProvider.isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!).withOpacity(value),
                                      (themeProvider.isDarkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[200]!).withOpacity(value),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1800),
                            tween: Tween(begin: 0.3, end: 0.7),
                            builder: (context, value, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 1800),
                                height: 14,
                                width: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (themeProvider.isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!).withOpacity(value),
                                      (themeProvider.isDarkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[200]!).withOpacity(value),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 2100),
                            tween: Tween(begin: 0.3, end: 0.7),
                            builder: (context, value, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 2100),
                                height: 14,
                                width: 150,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (themeProvider.isDarkMode
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!).withOpacity(value),
                                      (themeProvider.isDarkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[200]!).withOpacity(value),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
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
      },
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap ??
                      () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ComplaintDetailPage(complaintId: complaint["id"]),
                            ),
                          ),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Enhanced media preview with animation
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Transform.rotate(
                                angle: (1 - value) * 0.1,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: complaint["media_type"] == "image"
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      complaint["media_url"],
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue[400]!.withOpacity(0.2),
                                          Colors.blue[600]!.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.videocam_rounded,
                                      color: Colors.blue[600],
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Enhanced content section with staggered animations
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and favorite row with animation
                              Row(
                                children: [
                                  Expanded(
                                    child: TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 400),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(20 * (1 - value), 0),
                                          child: Opacity(
                                            opacity: value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        complaint["issue_type"] ?? "Unknown Issue",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                                          height: 1.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (onFavoriteToggle != null)
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 500),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: 0.7 + (0.3 * value),
                                          child: Transform.rotate(
                                            angle: (1 - value) * 0.5,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: GestureDetector(
                                        onTap: onFavoriteToggle,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isFavorite
                                                ? const Color(0xFFE57373).withOpacity(0.2)
                                                : (isDarkMode ? Colors.grey[700] : Colors.grey[100]),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: Icon(
                                              isFavorite
                                                  ? Icons.favorite_rounded
                                                  : Icons.favorite_border_rounded,
                                              key: ValueKey(isFavorite),
                                              color: isFavorite
                                                  ? const Color(0xFFE57373)
                                                  : (isDarkMode ? Colors.grey[400] : Colors.grey[500]),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Enhanced status badge with animation
                              Row(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 600),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(15 * (1 - value), 0),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _getStatusColor(complaint["status"]).withOpacity(0.2),
                                            _getStatusColor(complaint["status"]).withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _getStatusColor(complaint["status"]).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            duration: const Duration(milliseconds: 1000),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, value, child) {
                                              return Transform.scale(
                                                scale: value,
                                                child: Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(complaint["status"]),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            complaint["status"] ?? "Unknown",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _getStatusColor(complaint["status"]),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 700),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      "${complaint["date"] ?? "Unknown"} • ${complaint["time"] ?? "Unknown"}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Enhanced location info with animation
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 800),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(10 * (1 - value), 0),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[750]?.withOpacity(0.5)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(milliseconds: 1200),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: 0.5 + (0.5 * value),
                                            child: Transform.rotate(
                                              angle: (1 - value) * 6.28,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.teal.withOpacity(0.2)
                                                : const Color(0xFF1565C0).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.location_on_rounded,
                                            size: 14,
                                            color: isDarkMode ? Colors.teal[300] : const Color(0xFF1565C0),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "${complaint["city"] ?? "Unknown"}, ${complaint["state"] ?? "Unknown"}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                            height: 1.3,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(milliseconds: 1000),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(5 * (1 - value), 0),
                                            child: Opacity(
                                              opacity: value,
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                        ),
                                      ),
                                    ],
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
          ),
        );
      },
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
