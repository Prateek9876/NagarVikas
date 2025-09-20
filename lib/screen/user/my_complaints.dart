import 'dart:developer';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/theme_provider.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  MyComplaintsScreenState createState() => MyComplaintsScreenState();
}

class MyComplaintsScreenState extends State<MyComplaintsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];
  TextEditingController searchController = TextEditingController();

  bool _isLoading = true;
  String selectedStatus = 'All';
  Map<int, String> complaintKeys = {};

  late AnimationController _fadeController;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchComplaints();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    DatabaseReference ref = FirebaseDatabase.instance.ref('complaints/');

    ref.orderByChild("user_id").equalTo(userId).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        setState(() {
          complaints = [];
          filteredComplaints = [];
          complaintKeys.clear();
          _isLoading = false;
        });
        _fadeController.forward();
        return;
      }

      List<Map<String, dynamic>> loadedComplaints = [];
      Map<int, String> keys = {};

      int index = 0;
      data.forEach((key, value) {
        final complaint = value as Map<dynamic, dynamic>;

        String rawTimestamp = complaint["timestamp"] ?? "";
        String formattedDate = "Unknown";
        String formattedTime = "Unknown";

        try {
          if (rawTimestamp.isNotEmpty) {
            DateTime dateTime = DateTime.parse(rawTimestamp);
            formattedDate = DateFormat('MMM dd').format(dateTime);
            formattedTime = DateFormat('hh:mm a').format(dateTime);
          }
        } catch (e) {
          log("Error parsing timestamp: $e");
        }

        loadedComplaints.add({
          "issue": complaint["issue_type"]?.toString() ?? "Unknown Issue",
          "status": complaint["status"]?.toString() ?? "Pending",
          "date": formattedDate,
          "time": formattedTime,
          "location": complaint["location"]?.toString() ?? "Not Available",
          "city": complaint["city"]?.toString() ?? "Not Available",
          "state": complaint["state"]?.toString() ?? "Not Available",
        });

        keys[index] = key;
        index++;
      });

      // Sort by most recent first
      loadedComplaints.sort((a, b) => b['date'].compareTo(a['date']));

      setState(() {
        complaints = loadedComplaints;
        complaintKeys = keys;
        _applyFilters();
        _isLoading = false;
      });

      _fadeController.forward();
    });
  }

  Future<void> _deleteComplaint(int index) async {
    try {
      // Show loading
      _scaleController.forward();

      String? complaintKey = complaintKeys[index];
      if (complaintKey != null) {
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref('complaints/$complaintKey')
            .get();

        if (snapshot.exists) {
          Map<String, dynamic> complaintData =
              Map<String, dynamic>.from(snapshot.value as Map);

          // Delete associated images
          if (complaintData.containsKey('images') &&
              complaintData['images'] != null) {
            dynamic images = complaintData['images'];
            List<String> imageUrls = [];

            if (images is String) {
              imageUrls.add(images);
            } else if (images is List) {
              imageUrls = List<String>.from(images);
            }

            for (String imageUrl in imageUrls) {
              try {
                if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
                  await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                }
              } catch (e) {
                log('Error deleting image: $e');
              }
            }
          }

          if (complaintData.containsKey('image') &&
              complaintData['image'] != null) {
            String imageUrl = complaintData['image'].toString();
            try {
              if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
                await FirebaseStorage.instance.refFromURL(imageUrl).delete();
              }
            } catch (e) {
              log('Error deleting single image: $e');
            }
          }
        }

        await FirebaseDatabase.instance
            .ref('complaints/$complaintKey')
            .remove();

        _scaleController.reverse();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Spell removed successfully ✨'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _scaleController.reverse();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing spell: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return AlertDialog(
              backgroundColor:
                  themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.auto_delete_rounded,
                    color: Colors.red[400],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remove Spell?',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Text(
                'This action cannot be undone. Your spell will be permanently removed.',
                style: TextStyle(
                  color: themeProvider.isDarkMode
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Remove'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteComplaint(index);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredComplaints = complaints.where((complaint) {
        final matchesStatus = selectedStatus == 'All' ||
            complaint['status'].toString().toLowerCase() ==
                selectedStatus.toLowerCase();
        final matchesQuery = query.isEmpty ||
            complaint['issue'].toString().toLowerCase().contains(query) ||
            complaint['location'].toString().toLowerCase().contains(query);
        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return const Color(0xFFFF6B6B);
      case "in progress":
        return const Color(0xFFFFB347);
      case "resolved":
        return const Color(0xFF51CF66);
      default:
        return Colors.grey;
    }
  }

  IconData _getComplaintIcon(String issue) {
    final issueLower = issue.toLowerCase();
    if (issueLower.contains("road")) return Icons.construction_rounded;
    if (issueLower.contains("water")) return Icons.water_drop_rounded;
    if (issueLower.contains("drainage")) return Icons.water_rounded;
    if (issueLower.contains("garbage")) return Icons.delete_rounded;
    if (issueLower.contains("stray") || issueLower.contains("animal"))
      return Icons.pets_rounded;
    if (issueLower.contains("streetlight") || issueLower.contains("light"))
      return Icons.lightbulb_rounded;
    return Icons.report_problem_rounded;
  }

  String _getShortIssueText(String issue) {
    if (issue.length <= 30) return issue;
    return '${issue.substring(0, 30)}...';
  }

  Widget _buildShimmerCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Shimmer.fromColors(
            baseColor: themeProvider.isDarkMode
                ? Colors.grey[700]!
                : Colors.grey[300]!,
            highlightColor: themeProvider.isDarkMode
                ? Colors.grey[600]!
                : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[600]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[600]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 20,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[600]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[600]
                          : Colors.white,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              size: 60,
              color: themeProvider.isDarkMode
                  ? Colors.grey[600]
                  : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getNoComplaintsMessage(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedStatus == 'All'
                ? 'Your spells will appear here'
                : 'Try changing the filter',
            style: TextStyle(
              fontSize: 14,
              color: themeProvider.isDarkMode
                  ? Colors.grey[500]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F9FA),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 110,
                floating: false,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false,
                backgroundColor: themeProvider.isDarkMode
                    ? Colors.grey[850]
                    : const Color(0xFF1E88E5),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: themeProvider.isDarkMode
                            ? [
                                Colors.grey[800]!,
                                Colors.grey[700]!,
                                Colors.teal[600]!,
                              ]
                            : [
                                const Color(0xFF1565C0),
                                const Color(0xFF42A5F5),
                                const Color(0xFF04CCF0),
                              ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.auto_stories_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SlideInDown(
                                    child: const Text(
                                      'Spell Records',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                // Theme is controlled by Issue Selection page
                              ],
                            ),
                            const SizedBox(height: 4),
                            SlideInDown(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                '${filteredComplaints.length} spell${filteredComplaints.length != 1 ? 's' : ''} found',
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
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[850]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: (val) => _applyFilters(),
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search spells...',
                              hintStyle: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[850]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: themeProvider.isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(12),
                            items: ['All', 'Pending', 'In Progress', 'Resolved']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children:
                              List.generate(4, (index) => _buildShimmerCard()),
                        ),
                      )
                    : filteredComplaints.isEmpty
                        ? Container(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyState(themeProvider),
                          )
                        : FadeTransition(
                            opacity: _fadeController,
                            child: RefreshIndicator(
                              onRefresh: _fetchComplaints,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: filteredComplaints
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    int index = entry.key;
                                    Map<String, dynamic> complaint =
                                        entry.value;

                                    int originalIndex = complaints.indexWhere(
                                        (c) =>
                                            c['issue'] == complaint['issue'] &&
                                            c['date'] == complaint['date'] &&
                                            c['time'] == complaint['time']);

                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: themeProvider.isDarkMode
                                            ? Colors.grey[850]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: themeProvider.isDarkMode
                                            ? Border.all(
                                                color: Colors.grey[700]!,
                                                width: 0.5,
                                              )
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: themeProvider.isDarkMode
                                                ? Colors.black26
                                                : Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                            complaint['status'])
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Icon(
                                                    _getComplaintIcon(
                                                        complaint['issue']),
                                                    color: _getStatusColor(
                                                        complaint['status']),
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _getShortIssueText(
                                                            complaint['issue']),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: themeProvider
                                                                  .isDarkMode
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .location_on_rounded,
                                                            size: 14,
                                                            color: themeProvider
                                                                    .isDarkMode
                                                                ? Colors
                                                                    .grey[400]
                                                                : Colors
                                                                    .grey[600],
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Expanded(
                                                            child: Text(
                                                              '${complaint['location']}, ${complaint['city']}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: themeProvider
                                                                        .isDarkMode
                                                                    ? Colors.grey[
                                                                        400]
                                                                    : Colors.grey[
                                                                        600],
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(
                                                            complaint[
                                                                'status']),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        complaint['status'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    InkWell(
                                                      onTap: () =>
                                                          _showDeleteDialog(
                                                              originalIndex),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        child: Icon(
                                                          Icons
                                                              .delete_outline_rounded,
                                                          color:
                                                              Colors.red[400],
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: themeProvider.isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[50],
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule_rounded,
                                                    size: 16,
                                                    color:
                                                        themeProvider.isDarkMode
                                                            ? Colors.grey[400]
                                                            : Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${complaint['date']} at ${complaint['time']}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: themeProvider
                                                              .isDarkMode
                                                          ? Colors.grey[300]
                                                          : Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getNoComplaintsMessage() {
    switch (selectedStatus) {
      case 'Pending':
        return 'No Pending Spells';
      case 'In Progress':
        return 'No Active Spells';
      case 'Resolved':
        return 'No Resolved Spells';
      case 'All':
      default:
        return 'No Spells Found';
    }
  }
}
