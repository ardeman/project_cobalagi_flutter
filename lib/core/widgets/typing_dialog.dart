import 'package:flutter/material.dart';

/// A dialog with a text field. On a phone held sideways the keyboard leaves
/// little height, so the title, the content and the
/// buttons scroll together and the field being typed in scrolls into view;
/// otherwise it is a plain [AlertDialog].
class TypingDialog extends StatelessWidget {
  const TypingDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    // By screen height, not room above the keyboard, so the layout doesn't
    // switch while the keyboard opens or closes.
    final short = MediaQuery.sizeOf(context).height < 500;
    if (!short) {
      return AlertDialog(
        scrollable: true,
        title: title,
        content: content,
        actions: actions,
      );
    }
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          const SizedBox(height: 12),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            children: actions,
          ),
        ],
      ),
    );
  }
}
