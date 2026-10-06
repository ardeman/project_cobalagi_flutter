import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cobalagi/engine/program/program.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/engine/world/level.dart';
import 'package:cobalagi/features/editors/typed/data/typed_program.dart';

final class TypedCodeState {
  const TypedCodeState({
    this.source = '',
    this.program,
    this.issue,
    this.issues = const [],
  });
  final String source;
  final Program? program;
  final CodeIssue? issue;
  final List<ProgramIssue> issues;
  bool get canRun =>
      program != null && program!.body.isNotEmpty && issues.isEmpty;
}

class TypedCodeCubit extends Cubit<TypedCodeState> {
  TypedCodeCubit(this.level) : super(const TypedCodeState());
  final Level level;

  void edit(String source) {
    try {
      final program = compileCode(source);
      emit(
        TypedCodeState(
          source: source,
          program: program,
          issues: validateProgram(program, level),
        ),
      );
    } on CodeIssue catch (issue) {
      emit(TypedCodeState(source: source, issue: issue));
    }
  }
}
