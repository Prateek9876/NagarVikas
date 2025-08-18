import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

/// DiscussionForum
/// A real-time chat interface where users can post and view messages.
/// Uses Firebase Realtime Database for message storage.

class DiscussionForum extends StatefulWidget {
  const DiscussionForum({super.key});

  @override
  DiscussionForumState createState() => DiscussionForumState();
}

class DiscussionForumState extends State<DiscussionForum> {
  final TextEditingController _messageController =
  TextEditingController(); // 💬 Controls text input
  final DatabaseReference _messagesRef =
  FirebaseDatabase.instance.ref("discussion/"); // 🔗 Firebase DB ref
  final DatabaseReference _usersRef =
  FirebaseDatabase.instance.ref("users/"); // 🔗 Users DB ref
  final ScrollController _scrollController =
  ScrollController(); // 📜 Scroll controller for ListView
  String? userId;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid; // 🔑 Get current user ID
    _getCurrentUserName();
  }

  /// 👤 Get current user's display name
  void _getCurrentUserName() async {
    if (userId != null) {
      try {
        final snapshot = await _usersRef.child(userId!).once();
        if (snapshot.snapshot.value != null) {
          final userData = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            currentUserName = userData['name'] ?? userData['displayName'] ?? _getDefaultName();
          });
        } else {
          // If user data doesn't exist, create it with email prefix
          final defaultName = _getDefaultName();

          await _usersRef.child(userId!).set({
            'name': defaultName,
            'displayName': defaultName,
            'email': FirebaseAuth.instance.currentUser?.email ?? '',
            'createdAt': ServerValue.timestamp,
          });

          setState(() {
            currentUserName = defaultName;
          });
        }
      } catch (e) {
        print('Error getting user name: $e');
        setState(() {
          currentUserName = _getDefaultName();
        });
      }
    }
  }

  /// Get default name from email or generate random name
  String _getDefaultName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      return user!.email!.split('@')[0];
    }
    return 'User${Random().nextInt(1000)}';
  }

  /// 📤 Sends a message to Firebase Realtime Database
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || currentUserName == null) return;

    _messagesRef.push().set({
      "message": _messageController.text.trim(), // ✏️ Message text
      "senderId": userId, // 👤 Sender ID
      "senderName": currentUserName, // 👤 Sender display name - ADDED THIS
      "timestamp": ServerValue.timestamp, // 🕐 Server-side timestamp
    });

    _messageController.clear(); // 🔄 Clear input
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  /// 🧱 Builds a single message bubble (left or right aligned)
  Widget _buildMessage(Map<String, dynamic> messageData, bool isMe, ThemeProvider themeProvider) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show sender name only for other people's messages
            if (!isMe)
              Padding(
                padding: EdgeInsets.only(left: 8, right: 8, bottom: 2),
                child: Text(
                  messageData["senderName"] ?? "Unknown User", // Use senderName directly from Firebase
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Message bubble
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.blueAccent
                    : (themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomLeft: isMe ? Radius.circular(10) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(10),
                ),
              ),
              child: Text(
                messageData["message"], // 📝 Display message
                style: TextStyle(
                    color: isMe
                        ? Colors.white
                        : (themeProvider.isDarkMode ? Colors.white : Colors.black),
                    fontSize: 18
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor:
        themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        // 🧭 App bar
        appBar: AppBar(
          elevation: 5,
          shadowColor: Colors.black87,
          centerTitle: true,
          title: Text(
              "Discussion Forum",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              )
          ),
          backgroundColor: const Color.fromARGB(255, 4, 204, 240),
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        body: Stack(
          children: [
            const AnimatedBackground(), // Animated background with bubbles
            Column(
              children: [
                // 🔄 Real-time message list
                Expanded(
                  child: StreamBuilder(
                    stream: _messagesRef.orderByChild("timestamp").onValue,
                    builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                      if (!snapshot.hasData ||
                          snapshot.data?.snapshot.value == null) {
                        return Center(
                            child: Text(
                              "No messages yet!",
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            )); // 👤 Empty state
                      }

                      // 🔄 Convert snapshot to list of messages
                      Map<dynamic, dynamic> messagesMap = snapshot
                          .data!.snapshot.value as Map<dynamic, dynamic>;

                      List<Map<String, dynamic>> messagesList = messagesMap
                          .entries
                          .map((e) => {
                        "key": e.key,
                        ...Map<String, dynamic>.from(e.value)
                      })
                          .toList();

                      // 🕐 Sort by timestamp (ascending)
                      messagesList.sort(
                              (a, b) => a["timestamp"].compareTo(b["timestamp"]));

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messagesList.length,
                        itemBuilder: (context, index) {
                          final message = messagesList[index];
                          bool isMe = message["senderId"] == userId;
                          return _buildMessage(
                              message, isMe, themeProvider); // 🧱 Render message
                        },
                      );
                    },
                  ),
                ),

                // 💬 Message input field & send button
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // ✏️ Text input field
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              decoration: InputDecoration(
                                icon: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, left: 18, right: 8, bottom: 8),
                                  child: Icon(
                                      Icons.message,
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey
                                  ),
                                ),
                                hintText: "Type a message...",
                                hintStyle: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none, // Remove default border
                                ),
                                contentPadding:
                                EdgeInsets.symmetric(horizontal: 1),
                                filled: true,
                                fillColor: themeProvider.isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),

                      // 🚀 Send button
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8.0, top: 8, right: 8),
                        child: FloatingActionButton(
                          onPressed: _sendMessage,
                          backgroundColor: const Color.fromARGB(255, 7, 7, 7),
                          child: Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int bubbleCount = 30;
  late List<_Bubble> bubbles;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: Duration(seconds: 20))
      ..repeat();
    final random = Random();
    bubbles = List.generate(bubbleCount, (index) {
      final size = random.nextDouble() * 30 + 10;
      return _Bubble(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: size,
        speed: random.nextDouble() * 0.2 + 0.05,
        dx: (random.nextDouble() - 0.5) * 0.002,
        color: Colors.blue.withOpacity(0.25),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _BubblePainter(bubbles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Bubble {
  double x, y, radius, speed, dx;
  Color color;
  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.dx,
    required this.color,
  });
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double progress;
  _BubblePainter(this.bubbles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final double dy = (bubble.y + progress * bubble.speed) % 1.2;
      final double dx = (bubble.x + progress * bubble.dx) % 1.0;
      final Offset center = Offset(dx * size.width, dy * size.height);
      final Paint paint = Paint()..color = bubble.color;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: bubble.radius,
          height: bubble.radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
