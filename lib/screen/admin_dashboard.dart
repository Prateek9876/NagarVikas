import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'login_page.dart';

/// 🛠️ AdminDashboard
/// Admin dashboard to view, search, and manage user complaints in real-time.
/// Pulls data from Firebase Realtime Database and supports real-time updates.
/// version1.1

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // 🔢 Complaint counters
  int totalComplaints = 0;
  int pendingComplaints = 0;
  int inProgressComplaints = 0;
  int resolvedComplaints = 0;

  // 📦 Complaint data storage
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];

  // Controller for the top search bar
  TextEditingController searchController = TextEditingController();

  StreamSubscription? _complaintsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchComplaints(); // 📥 Fetch complaints on load
  }

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }

  /// 🔄 Fetches all complaints and enriches them with user info from Firebase
  Future<void> _fetchComplaints() async {
    DatabaseReference complaintsRef =
        FirebaseDatabase.instance.ref('complaints');
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');

    _complaintsSubscription =
        complaintsRef.onValue.listen((complaintEvent) async {
      if (!mounted) return;

      final complaintData =
          complaintEvent.snapshot.value as Map<dynamic, dynamic>?;

      // If no data exists
      if (complaintData == null) {
        if (mounted) {
          setState(() {
            totalComplaints = pendingComplaints =
                inProgressComplaints = resolvedComplaints = 0;
            complaints = [];
            filteredComplaints = [];
          });
        }
        return;
      }

      // 🧾 Parsing and enriching complaint data with user info
      List<Map<String, dynamic>> loadedComplaints = [];
      int pending = 0, inProgress = 0, resolved = 0, total = 0;

      for (var entry in complaintData.entries) {
        final complaint = entry.value as Map<dynamic, dynamic>;
        String userId = complaint["user_id"] ?? "Unknown";

        // 👤 Fetch user details
        DataSnapshot userSnapshot = await usersRef.child(userId).get();
        Map<String, dynamic>? userData = userSnapshot.value != null
            ? Map<String, dynamic>.from(userSnapshot.value as Map)
            : null;

        // ⏳ Complaint status classification
        String status = complaint["status"]?.toString() ?? "Pending";
        if (status == "Pending") pending++;
        if (status == "In Progress") inProgress++;
        if (status == "Resolved") resolved++;
        total++;

        // 📅 Timestamp parsing
        String timestamp = complaint["timestamp"] ?? "Unknown";
        String date = "Unknown", time = "Unknown";

        if (timestamp != "Unknown") {
          DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
          date = "${dateTime.day}-${dateTime.month}-${dateTime.year}";
          time = "${dateTime.hour}:${dateTime.minute}";
        }

        // 📋 Building complaint object
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
          "image_url": complaint["image_url"] ?? "",
          "user_id": userId,
          "user_name": userData?["name"] ?? "Unknown",
          "user_email": userData?["email"] ?? "Unknown",
        });
      }

      // 🆙 Update UI state
      if (mounted) {
        setState(() {
          totalComplaints = total;
          pendingComplaints = pending;
          inProgressComplaints = inProgress;
          resolvedComplaints = resolved;
          complaints = loadedComplaints;
          filteredComplaints = complaints;
        });
      }
    });
  }

  /// 🔍 Filters displayed complaints live as the admin types
  void _searchComplaints(String query) {
    setState(() {
      filteredComplaints = complaints.where((complaint) {
        return complaint.values.any((value) =>
            value.toString().toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  /// 🔄 Updates the status of a complaint
  void _updateComplaintStatus(String complaintId, String newStatus) {
    FirebaseDatabase.instance
        .ref('complaints/$complaintId')
        .update({"status": newStatus});
  }

  void _deleteComplaint(String complaintId) {
    FirebaseDatabase.instance.ref('complaints/$complaintId').remove();
  }

  void _confirmAction(String action, String complaintId, {String? status}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm $action"),
        content: Text(
            "Are you sure you want to ${action.toLowerCase()} this complaint?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (action == "Delete") {
                _deleteComplaint(complaintId);
              } else if (action == "Mark Resolved" && status != null) {
                _updateComplaintStatus(complaintId, status);
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  /// 🔓 Logs the admin out with confirmation dialog and redirects to LoginPage
  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false);
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          return false; // 🚫 Prevent back navigation to avoid unintended logout or state loss
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Admin Dashboard"),
            backgroundColor: const Color.fromARGB(255, 4, 204, 240),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _logout(context)),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Search complaints...",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: _searchComplaints,
                ),
                const SizedBox(height: 20),

                // 📋 Complaints ListView
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredComplaints.length,
                    itemBuilder: (ctx, index) {
                      final complaint = filteredComplaints[index];
                      return Dismissible(
                        key: Key(complaint["id"]),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.only(left: 20),
                          child:
                              Icon(Icons.check, color: Colors.white, size: 30),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                          child:
                              Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            _confirmAction("Mark Resolved", complaint["id"],
                                status: "Resolved");
                          } else if (direction == DismissDirection.endToStart) {
                            _confirmAction("Delete", complaint["id"]);
                          }
                          return false;
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          elevation: 5,
                          child: ListTile(
                            leading: complaint["image_url"].isNotEmpty
                                ? Image.network(complaint["image_url"],
                                    width: 80, height: 80, fit: BoxFit.cover)
                                : Icon(Icons.image_not_supported, size: 50),
                            title: Text(complaint["issue_type"],
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "User: ${complaint["user_name"]} (${complaint["user_email"]})"),
                                Text("Status: ${complaint["status"]}"),
                                Text(
                                    "Date: ${complaint["date"]}  Time: ${complaint["time"]}"),
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () =>
                                _showComplaintDetails(context, complaint),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  /// 📄 Shows full details of a selected complaint with status editing
  void _showComplaintDetails(
      BuildContext context, Map<String, dynamic> complaint) {
    String selectedStatus = complaint["status"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(complaint["issue_type"],
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  complaint["image_url"].isNotEmpty
                      ? Image.network(complaint["image_url"],
                          height: 200, fit: BoxFit.cover)
                      : Icon(Icons.image_not_supported, size: 100),
                  const SizedBox(height: 10),
                  Text("📍 Location:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      "${complaint["location"]}, ${complaint["city"]}, ${complaint["state"]}"),
                  const SizedBox(height: 10),
                  Text("📅 Date & Time:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${complaint["date"]} at ${complaint["time"]}"),
                  const SizedBox(height: 10),
                  Text("👤 User:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      "${complaint["user_name"]} (${complaint["user_email"]})"),
                  const SizedBox(height: 10),
                  Text("📝 Description:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(complaint["description"],
                      style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  Text("🔄 Status:",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  // 🎛️ Dropdown for changing complaint status (updates Firebase)
                  DropdownButton<String>(
                    value: selectedStatus,
                    items: ["Pending", "In Progress", "Resolved"]
                        .map((status) => DropdownMenuItem(
                            value: status, child: Text(status)))
                        .toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        _updateComplaintStatus(complaint["id"], newStatus);
                        setState(() {
                          selectedStatus = newStatus;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"))
            ],
          );
        },
      ),
    );
  }
}
