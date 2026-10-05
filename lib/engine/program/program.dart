import 'instruction.dart';

final class Program {
  const Program(this.body);

  final List<Instruction> body;

  int get blockCount =>
      body.fold(0, (sum, instruction) => sum + instruction.blockCount);
}
