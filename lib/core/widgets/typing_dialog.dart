import 'package:flutter/material.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';

/// A dialog with a text field. On a phone held sideways the keyboard leaves
/// little height, so the title, the content and the
/// buttons scroll together and the field being typed in scrolls into view;
/// otherwise it is a plain [AlertDialog]. Its buttons are Cancel (B on a
/// controller) and [confirmLabel] (X).
class TypingDialog extends StatelessWidget {
  const TypingDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final Widget title;
  final Widget content;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final actions = [
      GamepadShortcut(
        button: PadButton.b,
        onPressed: onCancel,
        child: TextButton(
          onPressed: onCancel,
          child: Text(AppLocalizations.of(context).cancel),
        ),
      ),
      GamepadShortcut(
        button: PadButton.x,
        onPressed: onConfirm,
        child: FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
      ),
    ];
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
