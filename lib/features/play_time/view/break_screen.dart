import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/widgets/glass_surface.dart';
import '../../parent/view/parent_gate.dart';
import '../data/play_clock.dart';

/// Shown instead of the next puzzle once the parent's break reminder is
/// due. The child can go back to the players; only a grown-up continues.
class BreakScreen extends StatefulWidget {
  const BreakScreen({super.key, required this.onContinue});

  /// Back to puzzles, after the parent gate.
  final VoidCallback onContinue;

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AudioService>().playVoice(
        VoiceClips.breakTime,
        languageCode: Localizations.localeOf(context).languageCode,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: GlassSurface(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bedtime_rounded,
                      size: 120,
                      color: Color(0xFF7E57C2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.breakTitle,
                      textAlign: TextAlign.center,
                      style: text.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.breakBody,
                      textAlign: TextAlign.center,
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.home_rounded),
                          label: Text(l10n.breakHome),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            if (!await showParentGate(context) ||
                                !context.mounted) {
                              return;
                            }
                            context.read<PlayClock>().reset();
                            widget.onContinue();
                          },
                          icon: const Icon(Icons.lock_open_rounded),
                          label: Text(l10n.breakContinue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
