import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nagarvikas/screen/discussion/search_message.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../theme/theme_provider.dart';
import 'emoji_picker.dart';
import 'forum_logic.dart';
import 'forum_animations.dart';
import 'message_reporting_screen.dart';
import 'message_widgets.dart';
import 'poll_creation_widget.dart';
import 'package:flutter/services.dart';
import '../../service/eveyone_notification_service.dart';
import '../../widgets/mention_text_field.dart';
import '../../service/notification_service.dart';
import 'admin_only_manager.dart';

/// DiscussionForum with Image and Video Sharing
/// Enhanced real-time chat interface with image/video upload and full-screen viewing capabilities
class DiscussionForum extends StatefulWidget {
  final bool isAdmin;
  const DiscussionForum({super.key, this.isAdmin = false});

  @override
  DiscussionForumState createState() => DiscussionForumState();
}

class DiscussionForumState extends State<DiscussionForum>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref("discussion/");
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users/");
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  String? userId;
  String? currentUserName;
  bool _showDisclaimer = true;
  bool _hasAgreedToTerms = false;
  bool _showTermsDialog = false;
  bool _isUploading = false;
  bool _isAdmin = false;
  bool _isUserBanned = false;
  String? _highlightedMessageId;
  Timer? _highlightTimer;
  Map<String, Map<String, dynamic>> _messageVotes = {}; // Cache message votes
  final DatabaseReference _votesRef = FirebaseDatabase.instance.ref("votes/");
  StreamSubscription<DatabaseEvent>? _everyoneNotificationSubscription;
  bool _hasEveryoneMention = false;
  OverlayEntry? _mentionOverlay;
  bool _isAdminOnlyMode = false;
  bool _isGovAdmin = false;
  StreamSubscription<DatabaseEvent>? _adminOnlySubscription;

  Map<String, Map<String, dynamic>> _messageReactions =
      {}; // Cache message reactions
  final DatabaseReference _reactionsRef =
      FirebaseDatabase.instance.ref("reactions/");
  String? _selectedMessageForReaction;
  OverlayEntry? _reactionPickerOverlay;

// Animation controllers for enhanced UI
  late AnimationController _sendButtonAnimationController;
  late AnimationController _messageAnimationController;
  late AnimationController _disclaimerController;
  late AnimationController _emojiAnimationController;
  late Animation<double> _sendButtonScaleAnimation;
  late Animation<double> _messageSlideAnimation;
  late Animation<double> _emojiScaleAnimation;
  final FocusNode _textFieldFocusNode = FocusNode();

  bool _isTyping = false;
  String? _replyingToMessageId;
  String? _replyingToMessage;
  String? _replyingToSender;
  bool _isReplying = false;
  bool _showEmojiPicker = false;
  final GlobalKey _messagesListKey = GlobalKey();
  final Map<String, GlobalKey> _messageKeys = {};
  DateTime? _clearChatTimestamp; // Track when chat was cleared
  bool _showRestoreButton = false; // Show restore button when chat is cleared

  // Media attachment preview
  File? _attachedMediaFile;
  String? _attachedMediaUrl;
  String? _attachedMediaType;
  bool _showMediaPreview = false;

// Edit message functionality
  bool _isEditing = false;
  String? _editingMessageId;
  String? _originalMessage;

  String _selectedEmojiCategory = 'Smileys';

// Go down button visibility
  bool _showGoDownButton = false;

// Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _isAdmin = widget.isAdmin;
    ForumLogic.getCurrentUserName(
      userId,
      _usersRef,
      (name) => setState(() => currentUserName = name),
    );
    _checkTermsAgreement();
    _checkUserBanStatus();
    _loadChatClearTimestamp();
    _messagesRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final messagesData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        messagesData.forEach((messageId, messageData) {
          _loadMessageVotes(messageId);
        });
      }
    });
    _initSpeech(); // Initialize speech to text

    ForumAnimations.initAnimations(
      this,
      (controllers) {
        _sendButtonAnimationController = controllers['sendButton']!;
        _messageAnimationController = controllers['message']!;
        _disclaimerController = controllers['disclaimer']!;
        _emojiAnimationController = controllers['emoji']!;
      },
      (animations) {
        _sendButtonScaleAnimation = animations['sendButtonScale']!;
        _messageSlideAnimation = animations['messageSlide']!;
        _emojiScaleAnimation = animations['emojiScale']!;
      },
    );

    if (userId != null) {
      _everyoneNotificationSubscription = EveryoneNotificationService()
          .listenForEveryoneNotifications(userId!, (notificationData) {
        // Show local notification
        NotificationService().showEveryoneNotification(
          senderName: notificationData['senderName'] ?? 'Someone',
          messageText: notificationData['messageText'] ?? '',
          messageId: notificationData['messageId'],
        );
      });
    }
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
        _hasEveryoneMention = EveryoneNotificationService.containsEveryone(
            _messageController.text);
      });
    });
    // Auto-scroll to bottom when new messages arrive (only if user is already near bottom)
    _messagesRef
        .orderByChild("timestamp")
        .limitToLast(1)
        .onChildAdded
        .listen((event) {
      if (mounted) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (_scrollController.hasClients) {
            final isNearBottom = _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200;

            if (isNearBottom) {
              // Force jump to absolute bottom
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);

              // Additional jumps to handle media loading
              for (int i = 1; i <= 5; i++) {
                Future.delayed(Duration(milliseconds: i * 200), () {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
              }
            }
          }
        });
      }
    });

    // Listen for scroll changes to show/hide go down button
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isAtBottom = _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100;

        if (isAtBottom && _showGoDownButton) {
          setState(() {
            _showGoDownButton = false;
          });
        } else if (!isAtBottom && !_showGoDownButton) {
          setState(() {
            _showGoDownButton = true;
          });
        }
      }
    });
    _messagesRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final messagesData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        messagesData.forEach((messageId, messageData) {
          _loadMessageReactions(messageId);
        });
      }
    });
    _initAdminOnlyMode();
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _sendButtonAnimationController.dispose();
    _messageAnimationController.dispose();
    _disclaimerController.dispose();
    _emojiAnimationController.dispose();
    _highlightTimer?.cancel();
    _everyoneNotificationSubscription?.cancel();
    _mentionOverlay?.remove();
    _reactionPickerOverlay?.remove();
    _adminOnlySubscription?.cancel();
    super.dispose();
  }

  // Initialize admin-only mode functionality
  void _initAdminOnlyMode() async {
    // Check if current user is a gov admin
    _isGovAdmin = await AdminOnlyManager.checkGovAdminStatus(userId, _isAdmin);

    // Listen to admin-only mode changes
    _adminOnlySubscription =
        AdminOnlyManager.listenToAdminOnlyMode((isAdminOnly) {
      if (mounted) {
        setState(() {
          _isAdminOnlyMode = isAdminOnly;
        });
      }
    });

    // Update state
    if (mounted) {
      setState(() {});
    }
  }

  /// Load reactions for a specific message
  Future<void> _loadMessageReactions(String messageId) async {
    try {
      final snapshot = await _reactionsRef.child(messageId).once();
      if (snapshot.snapshot.exists) {
        final reactionsData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          _messageReactions[messageId] = reactionsData;
        });
      } else {
        setState(() {
          _messageReactions[messageId] = {};
        });
      }
    } catch (e) {
      print('Error loading reactions for message $messageId: $e');
    }
  }

  /// Show reaction picker overlay
  void _showReactionPicker(
      BuildContext context, String messageId, Offset tapPosition) {
    if (_isUserBanned) {
      Fluttertoast.showToast(msg: "You are banned from reacting to messages");
      return;
    }

    _selectedMessageForReaction = messageId;

    // Remove existing overlay if any
    _reactionPickerOverlay?.remove();

    _reactionPickerOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: tapPosition.dx - 150,
        top: tapPosition.dy - 60,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(30),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[800]
                      : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['👍', '❤️', '😂', '😮', '😢', '😡']
                      .map((emoji) => GestureDetector(
                            onTap: () => _reactToMessage(messageId, emoji),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                emoji,
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context)?.insert(_reactionPickerOverlay!);

    // Auto-hide after 5 seconds
    Timer(Duration(seconds: 5), () {
      _hideReactionPicker();
    });
  }

  /// Hide reaction picker overlay
  void _hideReactionPicker() {
    _reactionPickerOverlay?.remove();
    _reactionPickerOverlay = null;
    _selectedMessageForReaction = null;
  }

  /// React to a message
  Future<void> _reactToMessage(String messageId, String emoji) async {
    if (userId == null) return;

    // Check if user can react (not banned and if admin-only mode, user must be admin)
    if (!AdminOnlyManager.canUserSendMessage(
      isAdminOnlyMode: _isAdminOnlyMode,
      isAdmin: _isAdmin,
      isUserBanned: _isUserBanned,
    )) {
      Fluttertoast.showToast(
        msg: AdminOnlyManager.getBannedMessage(
          isAdminOnlyMode: _isAdminOnlyMode,
          isAdmin: _isAdmin,
          isUserBanned: _isUserBanned,
        ),
      );
      return;
    }

    _hideReactionPicker();

    try {
      final userReactionRef = _reactionsRef.child(messageId).child(userId!);
      final snapshot = await userReactionRef.once();

      if (snapshot.snapshot.exists) {
        final currentReaction =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        if (currentReaction['emoji'] == emoji) {
          // Same reaction - remove it
          await userReactionRef.remove();
          Fluttertoast.showToast(msg: "Reaction removed");
        } else {
          // Different reaction - update it
          await userReactionRef.update({
            'emoji': emoji,
            'timestamp': ServerValue.timestamp,
            'userName': currentUserName ?? 'Unknown User',
          });
        }
      } else {
        // New reaction
        await userReactionRef.set({
          'emoji': emoji,
          'timestamp': ServerValue.timestamp,
          'userName': currentUserName ?? 'Unknown User',
        });
      }

      // Reload reactions for this message
      await _loadMessageReactions(messageId);
    } catch (e) {
      print('Error reacting to message: $e');
      Fluttertoast.showToast(msg: "Failed to add reaction");
    }
  }

  /// Show who reacted to a message
  void _showReactionDetails(String messageId, String emoji) {
    final reactions = _messageReactions[messageId] ?? {};
    final usersWithThisEmoji = <Map<String, dynamic>>[];

    reactions.forEach((userId, reactionData) {
      if (reactionData is Map && reactionData['emoji'] == emoji) {
        usersWithThisEmoji.add({
          'userId': userId,
          'userName': reactionData['userName'] ?? 'Unknown User',
          'timestamp': reactionData['timestamp'],
        });
      }
    });

    if (usersWithThisEmoji.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    Text(
                      emoji,
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${usersWithThisEmoji.length} ${usersWithThisEmoji.length == 1 ? 'person' : 'people'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Users list
                ...usersWithThisEmoji.map((user) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ForumLogic.getAvatarColor(user['userName']),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user['userName']
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        user['userName'],
                        style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: user['userId'] == userId
                          ? GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _removeReaction(messageId);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.red, width: 1),
                                ),
                                child: Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    )),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Remove user's reaction
  Future<void> _removeReaction(String messageId) async {
    if (userId == null) return;

    try {
      await _reactionsRef.child(messageId).child(userId!).remove();
      await _loadMessageReactions(messageId);
      Fluttertoast.showToast(msg: "Reaction removed");
    } catch (e) {
      print('Error removing reaction: $e');
      Fluttertoast.showToast(msg: "Failed to remove reaction");
    }
  }

  /// Get reaction summary for a message
  Map<String, int> _getReactionSummary(String messageId) {
    final reactions = _messageReactions[messageId] ?? {};
    final summary = <String, int>{};

    reactions.forEach((userId, reactionData) {
      if (reactionData is Map && reactionData['emoji'] != null) {
        final emoji = reactionData['emoji'];
        summary[emoji] = (summary[emoji] ?? 0) + 1;
      }
    });

    return summary;
  }

  /// Load votes for a specific message
  Future<void> _loadMessageVotes(String messageId) async {
    try {
      final snapshot = await _votesRef.child(messageId).once();
      if (snapshot.snapshot.exists) {
        final votesData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        setState(() {
          _messageVotes[messageId] = votesData;
        });
      } else {
        // Important: Clear votes if no data exists (after removal)
        setState(() {
          _messageVotes[messageId] = {};
        });
      }
    } catch (e) {
      print('Error loading votes for message $messageId: $e');
    }
  }

  Widget _buildEnhancedTextInput(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[700] : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_isTyping || _isEditing)
              ? Color(0xFF2196F3)
              : (themeProvider.isDarkMode
                  ? Colors.grey[600]!
                  : Colors.grey[300]!),
          width: (_isTyping || _isEditing) ? 2 : 1,
        ),
        boxShadow: (_isTyping || _isEditing || _showMediaPreview)
            ? [
                BoxShadow(
                  color: Color(0xFF2196F3)
                      .withOpacity(0.2), // Remove _hasEveryoneMention condition
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Text field with @everyone support
              Expanded(
                child: MentionTextField(
                  controller: _messageController,
                  focusNode: _textFieldFocusNode,
                  hintText: _isEditing
                      ? "Edit your message..."
                      : (_isReplying
                          ? "Reply to ${_replyingToSender}..."
                          : (_isListening
                              ? "Listening..."
                              : "Type a message...")),
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  minLines: 1,
                  onChanged: (text) {
                    if (text.length > 1000) {
                      _messageController.text = text.substring(0, 1000);
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: 1000),
                      );
                    }
                  },
                  onTap: () {
                    // Hide emoji picker when text field is tapped
                    if (_showEmojiPicker) {
                      setState(() {
                        _showEmojiPicker = false;
                      });
                      _emojiAnimationController.reverse();
                    }
                    // Auto scroll if at bottom when keyboard opens
                    Future.delayed(Duration(milliseconds: 300), () {
                      if (!_showGoDownButton && _scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                ),
              ),

              // Mic button
              GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  margin: EdgeInsets.only(right: 4),
                  padding: EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Color(0xFF4CAF50).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Color(0xFF4CAF50)
                        : (themeProvider.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                    size: 20,
                  ),
                ),
              ),

              // Emoji button
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Future.delayed(Duration(milliseconds: 100), () {
                    _toggleEmojiPicker();
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 16),
                  padding: EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: _showEmojiPicker
                        ? Color(0xFF2196F3).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                    color: _showEmojiPicker
                        ? Color(0xFF2196F3)
                        : (themeProvider.isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600]),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ADD THIS METHOD - Enhanced send button with @everyone confirmation
  Widget _buildSendButton(ThemeProvider themeProvider) {
    return AnimatedBuilder(
      animation: _sendButtonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _sendButtonScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: (_isTyping || _isEditing || _showMediaPreview)
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1976D2),
                        Color(0xFF2196F3)
                      ], // Remove _hasEveryoneMention condition
                    )
                  : null,
              color: !(_isTyping || _isEditing || _showMediaPreview)
                  ? (themeProvider.isDarkMode
                      ? Colors.grey[600]
                      : Colors.grey[400])
                  : null,
              shape: BoxShape.circle,
              boxShadow: (_isTyping || _isEditing || _showMediaPreview)
                  ? [
                      BoxShadow(
                        color: Color(0xFF2196F3).withOpacity(
                            0.3), // Remove _hasEveryoneMention condition
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
                onTap: (_isTyping || _isEditing || _showMediaPreview)
                    ? () {
                        _sendMessage(); // Remove confirmation dialog
                      }
                    : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  child: Icon(
                    _isEditing
                        ? Icons.check
                        : (_isTyping
                            ? Icons.send_rounded
                            : Icons
                                .send_outlined), // Remove _hasEveryoneMention condition
                    color: Colors.white,
                    size: (_isTyping || _isEditing || _showMediaPreview)
                        ? 24
                        : 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Vote on a message (upvote or downvote)
  Future<void> _voteMessage(String messageId, bool isUpvote) async {
    if (userId == null) return;

    // Check if user can vote (not banned and if admin-only mode, user must be admin)
    if (!AdminOnlyManager.canUserSendMessage(
      isAdminOnlyMode: _isAdminOnlyMode,
      isAdmin: _isAdmin,
      isUserBanned: _isUserBanned,
    )) {
      Fluttertoast.showToast(
        msg: AdminOnlyManager.getBannedMessage(
          isAdminOnlyMode: _isAdminOnlyMode,
          isAdmin: _isAdmin,
          isUserBanned: _isUserBanned,
        ),
      );
      return;
    }

    try {
      final voteRef = _votesRef.child(messageId).child(userId!);
      final snapshot = await voteRef.once();

      // Check current vote status
      String? currentVote;
      if (snapshot.snapshot.exists) {
        final voteData =
            Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        currentVote = voteData['type'];
      }

      // Determine new vote action
      if (currentVote == null) {
        // No previous vote - add new vote
        await voteRef.set({
          'type': isUpvote ? 'upvote' : 'downvote',
          'timestamp': ServerValue.timestamp,
          'voterName': currentUserName ?? 'Unknown User',
        });
      } else if ((currentVote == 'upvote' && isUpvote) ||
          (currentVote == 'downvote' && !isUpvote)) {
        // Same vote clicked - REMOVE the vote (toggle off)
        await voteRef.remove();

        // Immediately update local state to reflect removal
        setState(() {
          if (_messageVotes[messageId] != null) {
            _messageVotes[messageId]!.remove(userId!);
          }
        });

        // Show feedback to user
        Fluttertoast.showToast(
          msg: isUpvote ? "Upvote removed" : "Downvote removed",
          toastLength: Toast.LENGTH_SHORT,
        );
      } else {
        // Different vote clicked - change vote type
        await voteRef.set({
          'type': isUpvote ? 'upvote' : 'downvote',
          'timestamp': ServerValue.timestamp,
          'voterName': currentUserName ?? 'Unknown User',
        });

        // Show feedback to user
        Fluttertoast.showToast(
          msg: isUpvote ? "Changed to upvote" : "Changed to downvote",
          toastLength: Toast.LENGTH_SHORT,
        );
      }

      // Always refresh votes after any operation to ensure UI consistency
      await _loadMessageVotes(messageId);
    } catch (e) {
      print('Error voting on message: $e');
      Fluttertoast.showToast(msg: "Failed to vote. Please try again.");
    }
  }

  /// Check if current user has voted on a message
  String? _getUserVote(String messageId) {
    if (userId == null) return null;
    final votes = _messageVotes[messageId] ?? {};
    final userVote = votes[userId!];
    if (userVote is Map && userVote['type'] != null) {
      return userVote['type'];
    }
    return null;
  }

  /// Scroll to bottom of messages - goes to absolute latest message
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Force immediate scroll to current max extent
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

      // Then use multiple delayed jumps to handle dynamic content loading
      for (int i = 1; i <= 10; i++) {
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    }
  }

  Future<void> _scrollToMessage(String messageId) async {
    try {
      // Get message details
      final messageSnapshot = await _messagesRef.child(messageId).once();

      // Get all messages to find the position
      final allMessagesSnapshot =
          await _messagesRef.orderByChild("timestamp").once();

      if (!allMessagesSnapshot.snapshot.exists) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No messages found'), backgroundColor: Colors.red),
        );
        return;
      }

      // Convert to list and sort by timestamp
      Map<dynamic, dynamic> messagesMap =
          allMessagesSnapshot.snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> messagesList = messagesMap.entries
          .map((e) => {"key": e.key, ...Map<String, dynamic>.from(e.value)})
          .toList();

      messagesList.sort((a, b) => a["timestamp"].compareTo(b["timestamp"]));

      // Find target index
      int targetIndex =
          messagesList.indexWhere((msg) => msg["key"] == messageId);
      if (targetIndex == -1) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Message not found in current view'),
              backgroundColor: Colors.red),
        );
        return;
      }

      // Highlight message
      setState(() => _highlightedMessageId = messageId);

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Estimate scroll position
      double estimatedItemHeight = 100.0;
      double scrollPosition = targetIndex * estimatedItemHeight;

      // Smooth scroll
      await Future.delayed(Duration(milliseconds: 50)); // Wait for UI to update
      if (_scrollController.hasClients) {
        double maxScrollExtent = _scrollController.position.maxScrollExtent;
        double targetPosition = scrollPosition.clamp(0.0, maxScrollExtent);

        await _scrollController.animateTo(
          targetPosition,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }

      // Remove highlight after 1 second
      _highlightTimer?.cancel();
      _highlightTimer = Timer(Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _highlightedMessageId = null);
        }
      });
    } catch (e) {
      print('Error finding message: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error finding message. Please try again.'),
            backgroundColor: Colors.red),
      );
      setState(() => _highlightedMessageId = null);
    }
  }

  /// Clear chat locally (hide messages from this device only)
  /// Clear chat locally (hide messages from this device only)
  void _clearChatLocally() {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Clear Chat',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This will hide all current messages from your device only. Other users will still see all messages. You can restore them anytime using the restore button.',
              style: TextStyle(
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  await _saveChatClearTimestamp(now);
                  setState(() {
                    _clearChatTimestamp = now;
                    _showRestoreButton = true;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat cleared from this device'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
                child: Text(
                  'Clear Chat',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Restore all cleared chat messages
  void _restoreAllMessages() {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Restore Chat',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'This will restore all previously cleared messages. You will see the complete chat history again.',
              style: TextStyle(
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await _clearChatClearTimestamp();
                  setState(() {
                    _clearChatTimestamp = null;
                    _showRestoreButton = false;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All messages restored'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
                child: Text(
                  'Restore All',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show poll creation dialog
  void _showPollCreation() {
    if (!AdminOnlyManager.canUserSendMessage(
      isAdminOnlyMode: _isAdminOnlyMode,
      isAdmin: _isAdmin,
      isUserBanned: _isUserBanned,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                AdminOnlyManager.getBannedIcon(
                  isAdminOnlyMode: _isAdminOnlyMode,
                  isAdmin: _isAdmin,
                  isUserBanned: _isUserBanned,
                ),
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(AdminOnlyManager.getBannedMessage(
                  isAdminOnlyMode: _isAdminOnlyMode,
                  isAdmin: _isAdmin,
                  isUserBanned: _isUserBanned,
                )),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return PollCreationWidget(
            themeProvider: themeProvider,
            onPollCreated: _createPoll,
          );
        },
      ),
    );
  }

  /// Create and send poll
  void _createPoll(
      String question, List<String> options, bool allowMultipleAnswers) async {
    if (currentUserName == null || userId == null) return;

    try {
      // Create poll data
      final pollId = _messagesRef.push().key!;
      final pollData = {
        'question': question,
        'options': options,
        'allowMultipleAnswers': allowMultipleAnswers,
        'createdBy': userId,
        'createdAt': ServerValue.timestamp,
        'votes':
            {}, // Will store votes as: {option: {userId: {votedAt, voterName}}}
      };

      // Save poll to polls collection
      await FirebaseDatabase.instance.ref("polls/$pollId").set(pollData);

      // Create message referencing the poll
      final messageData = {
        'senderId': userId,
        'senderName': currentUserName,
        'messageType': 'poll',
        'pollId': pollId,
        'timestamp': ServerValue.timestamp,
        'createdAt': ServerValue.timestamp,
      };

      await _messagesRef.child(pollId).set(messageData);

      // Clear any reply state
      _clearReply();

      // Hide emoji picker if open
      if (_showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
        _emojiAnimationController.reverse();
      }

      // Scroll to bottom
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error creating poll: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create poll. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _hideDisclaimer() {
    if (_showDisclaimer) {
      _disclaimerController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showDisclaimer = false;
          });
        }
      });
    }
  }

  /// Toggle emoji picker visibility
  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
      _emojiAnimationController.reverse();
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_textFieldFocusNode);
      });
    } else {
      FocusScope.of(context).unfocus();
      Future.delayed(Duration(milliseconds: 200), () {
        setState(() {
          _showEmojiPicker = true;
        });
        _emojiAnimationController.forward();
      });
    }
  }

  /// Insert emoji into text field
  void _insertEmoji(String emoji) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _messageController.value = _messageController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  // Initialize speech to text
  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  /// Start/stop listening for speech
  void _toggleListening() async {
    if (!_speechEnabled) {
      Fluttertoast.showToast(msg: "Speech recognition not available");
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      _lastWords = '';
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  /// Handle speech recognition results
  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      if (result.finalResult) {
        // Append to existing text or replace
        String currentText = _messageController.text;
        if (currentText.isEmpty) {
          _messageController.text = _lastWords;
        } else {
          _messageController.text = currentText + ' ' + _lastWords;
        }
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
        _isListening = false;
      }
    });
  }

  /// Check if user has agreed to terms and conditions
  void _checkTermsAgreement() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'terms_agreed_${userId ?? 'anonymous'}';
    bool hasAgreed = prefs.getBool(key) ?? false;

    setState(() {
      _hasAgreedToTerms = hasAgreed;
      _showTermsDialog = !hasAgreed;
    });
  }

  /// Check if current user is banned
  void _checkUserBanStatus() async {
    if (userId == null) return;

    DatabaseReference bannedUsersRef =
        FirebaseDatabase.instance.ref("banned_users/$userId");
    bannedUsersRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _isUserBanned = event.snapshot.exists;
        });
      }
    });
  }

  /// Load chat clear timestamp from SharedPreferences
  Future<void> _loadChatClearTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'chat_clear_timestamp_${userId ?? 'anonymous'}';
    int? timestamp = prefs.getInt(key);

    setState(() {
      if (timestamp != null) {
        _clearChatTimestamp = DateTime.fromMillisecondsSinceEpoch(timestamp);
        _showRestoreButton = true;
      } else {
        _clearChatTimestamp = null;
        _showRestoreButton = false;
      }
    });
  }

  /// Save chat clear timestamp to SharedPreferences
  Future<void> _saveChatClearTimestamp(DateTime timestamp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'chat_clear_timestamp_${userId ?? 'anonymous'}';
    await prefs.setInt(key, timestamp.millisecondsSinceEpoch);
  }

  /// Clear the saved chat clear timestamp
  Future<void> _clearChatClearTimestamp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'chat_clear_timestamp_${userId ?? 'anonymous'}';
    await prefs.remove(key);
  }

  /// Check if a message should be hidden based on clear timestamp
  bool _shouldHideMessage(Map<String, dynamic> messageData) {
    if (_clearChatTimestamp == null) return false;

    try {
      final messageTimestamp =
          messageData["createdAt"] ?? messageData["timestamp"];
      if (messageTimestamp is int) {
        final messageDate =
            DateTime.fromMillisecondsSinceEpoch(messageTimestamp);
        return messageDate.isBefore(_clearChatTimestamp!);
      }
    } catch (e) {
      print('Error checking message timestamp: $e');
    }
    return false;
  }

  /// Ban a user (admin only)
  void _banUser(String userIdToBan, String userName) {
    if (!_isAdmin) return;

    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
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
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseDatabase.instance
                      .ref("banned_users/$userIdToBan")
                      .set({
                    "banned_by": userId,
                    "banned_at": ServerValue.timestamp,
                    "user_name": userName,
                    "reason": "Admin ban",
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$userName has been banned')),
                  );
                },
                child: Text(
                  'Ban User',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _agreeToTerms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'terms_agreed_${userId ?? 'anonymous'}';
    await prefs.setBool(key, true);

    setState(() {
      _hasAgreedToTerms = true;
      _showTermsDialog = false;
    });
  }

  // Upload media to Cloudinary (supports both images and videos)
  Future<String?> _uploadToCloudinary(File file, {bool isVideo = false}) async {
    const cloudName = 'dved2q851';
    const uploadPreset = 'flutter_uploads';
    final url =
        'https://api.cloudinary.com/v1_1/$cloudName/${isVideo ? 'video' : 'image'}/upload';

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'upload_preset': uploadPreset,
        if (isVideo) 'resource_type': 'video',
      });
      final response = await Dio().post(url, data: formData);
      return response.data['secure_url'];
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // NEW: Show media selection bottom sheet (WhatsApp-like)
  void _showMediaOptions() {
    // Check if user can send messages before showing media options
    if (!AdminOnlyManager.canUserSendMessage(
      isAdminOnlyMode: _isAdminOnlyMode,
      isAdmin: _isAdmin,
      isUserBanned: _isUserBanned,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                AdminOnlyManager.getBannedIcon(
                  isAdminOnlyMode: _isAdminOnlyMode,
                  isAdmin: _isAdmin,
                  isUserBanned: _isUserBanned,
                ),
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(AdminOnlyManager.getBannedMessage(
                  isAdminOnlyMode: _isAdminOnlyMode,
                  isAdmin: _isAdmin,
                  isUserBanned: _isUserBanned,
                )),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 25),

                // Title
                Text(
                  'Share Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                SizedBox(height: 25),

                // First row - Media options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera Photo
                    _buildMediaOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      color: Color(0xFF4CAF50),
                      onTap: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                      themeProvider: themeProvider,
                    ),

                    // Gallery Photo
                    _buildMediaOption(
                      icon: Icons.photo_library,
                      label: 'Photo',
                      color: Color(0xFF2196F3),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                      themeProvider: themeProvider,
                    ),

                    // Video Camera
                    _buildMediaOption(
                      icon: Icons.videocam,
                      label: 'Video',
                      color: Color(0xFFFF5722),
                      onTap: () {
                        Navigator.pop(context);
                        _recordVideo();
                      },
                      themeProvider: themeProvider,
                    ),

                    // Gallery Video
                    _buildMediaOption(
                      icon: Icons.video_library,
                      label: 'Gallery',
                      color: Color(0xFF9C27B0),
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo();
                      },
                      themeProvider: themeProvider,
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Second row - Poll option (centered)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMediaOption(
                      icon: Icons.poll,
                      label: 'Poll',
                      color: Color(0xFFFF9800),
                      onTap: () {
                        Navigator.pop(context);
                        _showPollCreation();
                      },
                      themeProvider: themeProvider,
                    ),
                  ],
                ),

                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Build media option widget
  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    if (_isUploading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final imageFile = File(image.path);
      final imageUrl = await _uploadToCloudinary(imageFile, isVideo: false);

      if (imageUrl != null) {
        setState(() {
          _attachedMediaFile = imageFile;
          _attachedMediaUrl = imageUrl;
          _attachedMediaType = "image";
          _showMediaPreview = true;
          _isUploading = false;
        });
        FocusScope.of(context).requestFocus(_textFieldFocusNode);
      } else {
        setState(() {
          _isUploading = false;
        });
        Fluttertoast.showToast(
            msg: "Failed to upload image. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(msg: "Error picking image: $e");
    }
  }

  // Take photo with camera
  Future<void> _takePhoto() async {
    if (_isUploading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final imageFile = File(image.path);
      final imageUrl = await _uploadToCloudinary(imageFile, isVideo: false);

      if (imageUrl != null) {
        setState(() {
          _attachedMediaFile = imageFile;
          _attachedMediaUrl = imageUrl;
          _attachedMediaType = "image";
          _showMediaPreview = true;
          _isUploading = false;
        });
        FocusScope.of(context).requestFocus(_textFieldFocusNode);
      } else {
        setState(() {
          _isUploading = false;
        });
        Fluttertoast.showToast(
            msg: "Failed to upload image. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(msg: "Error taking photo: $e");
    }
  }

  // Pick video from gallery
  Future<void> _pickVideo() async {
    if (_isUploading) return;

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(minutes: 5),
      );

      if (video == null) return;

      setState(() {
        _isUploading = true;
      });

      final videoFile = File(video.path);
      final fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        Fluttertoast.showToast(
            msg:
                "Video file too large. Please choose a smaller file (max 50MB).");
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final videoUrl = await _uploadToCloudinary(videoFile, isVideo: true);

      if (videoUrl != null) {
        setState(() {
          _attachedMediaFile = videoFile;
          _attachedMediaUrl = videoUrl;
          _attachedMediaType = "video";
          _showMediaPreview = true;
          _isUploading = false;
        });
        FocusScope.of(context).requestFocus(_textFieldFocusNode);
      } else {
        setState(() {
          _isUploading = false;
        });
        Fluttertoast.showToast(
            msg: "Failed to upload video. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(msg: "Error picking video: $e");
    }
  }

  // Record video with camera
  Future<void> _recordVideo() async {
    if (_isUploading) return;

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(minutes: 5),
      );

      if (video == null) return;

      setState(() {
        _isUploading = true;
      });

      final videoFile = File(video.path);
      final fileSize = await videoFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        Fluttertoast.showToast(
            msg:
                "Video file too large. Please record a shorter video (max 50MB).");
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final videoUrl = await _uploadToCloudinary(videoFile, isVideo: true);

      if (videoUrl != null) {
        setState(() {
          _attachedMediaFile = videoFile;
          _attachedMediaUrl = videoUrl;
          _attachedMediaType = "video";
          _showMediaPreview = true;
          _isUploading = false;
        });
        FocusScope.of(context).requestFocus(_textFieldFocusNode);
      } else {
        setState(() {
          _isUploading = false;
        });
        Fluttertoast.showToast(
            msg: "Failed to upload video. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(msg: "Error recording video: $e");
    }
  }

  void _clearMediaPreview() {
    setState(() {
      _attachedMediaFile = null;
      _attachedMediaUrl = null;
      _attachedMediaType = null;
      _showMediaPreview = false;
    });
  }

  // Show image in full screen
  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  // Show video in full screen
  void _showFullScreenVideo(String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoViewer(videoUrl: videoUrl),
      ),
    );
  }

  void _sendMessage({String? mediaUrl, String? mediaType}) {
    // Check if user can send messages (banned or admin-only mode)
    if (!AdminOnlyManager.canUserSendMessage(
      isAdminOnlyMode: _isAdminOnlyMode,
      isAdmin: _isAdmin,
      isUserBanned: _isUserBanned,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                AdminOnlyManager.getBannedIcon(
                  isAdminOnlyMode: _isAdminOnlyMode,
                  isAdmin: _isAdmin,
                  isUserBanned: _isUserBanned,
                ),
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(AdminOnlyManager.getBannedMessage(
                  isAdminOnlyMode: _isAdminOnlyMode,
                  isAdmin: _isAdmin,
                  isUserBanned: _isUserBanned,
                )),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // Handle editing case
    if (_isEditing) {
      _saveEditedMessage();
      return;
    }

    // Use attached media if available, otherwise use provided parameters
    final finalMediaUrl = _attachedMediaUrl ?? mediaUrl;
    final finalMediaType = _attachedMediaType ?? mediaType;

    // Get message text and check for @everyone mention
    final messageText = _messageController.text.trim();
    final hasEveryoneMention =
        EveryoneNotificationService.containsEveryone(messageText);

    // Validate message content
    if ((messageText.isEmpty && finalMediaUrl == null) ||
        currentUserName == null) return;

    // Animate send button
    _sendButtonAnimationController.forward().then((_) {
      _sendButtonAnimationController.reverse();
    });

    // Prepare message data
    Map<String, dynamic> messageData = {
      "senderId": userId,
      "senderName": currentUserName,
      "timestamp": ServerValue.timestamp,
      "createdAt": ServerValue.timestamp,
    };

    // Add message text if present
    if (messageText.isNotEmpty) {
      messageData["message"] = messageText;
      // Mark if message contains @everyone
      if (hasEveryoneMention) {
        messageData["hasEveryoneMention"] = true;
      }
    }

    // Add media URL and type if present
    if (finalMediaUrl != null && finalMediaType != null) {
      messageData["mediaUrl"] = finalMediaUrl;
      messageData["messageType"] = finalMediaType;
    } else {
      messageData["messageType"] = "text";
    }

    // Add reply information if replying
    if (_isReplying && _replyingToMessageId != null) {
      messageData["replyTo"] = _replyingToMessageId;
      messageData["replyToMessage"] = _replyingToMessage ?? '';
      messageData["replyToSender"] = _replyingToSender ?? 'Unknown User';
    }

    // Send the message to Firebase
    final messageRef = _messagesRef.push();
    final messageId = messageRef.key!;

    messageRef.set(messageData).then((_) {
      print('Message sent successfully with ID: $messageId');

      // If message contains @everyone, send notifications to all users
      if (hasEveryoneMention && messageText.isNotEmpty) {
        print('Sending @everyone notifications for message: $messageId');

        EveryoneNotificationService()
            .sendEveryoneNotification(
          messageId: messageId,
          senderId: userId!,
          senderName: currentUserName!,
          messageText: messageText,
        )
            .then((_) {
          print('@everyone notifications sent successfully');

          // Show success feedback to sender
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.alternate_email, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Message sent to everyone successfully'),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }).catchError((error) {
          print('Error sending @everyone notification: $error');

          // Show error feedback to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Message sent but failed to notify all users'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // Retry sending @everyone notification
                  EveryoneNotificationService().sendEveryoneNotification(
                    messageId: messageId,
                    senderId: userId!,
                    senderName: currentUserName!,
                    messageText: messageText,
                  );
                },
              ),
            ),
          );
        });
      }
    }).catchError((error) {
      print('Error sending message: $error');

      // Show error feedback for message send failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text('Failed to send message. Please try again.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              // Retry sending the message
              _sendMessage(mediaUrl: finalMediaUrl, mediaType: finalMediaType);
            },
          ),
        ),
      );
      return; // Don't clear the input if message failed to send
    });

    // Clear input and states after successful message preparation
    _messageController.clear();
    _clearReply();
    _clearMediaPreview(); // Clear media preview after sending

    setState(() {
      _isTyping = false;
      _hasEveryoneMention = false; // Reset @everyone state
    });

    // Hide emoji picker after sending
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
      _emojiAnimationController.reverse();
    }

    // Force scroll to bottom after sending message with multiple attempts
    // This ensures the new message is visible even with media content
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

        // Additional jumps for media content loading
        // This handles cases where images/videos take time to load
        for (int i = 1; i <= 8; i++) {
          Future.delayed(Duration(milliseconds: i * 125), () {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    });

    // Add haptic feedback for successful message send
    HapticFeedback.lightImpact();
  }

  void _showEveryoneConfirmation(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  Icons.alternate_email,
                  color: Color(0xFF2196F3),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Notify Everyone?',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your message contains @everyone. This will send a notification to all users in the forum.',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Color(0xFF2196F3).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Color(0xFF2196F3), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use @everyone responsibly for important announcements only.',
                          style: TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Send to Everyone',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _replyToMessage(String messageId, String message, String senderName) {
    setState(() {
      _isReplying = true;
      _replyingToMessageId = messageId;
      _replyingToMessage = message;
      _replyingToSender = senderName;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

// Add this new method right after _replyToMessage
  void _jumpToMessage(String messageId) {
    final messageKey = _messageKeys[messageId];
    if (messageKey != null && messageKey.currentContext != null) {
      Scrollable.ensureVisible(
        messageKey.currentContext!,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3, // Position the message 30% from top of screen
      );

      // Add a brief highlight animation
      Future.delayed(Duration(milliseconds: 600), () {
        if (messageKey.currentContext != null) {
          // You can add a brief color flash here if desired
        }
      });
    }
  }

  void _clearReply() {
    setState(() {
      _isReplying = false;
      _replyingToMessageId = null;
      _replyingToMessage = null;
      _replyingToSender = null;
    });
  }

  /// Start editing a message
  void _startEditingMessage(String messageId, String message) {
    setState(() {
      _isEditing = true;
      _editingMessageId = messageId;
      _originalMessage = message;
      _messageController.text = message;
    });
    FocusScope.of(context).requestFocus(_textFieldFocusNode);
  }

  /// Cancel editing
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingMessageId = null;
      _originalMessage = null;
      _messageController.clear();
    });
  }

  /// Save edited message
  void _saveEditedMessage() {
    if (_editingMessageId == null || _messageController.text.trim().isEmpty)
      return;

    _messagesRef.child(_editingMessageId!).update({
      "message": _messageController.text.trim(),
      "editedAt": ServerValue.timestamp,
      "isEdited": true,
    });

    setState(() {
      _isEditing = false;
      _editingMessageId = null;
      _originalMessage = null;
      _messageController.clear();
      _isTyping = false;
    });
  }

  /// Delete message (admin or owner)
  void _deleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            title: Text(
              'Delete Message',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this message? This action cannot be undone.',
              style: TextStyle(
                color:
                    themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_isAdmin) {
                    // Admin deletion - replace with admin deletion message
                    _messagesRef.child(messageId).update({
                      "message": "This message was deleted by admin",
                      "messageType": "admin_deleted",
                      "deletedAt": ServerValue.timestamp,
                      "deletedBy": "admin",
                      "mediaUrl": null,
                      "replyTo": null,
                      "replyToMessage": null,
                      "replyToSender": null,
                    });
                  } else {
                    // User deletion - remove completely
                    _messagesRef.child(messageId).remove();
                  }
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Delete',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Show edit/delete/report options for messages
  void _showMessageOptions(
      String messageId,
      String message,
      ThemeProvider themeProvider,
      bool hasMedia,
      bool isMyMessage,
      String senderId,
      String senderName) {
    final isPoll = message.isEmpty && hasMedia ||
        (message.isNotEmpty && hasMedia && messageId.contains('poll'));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
        child: SingleChildScrollView(
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

              // Copy message option - Show for all messages that have text content
              if (message.isNotEmpty && !isPoll)
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF9C27B0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.copy, color: Color(0xFF9C27B0)),
                  ),
                  title: Text(
                    'Copy Message',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Copy message to clipboard
                    Clipboard.setData(ClipboardData(text: message));
                    Fluttertoast.showToast(
                      msg: "Message copied to clipboard",
                      toastLength: Toast.LENGTH_SHORT,
                      backgroundColor: Color(0xFF9C27B0),
                      textColor: Colors.white,
                    );
                  },
                ),

              // Vote options for everyone
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.thumb_up, color: Color(0xFF4CAF50)),
                ),
                title: Text(
                  'Upvote ${isPoll ? "Poll" : "Message"}',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _voteMessage(messageId, true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.thumb_down, color: Colors.red),
                ),
                title: Text(
                  'Downvote ${isPoll ? "Poll" : "Message"}',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _voteMessage(messageId, false);
                },
              ),

              Divider(color: Colors.grey[400]),

              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.reply, color: Color(0xFF2196F3)),
                ),
                title: Text(
                  'Reply to ${isPoll ? "Poll" : "Message"}',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _replyToMessage(
                    messageId,
                    message.isNotEmpty
                        ? message
                        : (isPoll ? "Poll" : (hasMedia ? "Media" : "Message")),
                    senderName,
                  );
                },
              ),

              // Report option - Show for messages that are not yours
              if (!isMyMessage)
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.flag, color: Colors.orange),
                  ),
                  title: Text(
                    'Report ${isPoll ? "Poll" : "Message"}',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog(messageId, message, senderName, senderId,
                        themeProvider);
                  },
                ),

              // Allow editing polls only by creator, regular messages by owner
              if (isMyMessage && !hasMedia && message.isNotEmpty)
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit, color: Color(0xFFFF9800)),
                  ),
                  title: Text(
                    'Edit Message',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _startEditingMessage(messageId, message);
                  },
                ),
              if (isMyMessage || _isAdmin)
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                  title: Text(
                    _isAdmin && !isMyMessage
                        ? 'Delete ${isPoll ? "Poll" : "Message"} (Admin)'
                        : 'Delete ${isPoll ? "Poll" : "Message"}',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(messageId);
                  },
                ),

