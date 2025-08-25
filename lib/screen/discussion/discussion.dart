import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
import 'message_widgets.dart';
import 'poll_creation_widget.dart';
import 'poll_message_widget.dart';

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
  Map<String, Map<String, dynamic>> _messageVotes = {}; // Cache message votes
  final DatabaseReference _votesRef = FirebaseDatabase.instance.ref("votes/");

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

    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
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
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _sendButtonAnimationController.dispose();
    _messageAnimationController.dispose();
    _disclaimerController.dispose();
    _emojiAnimationController.dispose();
    super.dispose();
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

  /// Vote on a message (upvote or downvote)
  Future<void> _voteMessage(String messageId, bool isUpvote) async {
    if (userId == null || _isUserBanned) {
      if (_isUserBanned) {
        Fluttertoast.showToast(msg: "You are banned from voting");
      }
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

      // Determine new vote action - THIS IS THE KEY PART
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

  /// Get vote counts for a message
  Map<String, int> _getVoteCounts(String messageId) {
    final votes = _messageVotes[messageId] ?? {};
    int upvotes = 0;
    int downvotes = 0;

    votes.forEach((userId, voteData) {
      if (voteData is Map && voteData['type'] == 'upvote') {
        upvotes++;
      } else if (voteData is Map && voteData['type'] == 'downvote') {
        downvotes++;
      }
    });

    return {'upvotes': upvotes, 'downvotes': downvotes};
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

  /// Show poll creation dialog
  void _showPollCreation() {
    if (_isUserBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are banned from creating polls'),
          backgroundColor: Colors.red,
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

  /// Initialize speech to text
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
    // Check if user is banned
    if (_isUserBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are banned from sending messages'),
          backgroundColor: Colors.red,
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

    if ((_messageController.text.trim().isEmpty && finalMediaUrl == null) ||
        currentUserName == null) return;

    _sendButtonAnimationController.forward().then((_) {
      _sendButtonAnimationController.reverse();
    });

    Map<String, dynamic> messageData = {
      "senderId": userId,
      "senderName": currentUserName,
      "timestamp": ServerValue.timestamp,
      "createdAt": ServerValue.timestamp,
    };

    // Add message text if present
    if (_messageController.text.trim().isNotEmpty) {
      messageData["message"] = _messageController.text.trim();
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

    _messagesRef.push().set(messageData);

    _messageController.clear();
    _clearReply();
    _clearMediaPreview(); // Clear media preview after sending
    setState(() {
      _isTyping = false;
    });

    // Hide emoji picker after sending
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
      _emojiAnimationController.reverse();
    }

    // Force scroll to bottom after sending message
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);

        // Additional jumps for media content
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

  /// Show edit/delete options for messages
  void _showMessageOptions(
      String messageId,
      String message,
      ThemeProvider themeProvider,
      bool hasMedia,
      bool isMyMessage,
      String senderId,
      String senderName) {
    final isPoll = message.isEmpty && hasMedia;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
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
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
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
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
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
            // Don't allow editing polls or media messages
            if (isMyMessage && !hasMedia && !isPoll)
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

                  // Real-time message list with date separators
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[900]
                            : Color(0xFFF8F9FA),
                      ),
                      child: StreamBuilder(
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
                                    // NEW: Add voting parameters
                                    _messageVotes,
                                    _voteMessage,
                                        (messageId) => _getUserVote(messageId) ?? '',
                                    onJumpToMessage: _jumpToMessage,
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
                                ? messageWidgets.map((widget) {
                              // If this is a message widget, wrap it with a key
                              if (widget is Widget && widget.runtimeType.toString().contains('buildMessage')) {
                                // Extract message ID from the widget if possible
                                return widget;
                              }
                              return widget;
                            }).toList()
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
                                  // NEW: Add voting parameters
                                  _messageVotes,
                                  _voteMessage,
                                      (messageId) => _getUserVote(messageId) ?? '',
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
                    child: _isUserBanned
                        ? Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.block, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You are banned from sending messages',
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
                          // UPDATED: Pin icon button for media selection
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

                          // Enhanced text input field
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[700]
                                    : Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: (_isTyping || _isEditing)
                                      ? Color(0xFF2196F3)
                                      : (themeProvider.isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!),
                                  width:
                                  (_isTyping || _isEditing) ? 2 : 1,
                                ),
                                boxShadow: (_isTyping ||
                                    _isEditing ||
                                    _showMediaPreview)
                                    ? [
                                  BoxShadow(
                                    color: Color(0xFF2196F3)
                                        .withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Text field
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      focusNode: _textFieldFocusNode,
                                      onTap: () {
                                        // Hide emoji picker when text field is tapped
                                        if (_showEmojiPicker) {
                                          setState(() {
                                            _showEmojiPicker = false;
                                          });
                                          _emojiAnimationController
                                              .reverse();
                                        }
                                        // Auto scroll if at bottom when keyboard opens
                                        Future.delayed(
                                            Duration(milliseconds: 300),
                                                () {
                                              if (!_showGoDownButton &&
                                                  _scrollController
                                                      .hasClients) {
                                                _scrollController.animateTo(
                                                  _scrollController.position
                                                      .maxScrollExtent,
                                                  duration: Duration(
                                                      milliseconds: 200),
                                                  curve: Curves.easeOut,
                                                );
                                              }
                                            });
                                      },
                                      onChanged: (text) {
                                        if (text.length > 100) {
                                          _messageController.text =
                                              text.substring(0, 100);
                                          _messageController.selection =
                                              TextSelection.fromPosition(
                                                TextPosition(offset: 100),
                                              );
                                        }
                                      },
                                      style: TextStyle(
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 3,
                                      minLines: 1,
                                      textCapitalization:
                                      TextCapitalization.sentences,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                            left: 20,
                                            top: 12,
                                            bottom: 12),
                                        hintText: _isEditing
                                            ? "Edit your message..."
                                            : (_isReplying
                                            ? "Reply to ${_replyingToSender}..."
                                            : (_isListening
                                            ? "Listening..."
                                            : "Type...")),
                                        hintStyle: TextStyle(
                                          color: _isListening
                                              ? Color(0xFF4CAF50)
                                              : (themeProvider.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[500]),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  // Mic button
                                  GestureDetector(
                                    onTap: _toggleListening,
                                    child: Container(
                                      margin: EdgeInsets.only(right: 4),
                                      padding: EdgeInsets.only(
                                          right: 8, top: 8, bottom: 8),
                                      decoration: BoxDecoration(
                                        color: _isListening
                                            ? Color(0xFF4CAF50)
                                            .withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        _isListening
                                            ? Icons.mic
                                            : Icons.mic_none,
                                        color: _isListening
                                            ? Color(0xFF4CAF50)
                                            : (themeProvider.isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600]),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  // Emoji button inside text field
                                  GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      Future.delayed(
                                          Duration(milliseconds: 100),
                                              () {
                                            _toggleEmojiPicker();
                                          });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 16),
                                      padding: EdgeInsets.all(0),
                                      decoration: BoxDecoration(
                                        color: _showEmojiPicker
                                            ? Color(0xFF2196F3)
                                            .withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        _showEmojiPicker
                                            ? Icons.keyboard
                                            : Icons
                                            .emoji_emotions_outlined,
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
                            ),
                          ),
                          SizedBox(width: 12),

                          // Send button
                          AnimatedBuilder(
                            animation: _sendButtonScaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _sendButtonScaleAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: (_isTyping ||
                                        _isEditing ||
                                        _showMediaPreview)
                                        ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF1976D2),
                                        Color(0xFF2196F3)
                                      ],
                                    )
                                        : null,
                                    color: !(_isTyping ||
                                        _isEditing ||
                                        _showMediaPreview)
                                        ? (themeProvider.isDarkMode
                                        ? Colors.grey[600]
                                        : Colors.grey[400])
                                        : null,
                                    shape: BoxShape.circle,
                                    boxShadow: (_isTyping ||
                                        _isEditing ||
                                        _showMediaPreview)
                                        ? [
                                      BoxShadow(
                                        color: Color(0xFF2196F3)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius:
                                      BorderRadius.circular(28),
                                      onTap: (_isTyping ||
                                          _isEditing ||
                                          _showMediaPreview)
                                          ? () => _sendMessage()
                                          : null,
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle),
                                        child: Icon(
                                          _isEditing
                                              ? Icons.check
                                              : (_isTyping
                                              ? Icons.send_rounded
                                              : Icons.send_outlined),
                                          color: Colors.white,
                                          size: (_isTyping ||
                                              _isEditing ||
                                              _showMediaPreview)
                                              ? 24
                                              : 20,
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
}
