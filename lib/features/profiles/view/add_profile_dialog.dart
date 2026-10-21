import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import '../cubit/profiles_cubit.dart';
import '../data/profile.dart';
import 'profile_avatar.dart';
import 'package:cobalagi/core/widgets/focus_tap.dart';
import 'package:cobalagi/core/widgets/glass_popups.dart';
import 'package:cobalagi/core/widgets/typing_dialog.dart';

/// Asks for a new player's nickname and avatar, or, with [nickname] and
/// [avatar], lets a parent change them. Returns `(nickname, avatar)`, or
/// null if cancelled.
Future<(String, int)?> showProfileDialog(
  BuildContext context, {
  String? nickname,
  int? avatar,
}) => showGlassDialog<(String, int)>(
  context: context,
  builder: (_) => _AddProfileDialog(nickname: nickname, avatar: avatar),
);

/// Lets a parent change [profile]'s nickname and avatar, and saves them.
Future<void> editProfile(BuildContext context, Profile profile) async {
  final result = await showProfileDialog(
    context,
    nickname: profile.nickname,
    avatar: profile.avatar,
  );
  if (result == null || !context.mounted) return;
  final (nickname, avatar) = result;
  await context.read<ProfilesCubit>().edit(
    profile.id,
    nickname: nickname,
    avatar: avatar,
  );
}

class _AddProfileDialog extends StatefulWidget {
  const _AddProfileDialog({this.nickname, this.avatar});

  /// Set when editing a player.
  final String? nickname;
  final int? avatar;

  @override
  State<_AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<_AddProfileDialog> {
  late final _nickname = TextEditingController(text: widget.nickname);
  late var _avatar = widget.avatar ?? 0;

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
    return TypingDialog(
      title: Text(widget.nickname == null ? l10n.addPlayer : l10n.editPlayer),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nickname,
            autofocus: true,
            maxLength: 16,
            decoration: InputDecoration(labelText: l10n.nickname),
            // Enter only closes the keyboard: the avatar comes next, and
            // Save stays the one way to add the player.
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 16),
          Text(l10n.chooseAvatar),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < avatarStyles.length; i++)
                FocusTap(
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
      confirmLabel: l10n.save,
      onConfirm: _submit,
      onCancel: () => Navigator.pop(context),
    );
  }
}