// Add edit option for polls created by user
              if (isPoll && isMyMessage)
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit, color: Colors.orange),
                  ),
                  title: Text(
                    'Edit Poll',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // This will be handled by the poll widget's long press
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Use the edit button on the poll to modify it'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              if (_isAdmin && !isMyMessage && senderId != userId)
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
                    'Ban User',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _banUser(senderId, senderName);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show report dialog for a message
  void _showReportDialog(String messageId, String message, String senderName,
      String senderId, ThemeProvider themeProvider) {
    if (_isUserBanned) {
      Fluttertoast.showToast(msg: "You are banned from reporting messages");
      return;
    }

    MessageReportingSystem.showReportDialog(
      context: context,
      messageId: messageId,
      messageContent: message,
      reportedUserId: senderId,
      reportedUserName: senderName,
      themeProvider: themeProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor:
            themeProvider.isDarkMode ? Colors.grey[900] : Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor:
              themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          title: Column(
            children: [
              Text(
                "Discussion Forum",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "Share your thoughts, images & videos",
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
          actions: [
            IconButton(
              icon: Icon(
                Icons.search,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                size: 24,
              ),
              onPressed: () async {
                final result = await showSearch(
                  context: context,
                  delegate: MessageSearchDelegate(
                    themeProvider: themeProvider,
                    messagesRef: _messagesRef,
                    onMessageFound: (messageId) {
                      // This function is called when a search result is clicked
                      _scrollToMessage(messageId);
                    },
                  ),
                );

                // Handle the result returned when search is closed
                if (result != null && result.isNotEmpty) {
                  _scrollToMessage(result);
                }
              },
              tooltip: 'Search messages',
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'clear_chat':
                    _clearChatLocally();
                    break;
                  case 'restore_chat':
                    _restoreAllMessages();
                    break;
                  case 'toggle_admin_only':
                    AdminOnlyManager.showToggleAdminOnlyDialog(
                      context: context,
                      isGovAdmin: _isGovAdmin,
                      currentAdminOnlyMode: _isAdminOnlyMode,
                      currentUserName: currentUserName,
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                // Admin-only mode toggle (only for gov admins)
                if (_isGovAdmin)
                  PopupMenuItem<String>(
                    value: 'toggle_admin_only',
                    child: Row(
                      children: [
                        Icon(
                          _isAdminOnlyMode ? Icons.lock_open : Icons.lock,
                          color: _isAdminOnlyMode
                              ? Color(0xFF4CAF50)
                              : Color(0xFFFF9800),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          _isAdminOnlyMode
                              ? 'Disable Admin-Only'
                              : 'Enable Admin-Only',
                          style: TextStyle(
                            color: _isAdminOnlyMode
                                ? Color(0xFF4CAF50)
                                : Color(0xFFFF9800),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Separator if gov admin
                if (_isGovAdmin)
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Divider(height: 1),
                  ),

                // Existing menu items
                PopupMenuItem<String>(
                  value: 'clear_chat',
                  child: Row(
                    children: [
                      Icon(
                        Icons.clear_all,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black87,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Clear Chat',
                        style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showRestoreButton)
                  PopupMenuItem<String>(
                    value: 'restore_chat',
                    child: Row(
                      children: [
                        Icon(Icons.restore, color: Color(0xFF4CAF50), size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Restore All Messages',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode
                    ? [Colors.grey[800]!, Colors.grey[700]!]
                    : [Colors.white, Color(0xFFF8F9FA)],
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
            const EnhancedAnimatedBackground(),
            if (_showTermsDialog)
              MessageWidgets.buildTermsDialog(
                context,
                themeProvider,
                _agreeToTerms,
              )
            else if (_hasAgreedToTerms)
              Column(
                children: [
                  // Disclaimer banner
                  if (_showDisclaimer)
                    MessageWidgets.buildDisclaimerBanner(
                      themeProvider,
                      _disclaimerController,
                      _hideDisclaimer,
                    ),

                  // Admin-only mode indicator
                  AdminOnlyManager.buildAdminOnlyIndicator(
                    context: context,
                    isAdminOnlyMode: _isAdminOnlyMode,
                    themeProvider: themeProvider,
                  ),

                  // Restore button at top
                  if (_showRestoreButton)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _restoreAllMessages,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xFF4CAF50),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restore,
                                  color: Color(0xFF4CAF50),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Tap to restore all cleared messages',
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Real-time message list with date separators
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[900]
                            : Color(0xFFF8F9FA),
                      ),
                      child: StreamBuilder<DatabaseEvent>(
                        stream: _messagesRef.orderByChild("timestamp").onValue,
                        builder:
                            (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data?.snapshot.value == null) {
                            return MessageWidgets.buildEmptyState(
                                themeProvider);
                          }

                          // Convert snapshot to list of messages
                          Map<dynamic, dynamic> messagesMap = snapshot
                              .data!.snapshot.value as Map<dynamic, dynamic>;

                          List<Map<String, dynamic>> messagesList = messagesMap
                              .entries
                              .map((e) => {
                                    "key": e.key,
                                    ...Map<String, dynamic>.from(e.value)
                                  })
                              .where((message) => !_shouldHideMessage(message))
                              .toList();

                          // Sort by timestamp (ascending)
                          messagesList.sort((a, b) =>
                              a["timestamp"].compareTo(b["timestamp"]));

                          // Group messages by date and create widgets with separators
                          List<Widget> messageWidgets = [];
                          String? lastDateString;

                          for (int i = 0; i < messagesList.length; i++) {
                            final message = messagesList[i];
                            bool isMe = message["senderId"] == userId;
                            final messageId = message["key"];

                            // Ensure message key exists
                            if (!_messageKeys.containsKey(messageId)) {
                              _messageKeys[messageId] = GlobalKey();
                            }

                            // Get message date
                            DateTime? messageDate;
                            try {
                              final timestamp =
                                  message["createdAt"] ?? message["timestamp"];
                              if (timestamp is int) {
                                messageDate =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        timestamp);
                              }
                            } catch (e) {
                              print('Error parsing date: $e');
                            }

                            // Add date separator if date changed and message date exists
                            if (messageDate != null) {
                              final dateString =
                                  ForumLogic.getDateString(messageDate);
                              if (dateString != lastDateString) {
                                messageWidgets.add(
                                    MessageWidgets.buildDateSeparator(
                                        dateString, themeProvider));
                                lastDateString = dateString;
                              }

                              // Add message only if we have a valid date
                              messageWidgets.add(
                                Container(
                                  key: _messageKeys[messageId],
                                  child: MessageWidgets.buildMessage(
                                    message,
                                    isMe,
                                    themeProvider,
                                    _showFullScreenImage,
                                    _showFullScreenVideo,
                                    _replyToMessage,
                                    _showMessageOptions,
                                    _isAdmin,
                                    userId!,
                                    currentUserName,
                                    _messageVotes,
                                    _voteMessage,
                                    (messageId) =>
                                        _getUserVote(messageId) ?? '',
                                    onJumpToMessage: _scrollToMessage,
                                    isHighlighted:
                                        _highlightedMessageId == message["key"],
                                    messageReactions: _messageReactions,
                                    onShowReactionPicker: _showReactionPicker,
                                    onShowReactionDetails: _showReactionDetails,
                                    getReactionSummary: _getReactionSummary,
                                  ),
                                ),
                              );
                            }
                          }

                          // Ensure all messages have keys for jumping functionality
                          for (int i = 0; i < messagesList.length; i++) {
                            final messageId = messagesList[i]["key"];
                            if (!_messageKeys.containsKey(messageId)) {
                              _messageKeys[messageId] = GlobalKey();
                            }
                          }

                          final listView = ListView(
                            key: _messagesListKey,
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            children: messageWidgets.isNotEmpty
                                ? messageWidgets
                                : messagesList.map((message) {
                                    bool isMe = message["senderId"] == userId;
                                    final messageId = message["key"];

                                    return Container(
                                      key: _messageKeys[messageId],
                                      child: MessageWidgets.buildMessage(
                                        message,
                                        isMe,
                                        themeProvider,
                                        _showFullScreenImage,
                                        _showFullScreenVideo,
                                        _replyToMessage,
                                        _showMessageOptions,
                                        _isAdmin,
                                        userId!,
                                        currentUserName,
                                        // Add voting parameters
                                        _messageVotes,
                                        _voteMessage,
                                        (messageId) =>
                                            _getUserVote(messageId) ?? '',
                                        onJumpToMessage: _jumpToMessage,
                                      ),
                                    );
                                  }).toList(),
                          );

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients &&
                                !_showGoDownButton) {
                              // Multiple jumps to ensure we reach absolute bottom
                              for (int i = 0; i <= 10; i++) {
                                Future.delayed(Duration(milliseconds: i * 50),
                                    () {
                                  if (_scrollController.hasClients &&
                                      !_showGoDownButton) {
                                    _scrollController.jumpTo(_scrollController
                                        .position.maxScrollExtent);
                                  }
                                });
                              }
                            }
                          });

                          return listView;
                        },
                      ),
                    ),
                  ),

                  // Media preview
                  if (_showMediaPreview && _attachedMediaUrl != null)
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF2196F3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _attachedMediaType == "image"
                                    ? Icons.image
                                    : Icons.videocam,
                                color: Color(0xFF2196F3),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Attached ${_attachedMediaType == "image" ? "Image" : "Video"}',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              GestureDetector(
                                onTap: _clearMediaPreview,
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
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _attachedMediaType == "image"
                                ? (_attachedMediaFile != null
                                    ? Image.file(
                                        _attachedMediaFile!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 100,
                                        width: 100,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image),
                                      ))
                                : Container(
                                    height: 100,
                                    width: 100,
                                    color: Colors.black,
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                  // Reply and edit indicators
                  MessageWidgets.buildReplyIndicator(
                    themeProvider,
                    _isReplying,
                    _replyingToSender,
                    _replyingToMessage,
                    _clearReply,
                  ),
                  MessageWidgets.buildEditIndicator(
                    themeProvider,
                    _isEditing,
                    _originalMessage,
                    _cancelEditing,
                  ),

                  // Enhanced message input field & send button with emoji picker
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
                    child: !AdminOnlyManager.canUserSendMessage(
                      isAdminOnlyMode: _isAdminOnlyMode,
                      isAdmin: _isAdmin,
                      isUserBanned: _isUserBanned,
                    )
                        ? Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  AdminOnlyManager.getBannedIcon(
                                    isAdminOnlyMode: _isAdminOnlyMode,
                                    isAdmin: _isAdmin,
                                    isUserBanned: _isUserBanned,
                                  ),
                                  color: Colors.red,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AdminOnlyManager.getBannedMessage(
                                      isAdminOnlyMode: _isAdminOnlyMode,
                                      isAdmin: _isAdmin,
                                      isUserBanned: _isUserBanned,
                                    ),
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SafeArea(
                            child: Row(
                              children: [
                                // Pin icon button for media selection
                                Container(
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[700]
                                        : Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: themeProvider.isDarkMode
                                          ? Colors.grey[600]!
                                          : Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: _isUploading
                                          ? null
                                          : _showMediaOptions,
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        child: _isUploading
                                            ? Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Color(0xFF2196F3),
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.attach_file,
                                                color: themeProvider.isDarkMode
                                                    ? Colors.grey[400]
                                                    : Colors.grey[500],
                                                size: 24,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),

                                // Enhanced text input field with @everyone support
                                Expanded(
                                  child: _buildEnhancedTextInput(themeProvider),
                                ),
                                SizedBox(width: 12),

                                // Enhanced send button
                                _buildSendButton(themeProvider),
                              ],
                            ),
                          ),
                  ),
                  if (_showEmojiPicker)
                    Container(
                      height: MediaQuery.of(context).viewInsets.bottom > 0
                          ? 280
                          : 280,
                      child: EmojiPickerWidget(
                        themeProvider: themeProvider,
                        emojiAnimationController: _emojiAnimationController,
                        emojiScaleAnimation: _emojiScaleAnimation,
                        selectedEmojiCategory: _selectedEmojiCategory,
                        onCategorySelected: (category) {
                          setState(() {
                            _selectedEmojiCategory = category;
                          });
                        },
                        onEmojiSelected: _insertEmoji,
                      ),
                    ),
                ],
              )
            else
              Center(
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              ),

            // Go down button - positioned at bottom right
            if (_showGoDownButton && _hasAgreedToTerms)
              Positioned(
                bottom: _showEmojiPicker ? 380 : (_isReplying ? 180 : 100),
                right: 16,
                child: AnimatedOpacity(
                  opacity: _showGoDownButton ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Color(0xFF2196F3),
                    onPressed: _scrollToBottom,
                    elevation: 4,
                    heroTag: "goDownButton",
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  static bool hasEveryoneMention(Map<String, dynamic> messageData) {
    final message = messageData["message"] ?? "";
    return EveryoneNotificationService.containsEveryone(message);
  }
}
