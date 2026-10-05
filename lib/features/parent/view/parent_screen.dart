import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/entitlement/entitlement_cubit.dart';
import '../../../core/entitlement/plan.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/data/profile.dart';
import '../../profiles/view/profile_avatar.dart';

/// Reached only through the parent gate.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Profile profile) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deletePlayerConfirm(profile.nickname)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ProfilesCubit>().delete(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = context.watch<SettingsCubit>().state?.languageCode;
    final plan = context.watch<EntitlementCubit>().state;
    final profiles = context.watch<ProfilesCubit>().state.profiles;
    final headerStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.parentArea)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.language, style: headerStyle),
              const SizedBox(height: 8),
              SegmentedButton<String?>(
                segments: [
                  ButtonSegment(value: null, label: Text(l10n.languageSystem)),
                  ButtonSegment(
                    value: 'id',
                    label: Text(l10n.languageIndonesian),
                  ),
                  ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ],
                selected: {languageCode},
                onSelectionChanged: (s) =>
                    context.read<SettingsCubit>().setLanguageCode(s.first),
              ),
              const SizedBox(height: 32),
              Text(l10n.plan, style: headerStyle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  plan == Plan.free
                      ? l10n.planFree
                      : l10n.planFull(Plan.full.maxProfiles),
                ),
                trailing: plan == Plan.free
                    ? FilledButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.comingSoon)),
                            ),
                        child: Text(l10n.unlockFullVersion),
                      )
                    : null,
              ),
              if (kDebugMode)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.debugPlanOverride),
                  value: plan == Plan.full,
                  onChanged: (full) => context
                      .read<EntitlementCubit>()
                      .debugOverride(full ? Plan.full : Plan.free),
                ),
              const SizedBox(height: 32),
              Text(l10n.players, style: headerStyle),
              for (final profile in profiles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ProfileAvatar(avatar: profile.avatar, size: 40),
                  title: Text(profile.nickname),
                  trailing: IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, profile),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
