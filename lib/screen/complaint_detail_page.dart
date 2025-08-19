import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';
import '../service/local_status_storage.dart';
import '../service/notification_service.dart';
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
  bool _loading = true;

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
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('complaints/${widget.complaintId}')
          .get();

      if (!snapshot.exists) {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        return;
      }

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
      final userId = (data['user_id'] ?? '').toString();
      if (userId.isNotEmpty) {
        final userSnapshot =
            await FirebaseDatabase.instance.ref('users/$userId').get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          data['user_name'] = userData['name'] ?? 'Unknown';
          data['user_email'] = userData['email'] ?? 'N/A';
        }
      }
      data['user_name'] ??= 'Unknown';
      data['user_email'] ??= 'N/A';

      setState(() {
        complaint = data;
        selectedStatus = data["status"]?.toString() ?? "Pending";
        _loading = false;
      });

      _initMedia(data);
    } catch (e) {
      debugPrint("Fetch details failed: $e");
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _initMedia(Map<String, dynamic> data) {
    final type = data["media_type"]?.toString().toLowerCase();
    final url = (data["media_url"] ?? '').toString();

    if (type == "video" && url.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          _videoController!.setVolume(_isMuted ? 0 : 1);
          if (mounted) {
            setState(() => _videoInitialized = true);
          }
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
    try {
      await FirebaseDatabase.instance
          .ref('complaints/${widget.complaintId}')
          .update({"status": newStatus});
      if (!mounted) return;
      setState(() => selectedStatus = newStatus);
      Fluttertoast.showToast(msg: "Status updated to $newStatus");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update status");
    }
  }

  Color _statusColor(String status, {bool bg = false}) {
    switch (status) {
      case 'Resolved':
        return bg ? const Color(0xFFDBF7E7) : const Color(0xFF1E8E5A);
      case 'In Progress':
        return bg ? const Color(0xFFFFF3D6) : const Color(0xFF915103);
      case 'Pending':
      default:
        return bg ? const Color(0xFFFFE4E6) : const Color(0xFFB42318);
    }
  }

  Widget _statusChip(String status, {double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status, bg: true),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          letterSpacing: .2,
        ),
      ),
    );
  }

  void _showStatusSheet() {
    final options = const ["Pending", "In Progress", "Resolved"];
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Update Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              ...options.map((s) {
                final selected = s == selectedStatus;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s == "Resolved"
                        ? Icons.check_circle
                        : s == "In Progress"
                            ? Icons.hourglass_top_rounded
                            : Icons.pending_rounded,
                    color: _statusColor(s),
                  ),
                  title: Text(
                    s,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.radio_button_checked,
                          color: Color(0xFF3A8EDB))
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateStatus(s);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: !isDeleting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  "Confirm Deletion",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              "Are you sure you want to delete this complaint? This action cannot be undone.",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setState(() => isDeleting = true);
                        try {
                          await FirebaseDatabase.instance
                              .ref('complaints/${widget.complaintId}')
                              .remove();

                          if (!mounted) return;
                          Navigator.of(context).pop(); // close dialog

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboard(),
                            ),
                          );

                          Fluttertoast.showToast(
                            msg: "Complaint deleted successfully!",
                            gravity: ToastGravity.BOTTOM,
                          );
                        } catch (e) {
                          if (mounted) {
                            Navigator.of(context).pop();
                            Fluttertoast.showToast(
                              msg: "Failed to delete complaint",
                              gravity: ToastGravity.BOTTOM,
                            );
                          }
                        }
                      },
                child: isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Delete"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading / empty state
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(
          color: Color(0xFF3A8EDB),
          strokeWidth: 5,
        )),
      );
    }
    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Complaint",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            "Complaint not found",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final String mediaType =
        complaint!["media_type"]?.toString().toLowerCase() ?? "image";
    final String mediaUrl = (complaint!["media_url"] ?? '').toString().isEmpty
        ? 'https://picsum.photos/640/360'
        : complaint!["media_url"].toString();

    final String issue = complaint!["issue_type"]?.toString() ?? "Complaint";
    final String status = selectedStatus;
    final String location = complaint!["location"]?.toString() ?? "-";
    final String city = complaint!["city"]?.toString() ?? "-";
    final String state = complaint!["state"]?.toString() ?? "-";
    final String reporter =
        "${complaint!["user_name"] ?? "Unknown"} (${complaint!["user_email"] ?? "N/A"})";
    final String timeStr =
        _formatTimestamp(complaint!["timestamp"]?.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        elevation: 3,
        title: Hero(
          tag: 'title_${widget.complaintId}',
          flightShuttleBuilder: _fadeShuttle,
          child: Material(
            color: Colors.transparent,
            child: Text(
              issue,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _statusChip(status, fontSize: 11),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "update") _showStatusSheet();
              if (value == "delete") _confirmDelete();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: "update", child: Text("Update Status")),
              PopupMenuItem(
                value: "delete",
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Delete", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            // Media Card
            _SectionCard(
              padding: EdgeInsets.zero,
              child: Hero(
                tag: 'media_${widget.complaintId}',
                flightShuttleBuilder: _fadeShuttle,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildMediaPreview(mediaType, mediaUrl),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Details Card
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.info_outline_rounded,
                    title: "Details",
                    trailing: _statusChip(status),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.place, label: "Location", value: location),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.location_city_outlined,
                    label: "City / State",
                    value: "$city, $state",
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                      icon: Icons.schedule,
                      label: "Date & Time",
                      value: timeStr),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reporter Card
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.person_outline_rounded,
                    title: "Reporter",
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                      icon: Icons.alternate_email,
                      label: "User",
                      value: reporter),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Description Card
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.notes_rounded,
                    title: "Description",
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (complaint!["description"] ?? "-").toString(),
                    style: const TextStyle(fontSize: 14.5, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showStatusSheet,
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.black,
                  ),
                  label: const Text(
                    "Update Status",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text(
                    "Delete",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Smooth cross-fade during hero flight
  Widget _fadeShuttle(BuildContext _, Animation<double> animation,
      HeroFlightDirection __, BuildContext fromHero, BuildContext toHero) {
    return FadeTransition(
      opacity: animation.drive(Tween(begin: 0.6, end: 1.0)),
      child: toHero.widget,
    );
  }

  Widget _buildMediaPreview(String type, String url) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.isAbsolute) {
      return Container(
        height: 200,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 100)),
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
            // Center play/pause
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
            // Mute toggle
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: const BoxDecoration(
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
        return SizedBox(
          height: 220,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: Color(0xFF3A8EDB),
                  ),
                ),
                SizedBox(width: 8),
                Text("Loading video…"),
              ],
            ),
          ),
        );
      }
    }

    // Image
    return Image.network(
      url,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: 220,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: Color(0xFF3A8EDB),
                  ),
                ),
                SizedBox(width: 8),
                Text("Loading image…"),
              ],
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Image load failed: $error");
        return Container(
          height: 220,
          color: Colors.grey.shade200,
          child: const Center(child: Icon(Icons.broken_image, size: 100)),
        );
      },
    );
  }

  String _formatTimestamp(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) return "-";
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      // 2025-08-17 13:45:22 format (no ms)
      return dt.toString().split('.').first;
    } catch (_) {
      return isoTimestamp;
    }
  }
}

/* ---------- UI helpers (cards/headers/rows) ---------- */

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _SectionCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black12.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black87),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: .2,
    );
    const valueStyle = TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}
