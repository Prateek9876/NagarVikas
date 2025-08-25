import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import 'forum_logic.dart';
import 'poll_message_widget.dart';

class MessageWidgets {
  /// Build message widget with image and video support
  static Widget buildMessage(
      Map<String, dynamic> messageData,
      bool isMe,
      ThemeProvider themeProvider,
      Function(String) onImageTap,
      Function(String) onVideoTap,
      Function(String, String, String) onReply,
      Function(String, String, ThemeProvider, bool, bool, String, String)
      onMessageOptions,
      bool isAdmin,
      String currentUserId,
      // NEW PARAMETERS for voting
      Map<String, Map<String, dynamic>> messageVotes,
      Function(String, bool) onVote,
      Function(String) getUserVote,
      // Parameters for jump to message functionality
          {Function(String)? onJumpToMessage,
        bool isHighlighted = false}
      ) {
    final timeString = ForumLogic.formatTime(
        messageData["createdAt"] ?? messageData["timestamp"]);
    final hasReply = messageData["replyTo"] != null;
    final messageType = messageData["messageType"] ?? "text";
    final isImageMessage = messageType == "image";
    final isVideoMessage = messageType == "video";
    final isPollMessage = messageType == "poll";
    final mediaUrl = messageData["mediaUrl"] ?? messageData["imageUrl"];
    final hasText = messageData["message"] != null &&
        messageData["message"].toString().trim().isNotEmpty;

    // Get voting data
    final messageId = messageData["key"] ?? "";
    final voteCounts = _getVoteCountsFromData(messageVotes[messageId] ?? {});
    final userVote = getUserVote(messageId);
    final hasVotes = voteCounts['upvotes']! > 0 || voteCounts['downvotes']! > 0;

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
                margin: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                child: Column(
                  crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                                color: ForumLogic.getAvatarColor(
                                    messageData["senderName"] ?? "Unknown"),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              messageData["senderName"] ?? "Unknown User",
                              style: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Message content - Handle different message types
                    if (isPollMessage)
                    // Poll message
                      PollMessageWidget(
                        pollData: messageData,
                        isMe: isMe,
                        themeProvider: themeProvider,
                        currentUserId: currentUserId,
                      )
                    else
                    // Regular message bubble for text, image, video
                      GestureDetector(
                        onLongPress: () {
                          onMessageOptions(
                            messageData["key"] ?? "",
                            messageData["message"] ?? "",
                            themeProvider,
                            isImageMessage || isVideoMessage,
                            isMe,
                            messageData["senderId"] ?? "",
                            messageData["senderName"] ?? "Unknown User",
                          );
                        },
                        onTap: () {
                          // Show reply option for messages that aren't from the current user
                          if (!isMe) {
                            onReply(
                              messageData["key"] ?? "",
                              messageData["message"] ?? (isImageMessage ? "Image" : isVideoMessage ? "Video" : "Message"),
                              messageData["senderName"] ?? "Unknown User",
                            );
                          }
                        },
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: (isImageMessage || isVideoMessage) ? 4 : 8,
                            horizontal: (isImageMessage || isVideoMessage) ? 4 : 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isHighlighted
                                  ? [Color(0xFFFFB74D), Color(0xFFFF9800)]
                                  : [Color(0xFF1976D2), Color(0xFF2196F3)],
                            )
                                : null,
                            color: isMe
                                ? null
                                : (isHighlighted
                                ? (themeProvider.isDarkMode ? Color(0xFFFFB74D).withOpacity(0.3) : Color(0xFFFFE0B2))
                                : (themeProvider.isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[100])),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomLeft:
                              isMe ? Radius.circular(18) : Radius.circular(3),
                              bottomRight:
                              isMe ? Radius.circular(3) : Radius.circular(18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isHighlighted
                                    ? Color(0xFFFF9800).withOpacity(0.4)
                                    : (themeProvider.isDarkMode
                                    ? Colors.black26
                                    : Colors.grey.withOpacity(0.1)),
                                blurRadius: isHighlighted ? 12 : 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: !isMe && !themeProvider.isDarkMode
                                ? Border.all(
                                color: isHighlighted
                                    ? Color(0xFFFF9800).withOpacity(0.5)
                                    : Colors.grey.withOpacity(0.2),
                                width: isHighlighted ? 1.5 : 0.5)
                                : (isHighlighted
                                ? Border.all(color: Color(0xFFFF9800), width: 1.5)
                                : null),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              // Reply indicator
                              if (hasReply) ...[
                                GestureDetector(
                                  onTap: () {
                                    if (onJumpToMessage != null && messageData["replyTo"] != null) {
                                      onJumpToMessage(messageData["replyTo"]);
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    margin: EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: (isMe
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.1)),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border(
                                        left: BorderSide(
                                          color: isMe
                                              ? Colors.white
                                              : const Color.fromARGB(255, 4, 204, 240),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: IntrinsicWidth(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                messageData["replyToSender"] ?? "Unknown User",
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : const Color.fromARGB(255, 4, 204, 240),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.keyboard_arrow_up,
                                                size: 16,
                                                color: isMe
                                                    ? Colors.white70
                                                    : const Color.fromARGB(255, 4, 204, 240),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 2),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.5,
                                            ),
                                            child: Text(
                                              messageData["replyToMessage"] ?? "",
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white70
                                                    : (themeProvider.isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[600]),
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Admin deleted message indicator
                              if (messageData["messageType"] ==
                                  "admin_deleted") ...[
                                Container(
                                  padding: EdgeInsets.all(8),
                                  margin: EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "This message was deleted by admin",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Image content
                              if (isImageMessage && mediaUrl != null) ...[
                                GestureDetector(
                                  onTap: () => onImageTap(mediaUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: CachedNetworkImage(
                                      imageUrl: mediaUrl,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 200,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                          BorderRadius.circular(14),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF2196F3),
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            width: 200,
                                            height: 200,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                              BorderRadius.circular(14),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error_outline,
                                                    color: Colors.grey[600]),
                                                SizedBox(height: 4),
                                                Text(
                                                  "Failed to load",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                if (hasText) SizedBox(height: 8),
                              ],

                              // Video content
                              if (isVideoMessage && mediaUrl != null) ...[
                                GestureDetector(
                                  onTap: () => onVideoTap(mediaUrl),
                                  child: Container(
                                    width: 200,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Video thumbnail
                                          Container(
                                            width: double.infinity,
                                            height: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.grey[800]!,
                                                  Colors.grey[900]!,
                                                ],
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.video_library,
                                              color: Colors.white54,
                                              size: 40,
                                            ),
                                          ),
                                          // Play button overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                              BorderRadius.circular(30),
                                            ),
                                            padding: EdgeInsets.all(12),
                                            child: Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          // Video label
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.videocam,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "Video",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                      FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasText) SizedBox(height: 8),
                              ],

                              // Text message content
                              if (messageData["messageType"] ==
                                  "admin_deleted") ...[
                                Text(
                                  "This message was deleted by admin",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ] else if (hasText) ...[
                                Text(
                                  messageData["message"],
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : (themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],

                              SizedBox(height: 4),

                              // NEW: Voting buttons and counts
                              if (messageData["messageType"] != "admin_deleted")
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Upvote button
                                    GestureDetector(
                                      onTap: () => onVote(messageId, true),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: userVote == 'upvote'
                                              ? Color(0xFF4CAF50)
                                              .withOpacity(0.2)
                                              : Colors.transparent,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: userVote == 'upvote'
                                              ? Border.all(
                                            color: Color(0xFF4CAF50),
                                            width: 1.5,
                                          )
                                              : Border.all(
                                            color: Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedSwitcher(
                                              duration:
                                              Duration(milliseconds: 200),
                                              child: Icon(
                                                userVote == 'upvote'
                                                    ? Icons.thumb_up
                                                    : Icons.thumb_up_outlined,
                                                key: ValueKey(
                                                    userVote == 'upvote'),
                                                size: 14,
                                                color: userVote == 'upvote'
                                                    ? Color(0xFF4CAF50)
                                                    : (isMe
                                                    ? Colors.white70
                                                    : (themeProvider
                                                    .isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors
                                                    .grey[600])),
                                              ),
                                            ),
                                            if (voteCounts['upvotes']! > 0) ...[
                                              SizedBox(width: 4),
                                              AnimatedSwitcher(
                                                duration:
                                                Duration(milliseconds: 200),
                                                child: Text(
                                                  '${voteCounts['upvotes']}',
                                                  key: ValueKey(
                                                      'upvotes-${voteCounts['upvotes']}'),
                                                  style: TextStyle(
                                                    color: userVote == 'upvote'
                                                        ? Color(0xFF4CAF50)
                                                        : (isMe
                                                        ? Colors.white70
                                                        : (themeProvider
                                                        .isDarkMode
                                                        ? Colors
                                                        .grey[400]
                                                        : Colors.grey[
                                                    600])),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 8),

                                    // Downvote button
                                    GestureDetector(
                                      onTap: () => onVote(messageId, false),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: userVote == 'downvote'
                                              ? Colors.red.withOpacity(0.2)
                                              : Colors.transparent,
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: userVote == 'downvote'
                                              ? Border.all(
                                            color: Colors.red,
                                            width: 1.5,
                                          )
                                              : Border.all(
                                            color: Colors.transparent,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            AnimatedSwitcher(
                                              duration:
                                              Duration(milliseconds: 200),
                                              child: Icon(
                                                userVote == 'downvote'
                                                    ? Icons.thumb_down
                                                    : Icons.thumb_down_outlined,
                                                key: ValueKey(
                                                    userVote == 'downvote'),
                                                size: 14,
                                                color: userVote == 'downvote'
                                                    ? Colors.red
                                                    : (isMe
                                                    ? Colors.white70
                                                    : (themeProvider
                                                    .isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors
                                                    .grey[600])),
                                              ),
                                            ),
                                            if (voteCounts['downvotes']! >
                                                0) ...[
                                              SizedBox(width: 4),
                                              AnimatedSwitcher(
                                                duration:
                                                Duration(milliseconds: 200),
                                                child: Text(
                                                  '${voteCounts['downvotes']}',
                                                  key: ValueKey(
                                                      'downvotes-${voteCounts['downvotes']}'),
                                                  style: TextStyle(
                                                    color: userVote ==
                                                        'downvote'
                                                        ? Colors.red
                                                        : (isMe
                                                        ? Colors.white70
                                                        : (themeProvider
                                                        .isDarkMode
                                                        ? Colors
                                                        .grey[400]
                                                        : Colors.grey[
                                                    600])),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Spacer for timestamp
                                    if (timeString.isNotEmpty ||
                                        messageData["isEdited"] == true)
                                      Spacer(),

                                    // Timestamp and edited indicator
                                    if (timeString.isNotEmpty) ...[
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white70
                                              : (themeProvider.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                    if (messageData["isEdited"] == true) ...[
                                      SizedBox(width: 4),
                                      Text(
                                        "(edited)",
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white70
                                              : (themeProvider.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        onReply(
                                          messageData["key"] ?? "",
                                          messageData["message"] ??
                                              (isImageMessage
                                                  ? "Image"
                                                  : isVideoMessage
                                                  ? "Video"
                                                  : "Message"),
                                          messageData["senderName"] ??
                                              "Unknown User",
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.reply,
                                          size: 14,
                                          color: themeProvider.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
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

  /// Helper function to get vote counts from data
  static Map<String, int> _getVoteCountsFromData(Map<String, dynamic> voteData) {
    int upvotes = 0;
    int downvotes = 0;

    voteData.forEach((userId, vote) {
      if (vote == true) {
        upvotes++;
      } else if (vote == false) {
        downvotes++;
      }
    });

    return {'upvotes': upvotes, 'downvotes': downvotes};
  }

  /// Build disclaimer banner
  static Widget buildDisclaimerBanner(
    ThemeProvider themeProvider,
    AnimationController disclaimerController,
    VoidCallback onClose,
  ) {
    return AnimatedBuilder(
      animation: disclaimerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - disclaimerController.value)),
          child: Opacity(
            opacity: disclaimerController.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2196F3).withOpacity(0.9),
                    Color(0xFF2196F3).withOpacity(0.7),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Be respectful • No inappropriate content • Keep discussions constructive",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close,
                          size: 16, color: Colors.white.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build edit indicator
  static Widget buildEditIndicator(
    ThemeProvider themeProvider,
    bool isEditing,
    String? originalMessage,
    VoidCallback onCancel,
  ) {
    if (!isEditing) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Colors.orange, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, size: 16, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing message',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  originalMessage ?? '',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              Icons.close,
              size: 18,
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build reply indicator
  static Widget buildReplyIndicator(
    ThemeProvider themeProvider,
    bool isReplying,
    String? replyingToSender,
    String? replyingToMessage,
    VoidCallback onCancel,
  ) {
    if (!isReplying) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
              color: const Color.fromARGB(255, 4, 204, 240), width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply,
              size: 16, color: const Color.fromARGB(255, 4, 204, 240)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to $replyingToSender',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 4, 204, 240),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  replyingToMessage ?? '',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              Icons.close,
              size: 18,
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Build date separator
  static Widget buildDateSeparator(
      String dateText, ThemeProvider themeProvider) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: themeProvider.isDarkMode
                  ? Colors.grey[600]
                  : Colors.grey[300],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.grey[700]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              dateText,
              style: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.grey[300]
                    : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: themeProvider.isDarkMode
                  ? Colors.grey[600]
                  : Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  static Widget buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
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
            "Start a conversation or share media",
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

  /// Build terms dialog
  static Widget buildTermsDialog(
    BuildContext context,
    ThemeProvider themeProvider,
    VoidCallback onAgree,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenHeight < 700 || screenWidth < 400;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 20 : 40,
          ),
          child: Container(
            width: screenWidth > 500 ? 450 : screenWidth * 0.9,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
              maxWidth: screenWidth > 500 ? 450 : screenWidth * 0.9,
            ),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
                // Header with icon
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.gavel,
                          size: isSmallScreen ? 32 : 40,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 20),

                      // Title
                      Text(
                        "Terms & Community Guidelines",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Terms content - Flexible height
                Flexible(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24),
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ForumLogic.buildTermsSection(
                            "Discussion Forum Guidelines",
                            [
                              "Be respectful and courteous to all participants",
                              "No abusive, offensive, or discriminatory language",
                              "Keep discussions constructive and on-topic",
                              "No spam, advertising, or promotional content",
                              "Respect privacy - no sharing personal information",
                              "Report inappropriate content to moderators"
                            ],
                            themeProvider.isDarkMode,
                            isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          ForumLogic.buildTermsSection(
                            "Media Sharing Guidelines",
                            [
                              "No inappropriate, explicit, or offensive images/videos",
                              "Keep file sizes reasonable (max 50MB for videos)",
                              "Only share content you have rights to",
                              "Videos are limited to 5 minutes duration",
                              "No copyrighted material without permission"
                            ],
                            themeProvider.isDarkMode,
                            isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          ForumLogic.buildTermsSection(
                            "Terms of Use",
                            [
                              "You must be 13+ years old to participate",
                              "Content posted becomes part of public discussion",
                              "We reserve the right to moderate content",
                              "Violations may result in restricted access",
                              "Use at your own risk and responsibility"
                            ],
                            themeProvider.isDarkMode,
                            isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          ForumLogic.buildTermsSection(
                            "Privacy & Data",
                            [
                              "Messages and media are stored securely in our database",
                              "Your display name will be visible to others",
                              "We don't share personal data with third parties",
                              "You can request data deletion anytime"
                            ],
                            themeProvider.isDarkMode,
                            isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom section with agreement text and buttons
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      // Agreement text
                      Text(
                        "By clicking 'I Agree', you acknowledge that you have read and agree to abide by these terms and guidelines.",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.grey[400]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: onAgree,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2196F3),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 10 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                "I Agree",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen image viewer widget
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                onPressed: () {
                  // Add download functionality if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Download feature coming soon!"),
                      backgroundColor: Color(0xFF2196F3),
                    ),
                  );
                },
                icon: Icon(Icons.download, color: Colors.white),
              ),
            ],
          ),
          body: Center(
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                  strokeWidth: 2,
                ),
              ),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      "Failed to load image",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Go Back"),
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
}

/// Full-screen video viewer widget
class FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoViewer({super.key, required this.videoUrl});

  @override
  _FullScreenVideoViewerState createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      _controller.play();

      // Auto-hide controls after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Download feature coming soon!"),
                        backgroundColor: Color(0xFF2196F3),
                      ),
                    );
                  },
                  icon: Icon(Icons.download, color: Colors.white),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Center(
          child: _hasError
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      "Failed to load video",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Go Back"),
                    ),
                  ],
                )
              : !_isInitialized
                  ? CircularProgressIndicator(
                      color: Color(0xFF2196F3),
                      strokeWidth: 2,
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (_showControls)
                          Container(
                            color: Colors.black26,
                            child: Center(
                              child: IconButton(
                                onPressed: _togglePlayPause,
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        if (_showControls)
                          Positioned(
                            bottom: 50,
                            left: 20,
                            right: 20,
                            child: VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: Color(0xFF2196F3),
                                bufferedColor: Colors.grey,
                                backgroundColor: Colors.grey[800]!,
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}
