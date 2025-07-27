import 'package:NagarVikas/localization/app_localizations.dart';
import 'package:flutter/material.dart'; 
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('aboutAppTitle')),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildQuestionTile(
              AppLocalizations.of(context).get('whatIsNagarVikasQuestion'),
              AppLocalizations.of(context).get('whatIsNagarVikasAnswer'),
            ),
            _buildQuestionTile(
              AppLocalizations.of(context).get('whatDoWeDoQuestion'),
              AppLocalizations.of(context).get('whatDoWeDoAnswer'),
            ),
            _buildQuestionTile(
              AppLocalizations.of(context).get('whatDoWeOfferQuestion'),
              AppLocalizations.of(context).get('whatDoWeOfferAnswer'),
            ),
            _buildQuestionTile(
              AppLocalizations.of(context).get('nagarVikasFeaturesQuestion'),
              AppLocalizations.of(context).get('nagarVikasFeaturesAnswer'),
            ),
            _buildQuestionTile(
              AppLocalizations.of(context).get('whoDevelopedNagarVikasQuestion'),
              AppLocalizations.of(context).get('whoDevelopedNagarVikasAnswer'),
            ),
            _buildQuestionTile(
              AppLocalizations.of(context).get('howToContactUsQuestion'),
              AppLocalizations.of(context).get('howToContactUsAnswer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTile(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: _ExpandableTile(
        question: question,
        answer: answer,
      ),
    );
  }
}

class _ExpandableTile extends StatefulWidget {
  final String question;
  final String answer;

  const _ExpandableTile({
    required this.question,
    required this.answer,
  });

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.2 * 255).toInt()),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        title: Text(
          widget.question,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0.0, // 180° when expanded
          duration: Duration(milliseconds: 300),
          child: Icon(
            Icons.arrow_drop_down,
            color: Colors.black87,
            size: 30,
          ),
        ),
        children: [
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
