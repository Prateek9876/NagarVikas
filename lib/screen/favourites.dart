import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/theme_provider.dart';
import 'complaint_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  final List<Map<String, dynamic>> favoriteComplaints;
  final Function(Map<String, dynamic>)? onRemoveFavorite;

  const FavoritesPage({Key? key, required this.favoriteComplaints, this.onRemoveFavorite}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {

  void _removeFavorite(int index) {
    final complaint = widget.favoriteComplaints[index];
    setState(() {
      widget.favoriteComplaints.removeAt(index);
    });
    if (widget.onRemoveFavorite != null) {
      widget.onRemoveFavorite!(complaint);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed from favorites'),
        backgroundColor: Colors.grey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : const Color(0xFFF0F9FF),
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
                  "Favorite Complaints",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Your saved complaints",
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          body: widget.favoriteComplaints.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No favorite complaints yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the heart icon on complaints to add them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: widget.favoriteComplaints.length,
              itemBuilder: (context, index) {
                final complaint = widget.favoriteComplaints[index];
                return RealTimeComplaintCard(
                  complaintId: complaint["id"] ?? complaint.hashCode.toString(),
                  isFavorite: true, // Always true in favorites page
                  onFavoriteToggle: () => _removeFavorite(index),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintDetailPage(complaintId: complaint["id"]),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class RealTimeComplaintCard extends StatefulWidget {
  final String complaintId;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const RealTimeComplaintCard({
    Key? key,
    required this.complaintId,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  }) : super(key: key);

  @override
  State<RealTimeComplaintCard> createState() => _RealTimeComplaintCardState();
}

class _RealTimeComplaintCardState extends State<RealTimeComplaintCard> {
  Map<String, dynamic>? complaint;
  StreamSubscription? _subscription;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupRealTimeListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _setupRealTimeListener() {
    DatabaseReference complaintRef = FirebaseDatabase.instance.ref('complaints/${widget.complaintId}');
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');

    _subscription = complaintRef.onValue.listen((event) async {
      if (!mounted) return;

      final complaintData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (complaintData != null) {
        String userId = complaintData["user_id"] ?? "Unknown";

        DataSnapshot userSnapshot = await usersRef.child(userId).get();
        Map<String, dynamic>? userData = userSnapshot.value != null
            ? Map<String, dynamic>.from(userSnapshot.value as Map)
            : null;

        String timestamp = complaintData["timestamp"] ?? "Unknown";
        String date = "Unknown", time = "Unknown";

        if (timestamp != "Unknown") {
          DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
          date = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
          time = "${dateTime.hour}:${dateTime.minute}";
        }

        String? mediaUrl = complaintData["media_url"] ?? complaintData["image_url"] ?? "";
        String mediaType = (complaintData["media_type"] ??
            (complaintData["image_url"] != null ? "image" : "video"))
            .toString()
            .toLowerCase();

        setState(() {
          complaint = {
            "id": widget.complaintId,
            "issue_type": complaintData["issue_type"] ?? "Unknown",
            "city": complaintData["city"] ?? "Unknown",
            "state": complaintData["state"] ?? "Unknown",
            "location": complaintData["location"] ?? "Unknown",
            "description": complaintData["description"] ?? "No description",
            "date": date,
            "time": time,
            "status": complaintData["status"] ?? "Pending",
            "media_url": (mediaUrl ?? '').isEmpty
                ? 'https://picsum.photos/250?image=9'
                : mediaUrl,
            "media_type": mediaType,
            "user_id": userId,
            "user_name": userData?["name"] ?? "Unknown",
            "user_email": userData?["email"] ?? "Unknown",
          };
          isLoading = false;
        });
      } else {
        setState(() {
          complaint = null;
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
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
                            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
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
      );
    }

    if (complaint == null) {
      return SizedBox.shrink();
    }

    return ComplaintCard(
      complaint: complaint!,
      isFavorite: widget.isFavorite,
      onFavoriteToggle: widget.onFavoriteToggle,
      onTap: widget.onTap,
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: themeProvider.isDarkMode ? Colors.black26 : Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: themeProvider.isDarkMode ? Colors.black12 : Colors.black.withAlpha(5),
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
                        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[100],
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
                                  color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
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
                                          : (themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400]),
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
                                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${complaint["city"] ?? "Unknown"}, ${complaint["state"] ?? "Unknown"}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
