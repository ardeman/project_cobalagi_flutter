import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/learning_cubit.dart';
import '../data/curriculum_repository.dart';
import '../data/progress_repository.dart';

/// Provides a [LearningCubit] for one child to every screen below it.
class ChildScope extends StatefulWidget {
  const ChildScope({super.key, required this.profileId, required this.child});

  final int profileId;
  final Widget child;

  @override
  State<ChildScope> createState() => _ChildScopeState();
}

class _ChildScopeState extends State<ChildScope> {
  late final _curriculum = context.read<CurriculumRepository>().load();

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _curriculum,
    builder: (context, snapshot) {
      final curriculum = snapshot.data;
      if (curriculum == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return BlocProvider(
        create: (context) => LearningCubit(
          profileId: widget.profileId,
          curriculum: curriculum,
          progress: context.read<ProgressRepository>(),
        )..load(),
        child: widget.child,
      );
    },
  );
}
