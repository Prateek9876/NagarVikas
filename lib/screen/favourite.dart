import 'package:flutter/material.dart';

import 'complaint_detail_page.dart';


class FavoritesPage extends StatelessWidget {
  final List<Map<String, dynamic>> favoriteComplaints;

  const FavoritesPage({Key? key, required this.favoriteComplaints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Complaints'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        foregroundColor: Colors.white,
      ),
      body: favoriteComplaints.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No favorite complaints yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart icon on complaints to add them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: favoriteComplaints.length,
        itemBuilder: (context, index) {
          final complaint = favoriteComplaints[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ComplaintDetailPage(complaintId: complaint["id"])),
              ),
            ),
          );
        },
      ),
    );
  }
}
