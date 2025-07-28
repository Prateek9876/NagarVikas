import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  MyComplaintsScreenState createState() => MyComplaintsScreenState();
}

class MyComplaintsScreenState extends State<MyComplaintsScreen> {
  List<Map<String, dynamic>> complaints = [];
  List<Map<String, dynamic>> filteredComplaints = [];
  TextEditingController searchController = TextEditingController();

  bool _isLoading = true;
  String selectedStatus = 'All';

  Map<int, String> complaintKeys = {};

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
          filteredComplaints = [];
          complaintKeys.clear();
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> loadedComplaints = [];
      Map<int, String> keys = {};

      int index = 0;
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

      setState(() {
        complaints = loadedComplaints;
        complaintKeys = keys;
        _applyFilters();
        _isLoading = false;
      });
    });
  }

  Future<void> _deleteComplaint(int index) async {
    try {
      String? complaintKey = complaintKeys[index];
      if (complaintKey != null) {
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref('complaints/$complaintKey')
            .get();

        if (snapshot.exists) {
          Map<String, dynamic> complaintData =
              Map<String, dynamic>.from(snapshot.value as Map);

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
                  log('Image deleted: $imageUrl');
                }
              } catch (e) {
                log('Error deleting image $imageUrl: $e');
              }
            }
          }

          if (complaintData.containsKey('image') &&
              complaintData['image'] != null) {
            String imageUrl = complaintData['image'].toString();
            try {
              if (imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
                await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                log('Single image deleted: $imageUrl');
              }
            } catch (e) {
              log('Error deleting single image $imageUrl: $e');
            }
          }
        }

        await FirebaseDatabase.instance
            .ref('complaints/$complaintKey')
            .remove();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Complaint and associated images deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting complaint: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Complaint'),
          content: Text('Are you sure you want to delete this complaint?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteComplaint(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    String query = searchController.text;
    setState(() {
      filteredComplaints = complaints.where((complaint) {
        final matchesStatus = selectedStatus == 'All' ||
            complaint['status'].toString().toLowerCase() ==
                selectedStatus.toLowerCase();
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
        title: Text("Spell Records"),
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
                            ]
                                .map((status) => DropdownMenuItem(
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

                            int originalIndex = complaints.indexWhere((c) =>
                                c['issue'] == complaint['issue'] &&
                                c['date'] == complaint['date'] &&
                                c['time'] == complaint['time']);

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withAlpha((0.2 * 255).toInt()),
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
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
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            onTap: () => _showDeleteDialog(
                                                originalIndex),
                                            child: Padding(
                                              padding: EdgeInsets.all(8),
                                              child: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red[400],
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          _getComplaintIcon(complaint['issue']),
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
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 5),
                                        Text(
                                          complaint['date'],
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                        SizedBox(width: 15),
                                        Icon(Icons.access_time,
                                            size: 16, color: Colors.grey[600]),
                                        SizedBox(width: 5),
                                        Text(
                                          complaint['time'],
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 18, color: Colors.redAccent),
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
