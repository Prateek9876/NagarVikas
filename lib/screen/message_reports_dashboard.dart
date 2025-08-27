// lib/admin/message_reports_dashboard.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../theme/theme_provider.dart';
import 'discussion/message_reporting_screen.dart';

class MessageReportsDashboard extends StatefulWidget {
  const MessageReportsDashboard({super.key});

  @override
  MessageReportsDashboardState createState() => MessageReportsDashboardState();
}

class MessageReportsDashboardState extends State<MessageReportsDashboard> {
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;
  String selectedStatus = 'All';
  final DatabaseReference _reportsRef = FirebaseDatabase.instance.ref("message_reports");
  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref("discussion");
  final DatabaseReference _bannedUsersRef = FirebaseDatabase.instance.ref("banned_users");

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  void _fetchReports() {
    _reportsRef.onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      List<Map<String, dynamic>> loadedReports = [];

      if (data != null) {
        data.forEach((reportId, reportData) {
          loadedReports.add({
            "id": reportId,
            ...Map<String, dynamic>.from(reportData),
          });
        });

        // Sort by report date (newest first)
        loadedReports.sort((a, b) => b["reportedAt"].compareTo(a["reportedAt"]));
      }

      if (mounted) {
        setState(() {
          reports = loadedReports;
          isLoading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> get filteredReports {
    if (selectedStatus == 'All') return reports;
    return reports.where((report) =>
    report['status']?.toLowerCase() == selectedStatus.toLowerCase()).toList();
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateFormat('MMM d, y • h:mm a').format(date);
      }
      return 'Unknown time';
    } catch (e) {
      return 'Unknown time';
    }
  }

  void _updateReportStatus(String reportId, String newStatus, {String? adminNote}) async {
    await MessageReportingSystem.updateReportStatus(reportId, newStatus, adminNote: adminNote);
  }

  void _deleteReport(String reportId) async {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Delete Report',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this report? This action cannot be undone.',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await MessageReportingSystem.deleteReport(reportId);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _banReportedUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Ban User',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to ban $userName? They will not be able to send messages until unbanned.',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _bannedUsersRef.child(userId).set({
                    "banned_by": "admin",
                    "banned_at": ServerValue.timestamp,
                    "user_name": userName,
                    "reason": "Reported message violation",
                  });
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(
                    msg: '$userName has been banned',
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                },
                child: Text(
                  'Ban User',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteReportedMessage(String messageId) async {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Delete Message',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete the reported message? This action cannot be undone.',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Replace message with admin deletion message
                  await _messagesRef.child(messageId).update({
                    "message": "This message was deleted by admin",
                    "messageType": "admin_deleted",
                    "deletedAt": ServerValue.timestamp,
                    "deletedBy": "admin",
                    "mediaUrl": null,
                    "replyTo": null,
                    "replyToMessage": null,
                    "replyToSender": null,
                  });
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(
                    msg: 'Message has been deleted',
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );
                },
                child: Text(
                  'Delete Message',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportActions(Map<String, dynamic> report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Report Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 20),

                // Mark as Reviewed
                if (report['status'] != 'reviewed')
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.visibility, color: Colors.blue),
                    ),
                    title: Text(
                      'Mark as Reviewed',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _updateReportStatus(report['id'], 'reviewed');
                    },
                  ),

                // Mark as Resolved
                if (report['status'] != 'resolved')
                  ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.check_circle, color: Colors.green),
                    ),
                    title: Text(
                      'Mark as Resolved',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _updateReportStatus(report['id'], 'resolved');
                    },
                  ),

                Divider(color: Colors.grey[400]),

                // Delete Reported Message
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_forever, color: Colors.red),
                  ),
                  title: Text(
                    'Delete Reported Message',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteReportedMessage(report['messageId']);
                  },
                ),

                // Ban User
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.block, color: Colors.orange),
                  ),
                  title: Text(
                    'Ban Reported User',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _banReportedUser(report['reportedUserId'], report['reportedUserName']);
                  },
                ),

                Divider(color: Colors.grey[400]),

                // Delete Report
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline, color: Colors.grey),
                  ),
                  title: Text(
                    'Delete Report',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteReport(report['id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.isDarkMode
              ? Colors.grey[900]
              : const Color(0xFFF8F9FA),
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Column(
              children: [
                Text(
                  "Message Reports",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "${filteredReports.length} report${filteredReports.length == 1 ? '' : 's'}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            iconTheme: IconThemeData(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          body: Column(
            children: [
              // Filter Section
              Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    dropdownColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                    items: ['All', 'Pending', 'Reviewed', 'Resolved']
                        .map((status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status == 'All' ? Colors.grey : _getStatusColor(status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            status,
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
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
                      }
                    },
                  ),
                ),
              ),

              // Reports List
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : filteredReports.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.report_off,
                        size: 64,
                        color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "No reports found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        selectedStatus == 'All'
                            ? "No message reports available"
                            : "No $selectedStatus reports",
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.isDarkMode
                                ? Colors.black26
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showReportActions(report),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(report['status'] ?? 'pending').withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.flag,
                                        color: _getStatusColor(report['status'] ?? 'pending'),
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Report #${report['id'].toString().substring(0, 8)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            _formatTimestamp(report['reportedAt']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(report['status'] ?? 'pending').withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getStatusColor(report['status'] ?? 'pending').withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        (report['status'] ?? 'pending').toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(report['status'] ?? 'pending'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),

                                // Report Details
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode ? Colors.grey[750] : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 14,
                                            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Reported: ${report['reportedUserName'] ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Spacer(),
                                          Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'By: ${report['reporterName'] ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Reason: ${report['reportReason'] ?? 'No reason provided'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      if (report['messageContent'] != null && report['messageContent'].isNotEmpty) ...[
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Text(
                                            report['messageContent'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      if (report['additionalDetails'] != null && report['additionalDetails'].isNotEmpty) ...[
                                        SizedBox(height: 8),
                                        Text(
                                          'Additional Details: ${report['additionalDetails']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
