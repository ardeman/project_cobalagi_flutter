import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/version/app_version_text.dart';
import '../../profiles/cubit/profiles_cubit.dart';

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
  var _waited = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.minimum, _maybeLeave);
  }

  void _maybeLeave() {
    _waited = true;
    if (mounted && context.read<ProfilesCubit>().state.loaded) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return BlocListener<ProfilesCubit, ProfilesState>(
      listenWhen: (before, after) => !before.loaded && after.loaded,
      listener: (context, _) {
        if (_waited) context.go('/');
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.primaryContainer,
        body: SafeArea(
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
    );
  }
}
