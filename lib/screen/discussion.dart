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

class DiscussionForumState extends State<DiscussionForum>
    with TickerProviderStateMixin {
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
  
  // Animation controllers for enhanced UI
  late AnimationController _sendButtonAnimationController;
  late AnimationController _messageAnimationController;
  late Animation<double> _sendButtonScaleAnimation;
  late Animation<double> _messageSlideAnimation;
  
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid; // 🔑 Get current user ID
    _getCurrentUserName();
    _initAnimations();
    
    // Listen to text changes for typing indicator
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _sendButtonAnimationController.dispose();
    _messageAnimationController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _sendButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _sendButtonAnimationController,
      curve: Curves.easeInOut,
    ));

    _messageSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeOutBack,
    ));
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

    // Animate send button
    _sendButtonAnimationController.forward().then((_) {
      _sendButtonAnimationController.reverse();
    });

    _messagesRef.push().set({
      "message": _messageController.text.trim(), // ✏️ Message text
      "senderId": userId, // 👤 Sender ID
      "senderName": currentUserName, // 👤 Sender display name - ADDED THIS
      "timestamp": ServerValue.timestamp, // 🕐 Server-side timestamp
    });

    _messageController.clear(); // 🔄 Clear input
    setState(() {
      _isTyping = false;
    });
    
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  /// 🧱 Builds a single message bubble (left or right aligned)
  Widget _buildMessage(Map<String, dynamic> messageData, bool isMe, ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(isMe ? (1 - value) * 50 : (value - 1) * 50, 0),
          child: Opacity(
            opacity: value,
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Show sender name only for other people's messages
                    if (!isMe)
                      Container(
                        margin: EdgeInsets.only(left: 12, right: 12, bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getAvatarColor(messageData["senderName"] ?? "Unknown"),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              messageData["senderName"] ?? "Unknown User",
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Message bubble with enhanced styling
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1976D2),
                                  Color(0xFF2196F3),
                                ],
                              )
                            : null,
                        color: isMe
                            ? null
                            : (themeProvider.isDarkMode 
                                ? Colors.grey[700] 
                                : Colors.grey[100]),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft: isMe ? Radius.circular(20) : Radius.circular(6),
                          bottomRight: isMe ? Radius.circular(6) : Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeProvider.isDarkMode 
                                ? Colors.black26 
                                : Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: !isMe && !themeProvider.isDarkMode
                            ? Border.all(
                                color: Colors.grey.withOpacity(0.2),
                                width: 0.5,
                              )
                            : null,
                      ),
                      child: Text(
                        messageData["message"], // 📝 Display message
                        style: TextStyle(
                          color: isMe
                              ? Colors.white
                              : (themeProvider.isDarkMode ? Colors.white : Colors.black87),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Generate consistent color for user avatars
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.indigo[400]!,
      Colors.pink[400]!,
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
        // 🧭 Enhanced App bar
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: themeProvider.isDarkMode 
              ? Colors.grey[800] 
              : Colors.white,
          title: Column(
            children: [
              Text(
                "Discussion Forum",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Share your thoughts",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: themeProvider.isDarkMode 
                      ? Colors.grey[400] 
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode
                    ? [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                      ]
                    : [
                        Colors.white,
                        Color(0xFFF8F9FA),
                      ],
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    themeProvider.isDarkMode 
                        ? Colors.grey[600]! 
                        : Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            const EnhancedAnimatedBackground(), // Enhanced animated background
            Column(
              children: [
                // 🔄 Real-time message list with enhanced styling
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode 
                          ? Colors.grey[900] 
                          : Color(0xFFF8F9FA),
                    ),
                    child: StreamBuilder(
                      stream: _messagesRef.orderByChild("timestamp").onValue,
                      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                        if (!snapshot.hasData ||
                            snapshot.data?.snapshot.value == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode 
                                        ? Colors.grey[800] 
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeProvider.isDarkMode 
                                            ? Colors.black26 
                                            : Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.forum_outlined,
                                    size: 48,
                                    color: themeProvider.isDarkMode 
                                        ? Colors.grey[400] 
                                        : Colors.grey[500],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No messages yet!",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Be the first to start the conversation",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
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
                          padding: EdgeInsets.symmetric(vertical: 8),
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
                ),

                // 💬 Enhanced message input field & send button
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode 
                        ? Colors.grey[800] 
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.isDarkMode 
                            ? Colors.black26 
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // ✏️ Enhanced text input field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey[700]
                                  : Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _isTyping
                                    ? Color(0xFF2196F3)
                                    : (themeProvider.isDarkMode 
                                        ? Colors.grey[600]! 
                                        : Colors.grey[300]!),
                                width: _isTyping ? 2 : 1,
                              ),
                              boxShadow: _isTyping
                                  ? [
                                      BoxShadow(
                                        color: Color(0xFF2196F3).withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                hintText: "Type your message...",
                                hintStyle: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(left: 8, right: 4),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[500],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),

                        // 🚀 Enhanced send button
                        AnimatedBuilder(
                          animation: _sendButtonScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _sendButtonScaleAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: _isTyping
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1976D2),
                                            Color(0xFF2196F3),
                                          ],
                                        )
                                      : null,
                                  color: !_isTyping
                                      ? (themeProvider.isDarkMode 
                                          ? Colors.grey[600] 
                                          : Colors.grey[400])
                                      : null,
                                  shape: BoxShape.circle,
                                  boxShadow: _isTyping
                                      ? [
                                          BoxShadow(
                                            color: Color(0xFF2196F3).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    onTap: _isTyping ? _sendMessage : null,
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isTyping ? Icons.send_rounded : Icons.send_outlined,
                                        color: Colors.white,
                                        size: _isTyping ? 24 : 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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

class EnhancedAnimatedBackground extends StatefulWidget {
  const EnhancedAnimatedBackground({super.key});

  @override
  State<EnhancedAnimatedBackground> createState() => _EnhancedAnimatedBackgroundState();
}

class _EnhancedAnimatedBackgroundState extends State<EnhancedAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int bubbleCount = 25;
  late List<_EnhancedBubble> bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: Duration(seconds: 25)
    )..repeat();
    
    final random = Random();
    bubbles = List.generate(bubbleCount, (index) {
      final size = random.nextDouble() * 25 + 8;
      return _EnhancedBubble(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: size,
        speed: random.nextDouble() * 0.15 + 0.03,
        dx: (random.nextDouble() - 0.5) * 0.001,
        opacity: random.nextDouble() * 0.15 + 0.05,
        color: Colors.blue.withOpacity(0.1),
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
        painter: _EnhancedBubblePainter(bubbles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _EnhancedBubble {
  double x, y, radius, speed, dx, opacity;
  Color color;
  _EnhancedBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.dx,
    required this.opacity,
    required this.color,
  });
}

class _EnhancedBubblePainter extends CustomPainter {
  final List<_EnhancedBubble> bubbles;
  final double progress;
  _EnhancedBubblePainter(this.bubbles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final double dy = (bubble.y + progress * bubble.speed) % 1.2;
      final double dx = (bubble.x + progress * bubble.dx) % 1.0;
      final Offset center = Offset(dx * size.width, dy * size.height);
      
      // Create gradient paint for more appealing bubbles
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [
            bubble.color.withOpacity(bubble.opacity * 0.8),
            bubble.color.withOpacity(bubble.opacity * 0.2),
            Colors.transparent,
          ],
          stops: [0.0, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: bubble.radius));
      
      canvas.drawCircle(center, bubble.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}