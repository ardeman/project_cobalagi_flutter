import 'instruction.dart';

final class Program {
  const Program(this.body, {this.procedure = const []});

  final List<Instruction> body;

  /// What a [Call] runs: the child's own block. Empty when the program has
  /// none.
  final List<Instruction> procedure;

  int get blockCount => _count(body) + _count(procedure);

  static int _count(List<Instruction> instructions) =>
      instructions.fold(0, (sum, instruction) => sum + instruction.blockCount);
}
