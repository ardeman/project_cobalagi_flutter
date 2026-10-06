import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_service.dart';
import '../core/audio/sound_effects_cubit.dart';
import '../core/entitlement/entitlement_cubit.dart';
import '../core/entitlement/entitlement_service.dart';
import '../core/settings/settings_cubit.dart';
import '../core/settings/settings_repository.dart';
import '../features/learning/data/curriculum_repository.dart';
import '../features/learning/data/progress_repository.dart';
import '../features/profiles/cubit/profiles_cubit.dart';
import '../features/profiles/data/profile_repository.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class CobaLagiApp extends StatefulWidget {
  const CobaLagiApp({
    super.key,
    required this.profiles,
    required this.settings,
    required this.entitlement,
    required this.audio,
    required this.curriculum,
    required this.progress,
  });

  final ProfileRepository profiles;
  final SettingsRepository settings;
  final EntitlementService entitlement;
  final AudioService audio;
  final CurriculumRepository curriculum;
  final ProgressRepository progress;

  @override
  State<CobaLagiApp> createState() => _CobaLagiAppState();
}

class _CobaLagiAppState extends State<CobaLagiApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    widget.entitlement.dispose();
    widget.audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: widget.audio),
      RepositoryProvider.value(value: widget.curriculum),
      RepositoryProvider.value(value: widget.progress),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit(widget.settings)..load()),
        BlocProvider(
          create: (_) =>
              SoundEffectsCubit(widget.settings, widget.audio)..load(),
        ),
        BlocProvider(
          create: (_) => EntitlementCubit(widget.entitlement)..load(),
        ),
        BlocProvider(
          create: (_) =>
              ProfilesCubit(widget.profiles, progress: widget.progress)..load(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, Locale?>(
        builder: (context, locale) => MaterialApp.router(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          // null follows the device; languages other than id/en fall back to English.
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: _router,
        ),
      ),
    ),
  );
}
