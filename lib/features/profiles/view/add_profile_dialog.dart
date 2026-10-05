import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import 'profile_avatar.dart';

/// Returns `(nickname, avatar)`, or null if cancelled.
Future<(String, int)?> showAddProfileDialog(BuildContext context) =>
    showDialog<(String, int)>(
      context: context,
      builder: (_) => const _AddProfileDialog(),
    );

class _AddProfileDialog extends StatefulWidget {
  const _AddProfileDialog();

  @override
  State<_AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<_AddProfileDialog> {
  final _nickname = TextEditingController();
  var _avatar = 0;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nickname.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, (name, _avatar));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addPlayer),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nickname,
              autofocus: true,
              maxLength: 16,
              decoration: InputDecoration(labelText: l10n.nickname),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(l10n.chooseAvatar),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < avatarStyles.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _avatar = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 4,
                          color: i == _avatar
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: ProfileAvatar(avatar: i, size: 64),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
