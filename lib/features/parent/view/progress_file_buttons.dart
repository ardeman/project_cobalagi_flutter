import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart' show ShareParams, SharePlus;

import '../../../app/l10n/app_localizations.dart';
import '../../../core/widgets/glass_popups.dart';
import '../../../learning/progress_file.dart';
import '../../learning/data/curriculum_repository.dart';
import '../../learning/data/progress_repository.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/data/profile.dart';
import '../../profiles/view/profile_avatar.dart';
import '../data/progress_transfer.dart';

/// "Save progress" and "Load progress" for one child, on their progress
/// screen in the parent area, so a parent can move the child to another
/// device. Free on every plan.
class ProgressFileButtons extends StatelessWidget {
  const ProgressFileButtons({
    super.key,
    required this.profile,
    required this.onLoaded,
  });

  final Profile profile;

  /// Called after a file's progress was added to [profile].
  final VoidCallback onLoaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.devices_rounded),
          title: Text(l10n.progressFileTitle),
          subtitle: Text(l10n.progressFileHint(profile.nickname)),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Builder(
              // Its own context, so the iPad's share sheet points at it.
              builder: (context) => OutlinedButton.icon(
                icon: const Icon(Icons.save_alt_rounded),
                label: Text(l10n.saveProgress),
                onPressed: () => _save(context),
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.file_open_rounded),
              label: Text(l10n.loadProgress),
              onPressed: () => _load(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final file = await (await _transfer(context)).save(profile);
    final name = file.fileName(DateTime.now());
    final data = XFile.fromData(
      utf8.encode(file.encode()),
      mimeType: 'application/json',
      name: name,
    );
    if (_desktop) {
      final location = await getSaveLocation(
        suggestedName: name,
        acceptedTypeGroups: const [_json],
      );
      if (location == null) return;
      await data.saveTo(location.path);
      if (context.mounted) _tell(context, l10n.progressSaved);
    } else {
      await SharePlus.instance.share(
        ShareParams(
          files: [data],
          fileNameOverrides: [name],
          sharePositionOrigin: origin,
          downloadFallbackEnabled: true,
        ),
      );
    }
  }

  Future<void> _load(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final file = await _pick(context);
    if (file == null || !context.mounted) return;
    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(
          l10n.loadProgressConfirm(file.nickname, profile.nickname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.load),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await (await _transfer(context)).load(profile.id, file);
    if (!context.mounted) return;
    _tell(context, l10n.progressLoaded);
    onLoaded();
  }
}

/// Adds the child in a progress file as a new player, when the plan has room
/// for one more ([maxProfiles]).
Future<void> loadPlayerFromFile(
  BuildContext context, {
  required int maxProfiles,
}) async {
  final l10n = AppLocalizations.of(context);
  final file = await _pick(context);
  if (file == null || !context.mounted) return;
  final transfer = await _transfer(context);
  if (!context.mounted) return;
  final profile = await context.read<ProfilesCubit>().add(
    nickname: file.nickname,
    // A newer app may have avatars this one hasn't.
    avatar: file.avatar < avatarStyles.length ? file.avatar : 0,
    maxProfiles: maxProfiles,
  );
  if (profile == null) return;
  await transfer.load(profile.id, file);
  if (context.mounted) _tell(context, l10n.playerLoaded(profile.nickname));
}

const _json = XTypeGroup(
  label: 'JSON',
  extensions: ['json'],
  mimeTypes: ['application/json'],
  uniformTypeIdentifiers: ['public.json'],
);

/// Desktops save through their own save dialog; phones and the web share the
/// file (the web downloads it where sharing files isn't supported).
bool get _desktop =>
    !kIsWeb &&
    switch (defaultTargetPlatform) {
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux => true,
      _ => false,
    };

Future<ProgressTransfer> _transfer(BuildContext context) async {
  final progress = context.read<ProgressRepository>();
  return ProgressTransfer(
    progress: progress,
    curriculum: await context.read<CurriculumRepository>().load(),
  );
}

/// Lets the parent pick a progress file. Phones accept any file, since a file
/// passed through a chat app may lose its JSON type; reading it checks it.
Future<ProgressFile?> _pick(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final picked = await openFile(
    acceptedTypeGroups: [if (_desktop || kIsWeb) _json],
  );
  if (picked == null) return null;
  try {
    return ProgressFile.decode(await picked.readAsString());
  } on ProgressFileException catch (e) {
    if (context.mounted) {
      _tell(context, switch (e.problem) {
        ProgressFileProblem.notProgress => l10n.progressFileNotProgress,
        ProgressFileProblem.tooNew => l10n.progressFileTooNew,
      });
    }
    return null;
  }
}

void _tell(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));
