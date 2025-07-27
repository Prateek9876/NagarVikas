import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:NagarVikas/localization/app_localizations.dart'; // Import the localization file

/// DiscussionForum
/// A real-time chat interface where users can post and view messages.
/// Uses Firebase Realtime Database for message storage.

class DiscussionForum extends StatefulWidget {
  const DiscussionForum({super.key});

  @override
  DiscussionForumState createState() => DiscussionForumState();
}

class DiscussionForumState extends State<DiscussionForum> {
  final TextEditingController _messageController = TextEditingController();  // 💬 Controls text input
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref("discussion/");  // 🔗 Firebase DB ref
  final ScrollController _scrollController = ScrollController();  // 📜 Scroll controller for ListView
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;  // 🔐 Get current user ID
  }

  /// 📤 Sends a message to Firebase Realtime Database
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _messagesRef.push().set({
      "message": _messageController.text.trim(),  // ✍️ Message text
      "senderId": userId,                         // 👤 Sender ID
      "timestamp": ServerValue.timestamp,         // 🕒 Server-side timestamp
    });

    _messageController.clear();  // 🔄 Clear input
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  /// 🧱 Builds a single message bubble (left or right aligned)
  Widget _buildMessage(Map<String, dynamic> messageData, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: isMe ? Radius.circular(10) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(10),
          ),
        ),
        child: Text(
          messageData["message"],  // 📝 Display message
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🧭 App bar
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get("discussionForum")), // Localized string
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Column(
        children: [
          // 🔄 Real-time message list
          Expanded(
            child: StreamBuilder(
              stream: _messagesRef.orderByChild("timestamp").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return Center(child: Text(AppLocalizations.of(context).get("noMessagesYet")));  // Localized string
                }

                // 🔄 Convert snapshot to list of messages
                Map<dynamic, dynamic> messagesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                List<Map<String, dynamic>> messagesList = messagesMap.entries
                    .map((e) =>
                        {"key": e.key, ...Map<String, dynamic>.from(e.value)})
                    .toList();

                // 🕒 Sort by timestamp (ascending)
                messagesList.sort((a, b) => a["timestamp"].compareTo(b["timestamp"]));

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messagesList.length,
                  itemBuilder: (context, index) {
                    final message = messagesList[index];
                    bool isMe = message["senderId"] == userId;
                    return _buildMessage(message, isMe);  // 🧱 Render message
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
                // ✍️ Text input field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).get("typeAMessage"), // Localized string
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // 🚀 Send button
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: const Color.fromARGB(255, 7, 7, 7),
                  child: Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
     ),
);
}
}
