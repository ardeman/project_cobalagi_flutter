import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/features/splash/cubit/app_update_cubit.dart';
import 'package:cobalagi/features/splash/data/app_update_service.dart';
import 'package:cobalagi/features/parent/view/parent_gate.dart';
import 'package:cobalagi/features/splash/view/app_update_notice.dart';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/version/app_version_text.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';

/// The first screen: the character, the name and the installed version,
/// until the players are loaded and [minimum] has passed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.minimum = const Duration(milliseconds: 1500),
  });

  final Duration minimum;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _timer;
  AppUpdateCubit? _updates;
  var _waited = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minimum, _maybeLeave);
  }

  void _maybeLeave() {
    _waited = true;
    if (mounted &&
        context.read<ProfilesCubit>().state.loaded &&
        _updates?.state.status != UpdateStatus.checking &&
        _updates?.state.update == null) {
      context.go('/');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updates ??= AppUpdateCubit(context.read<AppUpdateService>())..check();
  }

  @override
  void dispose() {
    _timer.cancel();
    _updates?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _updates!,
      child: BlocConsumer<AppUpdateCubit, AppUpdateState>(
        listener: (context, _) {
          if (_waited) _maybeLeave();
        },
        builder: (context, updateState) =>
            BlocListener<ProfilesCubit, ProfilesState>(
              listenWhen: (before, after) => !before.loaded && after.loaded,
              listener: (context, _) {
                if (_waited) _maybeLeave();
              },
              child: Scaffold(
                backgroundColor: theme.colorScheme.primaryContainer,
                body: SafeArea(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.sizeOf(context).height -
                            MediaQuery.paddingOf(context).vertical,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Spacer(),
                            Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                              height: 200,
                              semanticLabel: l10n.appTitle,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.appTitle,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const Spacer(),
                            if (updateState.update != null)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: AppUpdateNotice(
                                  state: updateState,
                                  onUpdate: () async {
                                    if (await showParentGate(context) &&
                                        context.mounted) {
                                      await context
                                          .read<AppUpdateCubit>()
                                          .openUpdate();
                                    }
                                  },
                                  onContinue:
                                      context
                                          .watch<ProfilesCubit>()
                                          .state
                                          .loaded
                                      ? () => context.go('/')
                                      : null,
                                ),
                              ),
                            AppVersionText(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
