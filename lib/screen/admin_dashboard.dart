// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import './ComplaintDetailPage.dart';
import 'login_page.dart';
import 'package:NagarVikas/screen/analytics_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSON encoding/decoding

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
List<Map<String, dynamic>> notifications = [];
Set<String> seenComplaintIds = {};

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
  void loadSeenComplaintIds() async {
  final prefs = await SharedPreferences.getInstance();
  final seenIds = prefs.getStringList('seenComplaintIds') ?? [];
  setState(() {
    seenComplaintIds = seenIds.toSet();
  });
}
  void markComplaintAsSeen(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final seenIds = prefs.getStringList('seenComplaintIds') ?? [];

  if (!seenIds.contains(id)) {
    seenIds.add(id);
    await prefs.setStringList('seenComplaintIds', seenIds);
  }

  setState(() {
    seenComplaintIds = seenIds.toSet(); // update local set also
  });
}
Future<void> saveNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(notifications);
  await prefs.setString('notifications', encoded);
}
Future<void> loadNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = prefs.getString('notifications');
  if (encoded != null) {
    final decoded = jsonDecode(encoded) as List;
    setState(() {
      notifications = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }
}

 @override
void initState() {
  super.initState();
  _fetchComplaints();
  loadNotifications(); 
  listenToNewComplaints();
  loadSeenComplaintIds(); 
}

  @override
  void dispose() {
    _complaintsSubscription?.cancel();
    searchController.dispose();
    super.dispose();
  }
void listenToNewComplaints() {
  FirebaseDatabase.instance
      .ref('complaints')
      .limitToLast(1)
      .onChildAdded
      .listen((event) async {
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    final complaintId = event.snapshot.key;

    if (data == null || complaintId == null) return;

    // Already seen? ignore
    if (seenComplaintIds.contains(complaintId)) return;

    final now = DateTime.now();
    final formattedTime =
        "${now.day}-${now.month}-${now.year} at ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    final newNotification = {
      'id': complaintId,
      'title': data['issue_type'] ?? 'New Complaint',
      'timestamp': formattedTime,
      'seen': false,
    };

    setState((){
      notifications.insert(0, newNotification);
    });
     await saveNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🔔 New Complaint: ${newNotification['title']}"),
        duration: const Duration(seconds: 3),
      ),
    );
  });
}
  Future<void> _fetchComplaints() async {
    DatabaseReference complaintsRef = FirebaseDatabase.instance.ref('complaints');
    DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');

    _complaintsSubscription = complaintsRef.onValue.listen((complaintEvent) async {
      if (!mounted) return;

      final complaintData = complaintEvent.snapshot.value as Map<dynamic, dynamic>?;

      if (complaintData == null) {
        if (mounted) {
          setState(() {
            totalComplaints = pendingComplaints = inProgressComplaints = resolvedComplaints = 0;
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

        String? mediaUrl = complaint["media_url"] ?? complaint["image_url"] ?? "";
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
          "media_url": (mediaUrl ?? '').isEmpty ? 'https://picsum.photos/250?image=9' : mediaUrl,
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
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  // Handle bottom navigation item tap
  void _onItemTapped(int index) {
    if (index == 1) { // Analytics
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnalyticsDashboard()),
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
                if (!mounted) return;
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
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
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
  title: const Text(
    "Admin Dashboard",
    style: TextStyle(color: Color.fromARGB(255, 10, 10, 10)),
  ),
  backgroundColor: const Color.fromARGB(255, 4, 204, 240),
  iconTheme: const IconThemeData(color: Color.fromARGB(255, 13, 13, 13)),
  actions: [
IconButton(
  icon: Stack(
    children: [
      const Icon(Icons.notifications),
      if (notifications.any((n) => !n['seen']))
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${notifications.where((n) => !n['seen']).length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
    ],
  ),
  onPressed: () async {
    setState(() {
      for (var n in notifications) {
        if (!n['seen']) {
          markComplaintAsSeen(n['id']);
          n['seen'] = true;
        }
      }
    });
    await saveNotifications(); // 🔐 Save seen status

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 198, 186, 190),
        title: const Text("Notifications"),
        content: SizedBox(
          height: 300,
          width: double.infinity,
          child: notifications.isEmpty
              ? const Center(child: Text("No notifications."))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final noti = notifications[index];
                    return Dismissible(
                      key: Key(noti['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        setState(() {
                          notifications.removeAt(index);
                        });
                        await saveNotifications(); // 💾 Save after dismiss
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Notification dismissed'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber),
                        title: Text(noti['title']),
                        subtitle: Text(noti['timestamp']),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              setState(() {
                for (var n in notifications) {
                  markComplaintAsSeen(n['id']);
                }
                notifications.clear();
              });
              await saveNotifications(); // 💾 Save after Clear All
              Navigator.pop(context);
            },
            child: const Text(
              "Clear All",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  },
),
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () {
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
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search complaints...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _searchComplaints,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredComplaints.isEmpty
                  ? const Center(child: Text("No complaints found."))
                  : ListView.builder(
                itemCount: filteredComplaints.length,
                itemBuilder: (ctx, index) {
                  final complaint = filteredComplaints[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: complaint["media_type"] == "image"
                          ? ClipOval(
                              child: Image.network(
                                complaint["media_url"],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 40),
                              ),
                            )
                          : const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.videocam, color: Colors.white),
                            ),
                      title: Text(
                        complaint["issue_type"] ?? "Unknown",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Status: ${complaint["status"]}"),
                          const SizedBox(height: 4),
                          Text("City: ${complaint["city"]}, State: ${complaint["state"]}"),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.of(context).push(
                        _createSlideRoute(complaint),
                      ),
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
}