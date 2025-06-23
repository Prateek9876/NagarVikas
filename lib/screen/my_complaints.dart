import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  _MyComplaintsScreenState createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = []; // Added for search
  TextEditingController searchController = TextEditingController(); // Added

  bool _isLoading = true;
  String selectedStatus = 'All'; // <-- Add this for status filter

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    DatabaseReference ref = FirebaseDatabase.instance.ref('complaints/');

    ref.orderByChild("user_id").equalTo(userId).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        setState(() {
          complaints = [];
          filteredComplaints = []; // Clear filtered
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> loadedComplaints = [];

      data.forEach((key, value) {
        final complaint = value as Map<dynamic, dynamic>;

        String rawTimestamp = complaint["timestamp"] ?? "";
        String formattedDate = "Unknown Date";
        String formattedTime = "Unknown Time";

        try {
          if (rawTimestamp.isNotEmpty) {
            DateTime dateTime = DateTime.parse(rawTimestamp);
            formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
            formattedTime = DateFormat('hh:mm a').format(dateTime);
          }
        } catch (e) {
          print("Error parsing timestamp: $e");
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
      });

      setState(() {
        complaints = loadedComplaints;
        _applyFilters(); // Use new filter logic
        _isLoading = false;
      });
    });
  }

  void _applyFilters() {
    String query = searchController.text;
    setState(() {
      filteredComplaints = complaints.where((complaint) {
        final matchesStatus = selectedStatus == 'All' ||
            complaint['status'].toString().toLowerCase() == selectedStatus.toLowerCase();
        final matchesQuery = query.isEmpty ||
            complaint.values.any((value) =>
                value.toString().toLowerCase().contains(query.toLowerCase()));
        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.red;
      case "in progress":
        return Colors.orange;
      case "resolved":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getComplaintIcon(String issue) {
    if (issue.toLowerCase().contains("road")) {
      return Icons.directions_car;
    } else if (issue.toLowerCase().contains("water")) {
      return Icons.water_drop;
    } else if (issue.toLowerCase().contains("drainage")) {
      return Icons.plumbing;
    } else if (issue.toLowerCase().contains("garbage")) {
      return Icons.delete;
    } else if (issue.toLowerCase().contains("stray")) {
      return Icons.pets;
    } else if (issue.toLowerCase().contains("streetlights")) {
      return Icons.wb_incandescent;
    } else if (issue.toLowerCase().contains("new")) {
      return Icons.fiber_new;
    }
    return Icons.report_problem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 253, 254, 254),
      appBar: AppBar(
        title: Text("My Complaints"),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/no_complaints.png', height: 150),
                      SizedBox(height: 20),
                      Text(
                        "No Complaints Raised Yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              onChanged: (val) => _applyFilters(),
                              decoration: InputDecoration(
                                hintText: 'Search complaints...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedStatus,
                            items: [
                              'All',
                              'Pending',
                              'In Progress',
                              'Resolved',
                            ].map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
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
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchComplaints,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredComplaints.length,
                          padding: EdgeInsets.all(10),
                          itemBuilder: (ctx, index) {
                            final complaint = filteredComplaints[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Status Tag
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                              complaint['status']),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          complaint['status'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),

                                    // Title Row with Icon
                                    Row(
                                      children: [
                                        Icon(
                                          _getComplaintIcon(
                                              complaint['issue']),
                                          color: Colors.blueAccent,
                                          size: 22,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            complaint['issue'],
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),
                                    Divider(color: Colors.grey[300]),

                                    // Date & Time Row
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16,
                                            color: Colors.grey[600]),
                                        SizedBox(width: 5),
                                        Text(
                                          complaint['date'],
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                        SizedBox(width: 15),
                                        Icon(Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[600]),
                                        SizedBox(width: 5),
                                        Text(
                                          complaint['time'],
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),

                                    // Location Row
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 18,
                                            color: Colors.redAccent),
                                        SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            "${complaint['location']}, ${complaint['city']}, ${complaint['state']}",
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
