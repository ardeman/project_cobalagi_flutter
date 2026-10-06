import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/widgets/glass_background.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';

import '../core/audio/audio_service.dart';
import '../core/audio/music_cubit.dart';
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
    this.updates = const NoAppUpdateService(),
  });

  final ProfileRepository profiles;
  final SettingsRepository settings;
  final EntitlementService entitlement;
  final AudioService audio;
  final CurriculumRepository curriculum;
  final ProgressRepository progress;
  final AppUpdateService updates;

  @override
  State<CobaLagiApp> createState() => _CobaLagiAppState();
}

class _CobaLagiAppState extends State<CobaLagiApp> with WidgetsBindingObserver {
  late final GoRouter _router = createRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Music pauses while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.audio.foreground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      RepositoryProvider.value(value: widget.updates),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit(widget.settings)..load()),
        // Not lazy: these apply the saved settings to the audio at launch,
        // not first when the parent area reads them.
        BlocProvider(
          lazy: false,
          create: (_) =>
              SoundEffectsCubit(widget.settings, widget.audio)..load(),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => MusicCubit(widget.settings, widget.audio)..load(),
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
          builder: (context, child) => GlassBackground(child: child!),
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
