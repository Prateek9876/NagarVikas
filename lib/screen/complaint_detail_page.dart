import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../service/local_status_storage.dart';
import '../service/notification_service.dart';
import '../theme/theme_provider.dart';
import './admin_dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ComplaintDetailPage extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailPage({super.key, required this.complaintId});

  @override
  State<ComplaintDetailPage> createState() => _ComplaintDetailPageState();
}

class _ComplaintDetailPageState extends State<ComplaintDetailPage> {
  Map<String, dynamic>? complaint;
  late String selectedStatus;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaintDetails();
  }

  Future<void> _fetchComplaintDetails() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('complaints/${widget.complaintId}')
        .get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      // Fetch user data
      String userId = data['user_id'] ?? '';
      final userSnapshot =
      await FirebaseDatabase.instance.ref('users/$userId').get();
      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        data['user_name'] = userData['name'] ?? 'Unknown';
        data['user_email'] = userData['email'] ?? 'N/A';
      } else {
        data['user_name'] = 'Unknown';
        data['user_email'] = 'N/A';
      }

      setState(() {
        complaint = data;
        selectedStatus = data["status"] ?? "Pending";
      });
      _initMedia(data);
    }
  }

  void _initMedia(Map<String, dynamic> data) {
    final type = data["media_type"]?.toLowerCase();
    final url = (data["media_url"] ?? '').toString();

    if (type == "video" && url.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          _videoController!.setVolume(_isMuted ? 0 : 1);
          setState(() => _videoInitialized = true);
        }).catchError((e) {
          debugPrint("Video init failed: $e");
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    await FirebaseDatabase.instance
        .ref('complaints/${widget.complaintId}')
        .update({"status": newStatus});

    // Fetch complaint details for notification
    final snapshot = await FirebaseDatabase.instance
        .ref('complaints/${widget.complaintId}')
        .get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final String userId = data['user_id'] ?? '';
      final String issueType = data['issue_type'] ?? 'Complaint';
      final String status = data['status'] ?? newStatus;

      // Save notification in local storage for user
      await LocalStatusStorage.saveNotification({
        'message':
        'Your $issueType complaint from ${data['city'] ?? 'Unknown City'}, ${data['state'] ?? 'Unknown State'} has been updated to $status.',
        'timestamp': DateTime.now().toIso8601String(),
        'complaint_id': widget.complaintId,
        'status': status,
        'issue_type': issueType,
      });

      // Optionally show a local notification immediately
      await NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Complaint Status Updated',
        body:
        'Your $issueType complaint from ${data['city'] ?? 'Unknown City'}, ${data['state'] ?? 'Unknown State'} is now $status.',
        payload: widget.complaintId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      if (complaint == null) {
        return Scaffold(
          backgroundColor:
          themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
          appBar: AppBar(
            title: Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            backgroundColor: const Color.fromARGB(255, 4, 204, 240),
          ),
          body: _buildDetailShimmer(themeProvider),
        );
      }

      final String mediaType = complaint!["media_type"]?.toLowerCase() ?? "image";
      final String mediaUrl = (complaint!["media_url"] ?? '').toString().isEmpty
          ? 'https://picsum.photos/250?image=9'
          : complaint!["media_url"];

      return Scaffold(
        backgroundColor:
        themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          title: Text(
            complaint!["issue_type"] ?? "Complaint",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Colors.black.withAlpha((0.3 * 255).toInt())
                        : Colors.black.withAlpha((0.1 * 255).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildMediaPreview(mediaType, mediaUrl, themeProvider),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoSection("📍 Location", complaint!["location"], themeProvider),
                  _buildInfoSection("🏙️ City", complaint!["city"], themeProvider),
                  _buildInfoSection("🗺️ State", complaint!["state"], themeProvider),
                  _buildInfoSection("📅 Date & Time",
                      _formatTimestamp(complaint!["timestamp"]), themeProvider),
                  _buildInfoSection("👤 User",
                      "${complaint!["user_name"]} (${complaint!["user_email"]})", themeProvider),
                  _buildInfoSection(
                      "📝 Description", complaint!["description"] ?? "-", themeProvider),
                  const SizedBox(height: 12),
                  Text(
                    "🔄 Update Status",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: const Color.fromARGB(255, 4, 204, 240),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: themeProvider.isDarkMode
                          ? Colors.grey[700]
                          : Colors.grey.shade100,
                    ),
                    dropdownColor: themeProvider.isDarkMode
                        ? Colors.grey[700]
                        : Colors.white,
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                    items: ["Pending", "In Progress", "Resolved"]
                        .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        )))
                        .toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        _updateStatus(newStatus);
                        setState(() {
                          selectedStatus = newStatus;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 🔴 Delete Button
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        backgroundColor: themeProvider.isDarkMode
                            ? Colors.red.withAlpha((0.1 * 255).toInt())
                            : Colors.red.withAlpha((0.05 * 255).toInt()),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => Consumer<ThemeProvider>(
                            builder: (context, themeProvider, child) => AlertDialog(
                              backgroundColor: themeProvider.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              title: Text(
                                "Confirm Deletion",
                                style: TextStyle(
                                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              content: Text(
                                "Are you sure you want to delete this complaint?",
                                style: TextStyle(
                                  color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "No",
                                    style: TextStyle(
                                      color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final navigator = Navigator.of(context);
                                    Navigator.pop(context); // Close dialog

                                    await FirebaseDatabase.instance
                                        .ref('complaints/${widget.complaintId}')
                                        .remove();

                                    if (!mounted) return;
                                    navigator.pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) => AdminDashboard()),
                                    );
                                    Fluttertoast.showToast(
                                        msg: "Deleted Successfully!");
                                  },
                                  child: const Text("Yes",
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDetailShimmer(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? Colors.black.withAlpha((0.3 * 255).toInt())
                  : Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image shimmer
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16), // Reduced from 20

            // Info sections shimmer
            ...List.generate(
              6,
                  (index) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced from 8
                  Container(
                    width: double.infinity,
                    height: 40, // Reduced from 48
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 14
                ],
              ),
            ),

            // Dropdown shimmer
            Container(
              width: double.infinity,
              height: 40, // Reduced from 48
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Add extra space at bottom to account for navigation/overflow
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoSection(String title, String? value, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey[700]
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: themeProvider.isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey.shade200,
              ),
            ),
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontSize: 15,
                color: themeProvider.isDarkMode ? Colors.grey[100] : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(String type, String url, ThemeProvider themeProvider) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.isAbsolute) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: 100,
          color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400],
        ),
      );
    }

    if (type == "video") {
      if (_videoController != null && _videoInitialized) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),

            // Center play/pause button
            Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _videoController!.value.isPlaying
                        ? _videoController!.pause()
                        : _videoController!.play();
                  });
                },
              ),
            ),

            // Bottom-right mute toggle
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isMuted = !_isMuted;
                      _videoController!.setVolume(_isMuted ? 0 : 1);
                    });
                  },
                ),
              ),
            ),
          ],
        );
      } else {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: const Color.fromARGB(255, 4, 204, 240),
            ),
          ),
        );
      }
    }

    return Image.network(
      url,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: const Color.fromARGB(255, 4, 204, 240),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Image load failed: $error");
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.broken_image,
            size: 100,
            color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400],
          ),
        );
      },
    );
  }

  String _formatTimestamp(String? isoTimestamp) {
    if (isoTimestamp == null) return "-";
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      return dt.toLocal().toString().split('.')[0];
    } catch (_) {
      return isoTimestamp;
    }
  }
}
