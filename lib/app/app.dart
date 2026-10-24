import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/gamepad/gamepad_cubit.dart';
import 'package:cobalagi/core/gamepad/gamepad_navigator.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:cobalagi/core/gamepad/screen_keyboard.dart';
import 'package:cobalagi/core/responsive/fold.dart';
import 'package:cobalagi/core/widgets/glass_background.dart';
import 'package:cobalagi/features/splash/cubit/app_update_cubit.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';

import '../features/play_time/cubit/break_reminder_cubit.dart';
import '../features/play_time/data/play_clock.dart';
import '../core/audio/audio_service.dart';
import '../core/audio/music_cubit.dart';
import '../core/audio/sound_effects_cubit.dart';
import '../core/entitlement/entitlement_cubit.dart';
import '../core/entitlement/entitlement_service.dart';
import '../core/entitlement/store_rules.dart';
import '../core/settings/app_language.dart';
import '../core/settings/hint_arrows_cubit.dart';
import '../core/settings/settings_cubit.dart';
import '../core/settings/settings_repository.dart';
import '../features/learning/data/curriculum_repository.dart';
import '../features/learning/data/progress_repository.dart';
import '../features/profiles/cubit/profiles_cubit.dart';
import '../features/profiles/data/profile_repository.dart';
import 'fallback_localizations.dart';
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
    this.storeRules = const StoreRules(appStore: false),
    this.padCommands,
    this.keyboard,
    this.hingeHalfOpen,
  });

  final ProfileRepository profiles;
  final SettingsRepository settings;
  final EntitlementService entitlement;
  final AudioService audio;
  final CurriculumRepository curriculum;
  final ProgressRepository progress;
  final AppUpdateService updates;

  /// What the store this build is sold through allows ([StoreRules.current]).
  final StoreRules storeRules;

  /// Controller input ([controllerCommands]); null in tests.
  final Stream<PadCommand>? padCommands;

  /// An on-screen keyboard for text fields ([steamKeyboard]); null where
  /// the system opens and closes its own.
  final ScreenKeyboard? keyboard;

  /// Whether the iPhone's hinge is half open ([hingeHalfOpen]); null where
  /// the system reports folds itself, and in tests.
  final Stream<bool>? hingeHalfOpen;

  @override
  State<CobaLagiApp> createState() => _CobaLagiAppState();
}

class _CobaLagiAppState extends State<CobaLagiApp> with WidgetsBindingObserver {
  late final GoRouter _router = createRouter();

  /// Puzzle time since the last break, for the parent's break reminder.
  final _playClock = PlayClock()..attach();

  /// Asks the store for an update at launch, and again on coming back.
  late final _updates = AppUpdateCubit(widget.updates)..check();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Music pauses while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.audio.foreground = state == AppLifecycleState.resumed;
    // Play may have learned of an update while the app was away.
    if (state == AppLifecycleState.resumed) _updates.check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playClock.detach();
    _updates.close();
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
      RepositoryProvider.value(value: widget.storeRules),
      RepositoryProvider.value(value: _playClock),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit(widget.settings)..load()),
        BlocProvider.value(value: _updates),
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
          lazy: false,
          create: (_) => BreakReminderCubit(widget.settings)..load(),
        ),
        BlocProvider(create: (_) => HintArrowsCubit(widget.settings)..load()),
        BlocProvider(create: (_) => GamepadCubit()),
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
          builder: (context, child) => HingeFold(
            halfOpen: widget.hingeHalfOpen,
            child: GamepadNavigator(
              commands: widget.padCommands,
              child: ScreenKeyboardOnFocus(
                keyboard: widget.keyboard,
                child: GlassBackground(child: child!),
              ),
            ),
          ),
          // null follows the device; languages the app doesn't offer fall
          // back to English, and a saved language no longer offered (its
          // voice isn't finished) follows the device.
          locale: AppLanguage.of(locale?.languageCode ?? '')?.voiced == true
              ? locale
              : null,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          routerConfig: _router,
        ),
      ),
    ),
  );
}
