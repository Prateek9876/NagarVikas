import 'package:flutter/material.dart';

//working chatbot
class ChatbotFloatingButton extends StatefulWidget {
  const ChatbotFloatingButton({Key? key}) : super(key: key);

  @override
  State<ChatbotFloatingButton> createState() => _ChatbotFloatingButtonState();
}

//chatbot floating button
class _ChatbotFloatingButtonState extends State<ChatbotFloatingButton> with SingleTickerProviderStateMixin {
  bool _isChatOpen = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openChat() {
    setState(() => _isChatOpen = true);
    _controller.forward();
  }

  void _closeChat() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isChatOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            heroTag: "chatbot_fab",
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: _openChat,
          ),
        ),
        if (_isChatOpen)
          Positioned(
            bottom: 165,
            right: 16,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 340,
                  height: 420,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.smart_toy, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  "Nagar Vikas Assistant",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Transform.translate(
                              offset: const Offset(0, -3),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                splashRadius: 20,
                                onPressed: _closeChat,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: const Color(0xFFF6F8FB),
                          child: const ChatbotConversationWidget(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ChatbotConversationWidget extends StatefulWidget {
  const ChatbotConversationWidget({Key? key}) : super(key: key);

  @override
  State<ChatbotConversationWidget> createState() => _ChatbotConversationWidgetState();
}

class _ChatbotConversationWidgetState extends State<ChatbotConversationWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(text: "How can I help you?", isBot: true),
    _ChatMessage(text: "Try: How do I report an issue?", isBot: true),
  ];
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isBot: false));
      _isTyping = true;
    });
    _controller.clear();
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(text: getMessage(text), isBot: true));
    });
  }

  String getMessage(String input) {
    final lower = input.toLowerCase();
    // FAQ keyword logic
    if (lower.contains('report') || (lower.contains('issue') || lower.contains('complaint'))) {
      return 'To report an issue, go to the Issues section from the main menu and fill out the form with details and photos.';
    } else if (lower.contains('register') || lower.contains('sign up')) {
      return 'To register, tap on the Register button on the home screen and fill in your details.';
    } else if (lower.contains('track') && (lower.contains('complaint') || lower.contains('issue') || lower.contains('status'))) {
      return 'You can track your complaint or issue status in the My Complaints section.';
    } else if (lower.contains('contact') && (lower.contains('support') || lower.contains('help'))) {
      return 'For support, contact us at support@nagarvikas.com or call our helpline at 1800-123-456.';
    } else if (lower.contains('reset') && lower.contains('password')) {
      return 'To reset your password, use the Forgot Password link on the login page.';
    } else if (lower.contains('edit') && (lower.contains('profile') || lower.contains('account'))) {
      return 'To edit your profile, go to the Profile section and tap on Edit.';
    } else if (lower.contains('delete') && lower.contains('account')) {
      return 'To delete your account, please contact support for assistance.';
    } else if ((lower.contains('app') || lower.contains('application')) && lower.contains('update')) {
      return 'To update the app, visit the Play Store or App Store and check for updates.';
    } else if (lower.contains('language')) {
      return 'You can change the app language from the Settings menu.';
    } else if (lower.contains('notification')) {
      return 'Notification preferences can be managed in the Settings > Notifications section.';
    } else if (lower.contains('location') && lower.contains('enable')) {
      return 'To enable location, allow location permissions in your device settings and app permissions.';
    } else if (lower.contains('faq') || lower.contains('help')) {
      return 'Frequently Asked Questions:\n- How do I report an issue?\n- How do I register?\n- How do I track my complaint?\n- How do I contact support?\n- How do I edit my profile?\n- How do I delete my account?\n- How do I update the app?\n- How do I change the language?\n- How do I enable notifications?';
    }
    // Fallback
    return 'Sorry, I didn\'t understand. Please try rephrasing your question or ask about reporting issues, registration, tracking complaints, support, password reset, profile, account, app update, language, or notifications.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isTyping && index == 0) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                        ),
                        const SizedBox(width: 10),
                        const Text("Typing...", style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                );
              }
              final msg = _messages[_messages.length - 1 - (index - (_isTyping ? 1 : 0))];
              return Align(
                alignment: msg.isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  decoration: BoxDecoration(
                    color: msg.isBot ? Colors.blue[50] : Colors.blueAccent.withAlpha(217),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isBot ? Colors.black87 : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Type your message...",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;
  _ChatMessage({required this.text, required this.isBot});
}

// UPDATED CHATBOT WRAPPER - THIS IS THE KEY CHANGE
class ChatbotWrapper extends StatefulWidget {
  final Widget child;
  final bool hideChat;

  const ChatbotWrapper({
    required this.child,
    this.hideChat = false,
    Key? key
  }) : super(key: key);

  @override
  State<ChatbotWrapper> createState() => _ChatbotWrapperState();
}

class _ChatbotWrapperState extends State<ChatbotWrapper> {
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DrawerNotification>(
      onNotification: (notification) {
        setState(() {
          _isDrawerOpen = notification.isOpen;
        });
        return true;
      },
      child: Stack( // Stack
        children: [
          widget.child,
          // Only show chatbot when hideChat is false AND drawer is not open
          if (!widget.hideChat && !_isDrawerOpen)
            const ChatbotFloatingButton(),
        ],
      ),
    );
  }
}

// Add this custom notification class
class DrawerNotification extends Notification { // Drawer Notification
  final bool isOpen;
  DrawerNotification(this.isOpen);
}
