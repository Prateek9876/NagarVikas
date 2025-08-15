import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About the App'),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 4, 204, 240).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: ListView(
            children: [
              _buildQuestionTile(
                'What is NagarVikas?',
                'NagarVikas is a civic issue complaint application designed to bridge the gap between citizens and municipal authorities. It allows citizens to easily report and track the resolution of civic issues like garbage disposal, potholes, water supply issues, and more.',
                Icons.info_outline,
              ),
              _buildQuestionTile(
                'What do we do?',
                'We provide an easy and convenient platform for reporting civic issues, enabling the authorities to act on them promptly. Our mission is to make urban living cleaner and more efficient by empowering citizens to take action on the problems they encounter.',
                Icons.work_outline,
              ),
              _buildQuestionTile(
                'What do we offer?',
                'Our app offers a variety of services, including issue reporting, live status tracking, and automated notifications. You can submit complaints about various civic problems, track the progress, and receive updates on the resolution.',
                Icons.local_offer_outlined,
              ),
              _buildQuestionTile(
                'What are the features of NagarVikas?',
                '• Easy complaint submission\n• Track complaint status in real time\n• Notifications and reminders for pending issues\n• User-friendly interface\n• Fast and reliable issue resolution system',
                Icons.featured_play_list_outlined,
              ),
              _buildQuestionTile(
                'Who developed NagarVikas?',
                'NagarVikas was developed by a passionate team aiming to improve civic engagement and urban infrastructure. We believe technology can solve problems more efficiently and make a positive impact on the community.',
                Icons.people_outline,
              ),
              _buildQuestionTile(
                'How can I contact you?',
                'For more information or support, feel free to reach out to us at support@nagarvikas.com. We value your feedback and are always here to help.',
                Icons.contact_support_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTile(String question, String answer, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: _CustomExpandableTile(
        question: question,
        answer: answer,
        icon: icon,
      ),
    );
  }
}

class _CustomExpandableTile extends StatefulWidget {
  final String question;
  final String answer;
  final IconData icon;

  const _CustomExpandableTile({
    required this.question,
    required this.answer,
    required this.icon,
  });

  @override
  State<_CustomExpandableTile> createState() => _CustomExpandableTileState();
}

class _CustomExpandableTileState extends State<_CustomExpandableTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  // NEW: Custom animation controller for smoother animations

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // NEW: Initialize animation controller for expansion/collapse
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // NEW: Proper cleanup of animation controller
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      // MAJOR CHANGE: Enhanced decoration instead of basic BoxDecoration
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? const Color.fromARGB(255, 4, 204, 240).withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: _isExpanded ? 3 : 1,
            blurRadius: _isExpanded ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: _isExpanded
            ? Border.all(
                color: const Color.fromARGB(255, 4, 204, 240).withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              // Added ripple effect on tap
              borderRadius: BorderRadius.circular(16),
              onTap: _toggleExpansion,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 4, 204, 240)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.icon,
                        color: const Color.fromARGB(255, 4, 204, 240),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isExpanded
                              ? const Color.fromARGB(255, 4, 204, 240)
                                  .withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: _isExpanded
                              ? const Color.fromARGB(255, 4, 204, 240)
                              : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                // 🆕 NEW: Styled content container with background
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 4, 204, 240).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        const Color.fromARGB(255, 4, 204, 240).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.answer,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
