import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? style;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? minLines;

  final InputDecoration? decoration;  // ✅ Add this

  const MentionTextField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.style,
    this.onChanged,
    this.onTap,
    this.maxLines,
    this.minLines,
    this.decoration,
  }) : super(key: key);

  @override
  _MentionTextFieldState createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  OverlayEntry? _overlayEntry;
  bool _showMentionSuggestion = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    // Check if user is typing @ at current cursor position
    if (selection.baseOffset > 0) {
      final beforeCursor = text.substring(0, selection.baseOffset);
      if (beforeCursor.endsWith('@') ||
          beforeCursor.toLowerCase().endsWith('@e')) {
        _showSuggestion();
      } else {
        _hideSuggestion();
      }
    } else {
      _hideSuggestion();
    }

    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }
  }

  void _showSuggestion() {
    if (_showMentionSuggestion) return;

    setState(() {
      _showMentionSuggestion = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _hideSuggestion() {
    if (!_showMentionSuggestion) return;

    setState(() {
      _showMentionSuggestion = false;
    });

    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - 60,
        width: size.width,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              dense: true,
              title: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '@everyone',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                        backgroundColor: Color(0xFF2196F3).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _insertEveryone();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _insertEveryone() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    // Find the @ symbol position
    int atPosition = -1;
    for (int i = selection.baseOffset - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atPosition = i;
        break;
      }
    }

    if (atPosition >= 0) {
      final beforeAt = text.substring(0, atPosition);
      final afterCursor = text.substring(selection.baseOffset);
      final newText = beforeAt + '@everyone' + afterCursor;

      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: atPosition + 9, // '@everyone'.length
      );
    }

    _hideSuggestion();

    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onTap: widget.onTap,
      style: widget.style,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      decoration: widget.decoration ?? InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
      ),
    );
  }
}
