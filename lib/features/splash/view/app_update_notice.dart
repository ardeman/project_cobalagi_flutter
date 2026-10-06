import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:cobalagi/features/splash/cubit/app_update_cubit.dart';
import 'package:flutter/material.dart';

/// A skippable notice; the owning screen gates the update action for parents.
class AppUpdateNotice extends StatelessWidget {
  const AppUpdateNotice({
    super.key,
    required this.state,
    required this.onUpdate,
    required this.onContinue,
  });

  final AppUpdateState state;
  final VoidCallback onUpdate;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final opening = state.status == UpdateStatus.opening;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GlassSurface(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.updateAvailableTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(l10n.updateAvailableBody, textAlign: TextAlign.center),
              if (state.status == UpdateStatus.openFailed) ...[
                const SizedBox(height: 12),
                Text(l10n.updateOpenFailed, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: opening ? null : onUpdate,
                icon: const Icon(Icons.system_update_rounded),
                label: Text(l10n.updateWithParent, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(64, 64)),
                onPressed: onContinue,
                child: Text(l10n.updateContinue, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
