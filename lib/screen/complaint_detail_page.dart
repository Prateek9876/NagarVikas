import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';
import './admin_dashboard.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nagarvikas/localization/app_localizations.dart';

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
        selectedStatus =
            data["status"] ?? AppLocalizations.of(context).get("pending");
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

  void _updateStatus(String newStatus) {
    FirebaseDatabase.instance
        .ref('complaints/${widget.complaintId}')
        .update({"status": newStatus});
  }

  @override
  Widget build(BuildContext context) {
    if (complaint == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String mediaType = complaint!["media_type"]?.toLowerCase() ?? "image";
    final String mediaUrl = (complaint!["media_url"] ?? '').toString().isEmpty
        ? 'https://picsum.photos/250?image=9'
        : complaint!["media_url"];

    return Scaffold(
      appBar: AppBar(
        title: Text(complaint!["issue_type"] ??
            AppLocalizations.of(context).get("complaint")),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.1 * 255).toInt()),
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
                  child: _buildMediaPreview(mediaType, mediaUrl),
                ),
                const SizedBox(height: 20),
                _buildInfoSection(AppLocalizations.of(context).get("location"),
                    complaint!["location"]),
                _buildInfoSection(AppLocalizations.of(context).get("cityTitle"),
                    complaint!["city"]),
                _buildInfoSection(
                    AppLocalizations.of(context).get("stateTitle"),
                    complaint!["state"]),
                _buildInfoSection(
                    AppLocalizations.of(context).get("dateAndTime"),
                    _formatTimestamp(complaint!["timestamp"])),
                _buildInfoSection(AppLocalizations.of(context).get("user"),
                    "${complaint!["user_name"]} (${complaint!["user_email"]})"),
                _buildInfoSection(
                    AppLocalizations.of(context).get("description"),
                    complaint!["description"] ?? "-"),
                const SizedBox(height: 12),
                Text(AppLocalizations.of(context).get("updateStatus"),
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  items: [
                    AppLocalizations.of(context).get("pending"),
                    AppLocalizations.of(context).get("inProgress"),
                    AppLocalizations.of(context).get("resolved")
                  ]
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
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
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(AppLocalizations.of(context).get("delete")),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)
                              .get("confirmDeletion")),
                          content: Text(AppLocalizations.of(context)
                              .get("areYouSureDeleteComplaint")),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context), // Close dialog
                              child:
                                  Text(AppLocalizations.of(context).get("no")),
                            ),
                            TextButton(
                              onPressed: () async {
                                final navigator = Navigator.of(
                                    context); // ✅ capture the safe context *before* popping

                                Navigator.pop(context); // Close dialog

                                await FirebaseDatabase.instance
                                    .ref('complaints/${widget.complaintId}')
                                    .remove();

                                if (!mounted) return;
                                // ✅ Now use the saved navigator to push replacement
                                navigator.pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => AdminDashboard()),
                                );
                                Fluttertoast.showToast(
                                    msg: AppLocalizations.of(context)
                                        .get("deletedSuccessfully"));
                              },
                              child: Text(
                                  AppLocalizations.of(context).get("yes"),
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
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
  }

  Widget _buildInfoSection(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(String type, String url) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.isAbsolute) {
      return const Icon(Icons.image_not_supported, size: 100);
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
        return const SizedBox(
            height: 200, child: Center(child: CircularProgressIndicator()));
      }
    }

    return Image.network(
      url,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Image load failed: $error");
        return const Icon(Icons.broken_image, size: 100);
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
