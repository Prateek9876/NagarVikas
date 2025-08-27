// message_reporting_system.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/theme_provider.dart';

class MessageReportingSystem {
  static final DatabaseReference _reportsRef = FirebaseDatabase.instance.ref("message_reports");
  static final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref("discussion");

  /// Show report dialog for a message
  static void showReportDialog({
    required BuildContext context,
    required String messageId,
    required String messageContent,
    required String reportedUserId,
    required String reportedUserName,
    required ThemeProvider themeProvider,
  }) {
    showDialog(
      context: context,
      builder: (context) => ReportMessageDialog(
        messageId: messageId,
        messageContent: messageContent,
        reportedUserId: reportedUserId,
        reportedUserName: reportedUserName,
        themeProvider: themeProvider,
      ),
    );
  }

  /// Submit a report to Firebase
  static Future<bool> submitReport({
    required String messageId,
    required String messageContent,
    required String reportedUserId,
    required String reportedUserName,
    required String reportReason,
    required String additionalDetails,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Check if user has already reported this message
      final existingReportQuery = await _reportsRef
          .orderByChild('messageId')
          .equalTo(messageId)
          .once();

      if (existingReportQuery.snapshot.exists) {
        final reports = existingReportQuery.snapshot.value as Map<dynamic, dynamic>;

        // Check if current user has already reported this message
        bool alreadyReported = false;
        reports.forEach((key, value) {
          if (value['reporterId'] == currentUser.uid) {
            alreadyReported = true;
          }
        });

        if (alreadyReported) {
          Fluttertoast.showToast(
            msg: "You have already reported this message",
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
          return false;
        }
      }

      // Get reporter's name
      String reporterName = "Anonymous User";
      try {
        final userSnapshot = await FirebaseDatabase.instance
            .ref("users/${currentUser.uid}")
            .once();
        if (userSnapshot.snapshot.exists) {
          final userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>;
          reporterName = userData['name'] ?? userData['displayName'] ?? "Anonymous User";
        }
      } catch (e) {
        print('Error getting reporter name: $e');
      }

      // Create report data
      final reportData = {
        'messageId': messageId,
        'messageContent': messageContent,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reporterId': currentUser.uid,
        'reporterName': reporterName,
        'reportReason': reportReason,
        'additionalDetails': additionalDetails,
        'reportedAt': ServerValue.timestamp,
        'status': 'pending', // pending, reviewed, resolved
        'createdAt': ServerValue.timestamp,
      };

      // Submit report
      await _reportsRef.push().set(reportData);

      Fluttertoast.showToast(
        msg: "Message reported successfully. Thank you for helping keep our community safe.",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      return true;
    } catch (e) {
      print('Error submitting report: $e');
      Fluttertoast.showToast(
        msg: "Failed to submit report. Please try again.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  /// Get all reports (admin only)
  static Stream<List<Map<String, dynamic>>> getReports() {
    return _reportsRef.orderByChild('reportedAt').onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> reports = [];

      data.forEach((key, value) {
        reports.add({
          'id': key,
          ...Map<String, dynamic>.from(value),
        });
      });

      // Sort by report date (newest first)
      reports.sort((a, b) => b['reportedAt'].compareTo(a['reportedAt']));
      return reports;
    });
  }

  /// Update report status (admin only)
  static Future<void> updateReportStatus(String reportId, String newStatus, {String? adminNote}) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'reviewedAt': ServerValue.timestamp,
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      };

      if (adminNote != null && adminNote.isNotEmpty) {
        updateData['adminNote'] = adminNote;
      }

      await _reportsRef.child(reportId).update(updateData);

      Fluttertoast.showToast(
        msg: "Report status updated successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error updating report status: $e');
      Fluttertoast.showToast(
        msg: "Failed to update report status",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  /// Delete report (admin only)
  static Future<void> deleteReport(String reportId) async {
    try {
      await _reportsRef.child(reportId).remove();

      Fluttertoast.showToast(
        msg: "Report deleted successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      print('Error deleting report: $e');
      Fluttertoast.showToast(
        msg: "Failed to delete report",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}

/// Report Message Dialog Widget
class ReportMessageDialog extends StatefulWidget {
  final String messageId;
  final String messageContent;
  final String reportedUserId;
  final String reportedUserName;
  final ThemeProvider themeProvider;

  const ReportMessageDialog({
    super.key,
    required this.messageId,
    required this.messageContent,
    required this.reportedUserId,
    required this.reportedUserName,
    required this.themeProvider,
  });

  @override
  State<ReportMessageDialog> createState() => _ReportMessageDialogState();
}

class _ReportMessageDialogState extends State<ReportMessageDialog> {
  String selectedReason = '';
  final TextEditingController _detailsController = TextEditingController();
  bool isSubmitting = false;

  final List<Map<String, dynamic>> reportReasons = [
    {
      'value': 'inappropriate_content',
      'label': 'Inappropriate Content',
      'icon': Icons.warning,
      'color': Colors.orange,
    },
    {
      'value': 'harassment',
      'label': 'Harassment or Bullying',
      'icon': Icons.person_off,
      'color': Colors.red,
    },
    {
      'value': 'spam',
      'label': 'Spam or Advertisement',
      'icon': Icons.block,
      'color': Colors.purple,
    },
    {
      'value': 'hate_speech',
      'label': 'Hate Speech',
      'icon': Icons.gavel,
      'color': Colors.deepOrange,
    },
    {
      'value': 'misinformation',
      'label': 'False Information',
      'icon': Icons.fact_check,
      'color': Colors.indigo,
    },
    {
      'value': 'privacy_violation',
      'label': 'Privacy Violation',
      'icon': Icons.privacy_tip,
      'color': Colors.teal,
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a reason for reporting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final success = await MessageReportingSystem.submitReport(
      messageId: widget.messageId,
      messageContent: widget.messageContent,
      reportedUserId: widget.reportedUserId,
      reportedUserName: widget.reportedUserName,
      reportReason: selectedReason,
      additionalDetails: _detailsController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }

    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: widget.themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.report,
                      size: 32,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Report Message",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.themeProvider.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Help us keep the community safe by reporting inappropriate content",
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Message preview
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: widget.themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      SizedBox(width: 8),
                      Text(
                        widget.reportedUserName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.messageContent.isNotEmpty
                        ? widget.messageContent
                        : "Media message or poll",
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Report reasons
            Flexible(
              child: Container(
                margin: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Why are you reporting this message?",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),
                      ...reportReasons.map((reason) {
                        final isSelected = selectedReason == reason['value'];
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  selectedReason = reason['value'];
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? reason['color'].withOpacity(0.1)
                                      : (widget.themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? reason['color']
                                        : (widget.themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: reason['color'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        reason['icon'],
                                        size: 16,
                                        color: reason['color'],
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        reason['label'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected
                                              ? reason['color']
                                              : (widget.themeProvider.isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: reason['color'],
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      SizedBox(height: 16),

                      // Additional details
                      Text(
                        "Additional details (optional)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _detailsController,
                        maxLines: 3,
                        maxLength: 500,
                        style: TextStyle(
                          color: widget.themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Provide more context about why this message violates community guidelines...",
                          hintStyle: TextStyle(
                            color: widget.themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: widget.themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: widget.themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[50],
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey[400]!,
                          ),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: widget.themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isSubmitting
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        "Submit Report",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
