import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class MentionTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color mentionColor;
  final Color mentionBackgroundColor;
  final Color? linkColor;
  final bool isOnDarkBackground; // Added missing parameter

  const MentionTextWidget({
    Key? key,
    required this.text,
    this.textStyle,
    this.mentionColor = const Color(0xFF2196F3),
    this.mentionBackgroundColor = const Color(0xFF2196F3),
    this.linkColor,
    this.isOnDarkBackground = false, // Default to light background
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    
    // Dynamic link color based on background - fixed null-aware operator
    final Color effectiveLinkColor = linkColor ?? 
        (isOnDarkBackground 
            ? const Color.fromARGB(255, 56, 59, 61) // Light blue/cyan for dark backgrounds
            : const Color.fromARGB(255, 36, 36, 36)); // Dark blue for light backgrounds
    
    // Combined pattern to match both @everyone mentions and URLs
    final combinedPattern = RegExp(
      r'(@everyone)|((https?:\/\/|www\.)[^\s]+)|([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.+[a-zA-Z]{2,}(?:\/[^\s]*)?)',
      caseSensitive: false,
    );
    
    int lastMatchEnd = 0;

    for (final match in combinedPattern.allMatches(text)) {
      // Add text before match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: textStyle,
        ));
      }

      final matchText = match.group(0)!;
      
      // Check if it's an @everyone mention
      if (matchText.toLowerCase() == '@everyone') {
        spans.add(TextSpan(
          text: matchText,
          style: textStyle?.copyWith(
                color: isOnDarkBackground ? Colors.orange : mentionColor,
                fontWeight: FontWeight.bold,
                backgroundColor: isOnDarkBackground 
                    ? Colors.orange.withOpacity(0.2)
                    : mentionBackgroundColor.withOpacity(0.2),
              ) ??
              TextStyle(
                color: isOnDarkBackground ? Colors.orange : mentionColor,
                fontWeight: FontWeight.bold,
                backgroundColor: isOnDarkBackground 
                    ? Colors.orange.withOpacity(0.2)
                    : mentionBackgroundColor.withOpacity(0.2),
              ),
        ));
      } 
      // Check if it's a URL
      else if (_isUrl(matchText)) {
        spans.add(TextSpan(
          text: matchText,
          style: textStyle?.copyWith(
                color: effectiveLinkColor,
                decoration: TextDecoration.underline,
                decorationColor: effectiveLinkColor,
                fontWeight: FontWeight.w600, // Make links slightly bolder
              ) ??
              TextStyle(
                color: effectiveLinkColor,
                decoration: TextDecoration.underline,
                decorationColor: effectiveLinkColor,
                fontWeight: FontWeight.w600,
              ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(matchText),
        ));
      } 
      // Fallback for any other match
      else {
        spans.add(TextSpan(
          text: matchText,
          style: textStyle,
        ));
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: textStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  bool _isUrl(String text) {
    // More comprehensive URL detection
    final urlPattern = RegExp(
      r'^(https?:\/\/)|(www\.)|([a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\.+[a-zA-Z]{2,})',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text);
  }

  void _launchUrl(String url) async {
    String formattedUrl = url;
    
    // Add https:// if the URL doesn't start with http:// or https://
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }
    
    try {
      final uri = Uri.parse(formattedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Handle error - could show a snackbar or toast
        debugPrint('Could not launch $formattedUrl');
      }
    } catch (e) {
      // Handle parsing errors
      debugPrint('Error launching URL: $e');
    }
  }
}