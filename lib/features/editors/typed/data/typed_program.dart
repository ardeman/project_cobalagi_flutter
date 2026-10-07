import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/program.dart';

enum CodeProblem { syntax, number, duplicateStar, nestedStar, tooLarge }

final class CodeIssue implements Exception {
  const CodeIssue(this.problem, this.line);

  final CodeProblem problem;
  final int line;
}

/// A small teaching language, compiled only to the shared instruction set.
/// IDs encode source offsets, so two statements on one line stay distinct.
Program compileCode(String source) => _Parser(source).parse();

int codeLine(String source, String? id) {
  final offset = int.tryParse(id?.replaceFirst('code:', '') ?? '') ?? 0;
  return '\n'
          .allMatches(source.substring(0, offset.clamp(0, source.length)))
          .length +
      1;
}

String formatCode(Program program) {
  String body(List<Instruction> instructions, int depth) =>
      instructions.map((instruction) {
        final indent = '  ' * depth;
        return switch (instruction) {
          SetSteps(:final value) => '${indent}steps = $value;\n',
          MoveSteps() => '${indent}move(steps);\n',
          Move(:final steps) => List.filled(steps, '${indent}move();\n').join(),
          TurnLeft() => '${indent}turn_left();\n',
          TurnRight() => '${indent}turn_right();\n',
          Call() => '${indent}star();\n',
          Repeat(:final times, body: final children) =>
            '${indent}repeat($times) {\n${body(children, depth + 1)}$indent}\n',
          IfPathClear(body: final children) =>
            '${indent}if_path_clear {\n${body(children, depth + 1)}$indent}\n',
          IfElsePathClear(body: final children, :final otherwise) =>
            '${indent}if_path_clear {\n${body(children, depth + 1)}'
                '$indent} otherwise {\n${body(otherwise, depth + 1)}$indent}\n',
          RepeatUntilGoal(body: final children) =>
            '${indent}until_flag {\n${body(children, depth + 1)}$indent}\n',
        };
      }).join();
  return '${program.procedure.isEmpty ? '' : 'define star {\n${body(program.procedure, 1)}}\n\n'}${body(program.body, 0)}';
}

final class _Token {
  const _Token(this.text, this.offset, this.line);
  final String text;
  final int offset;
  final int line;
}

final class _Parser {
  _Parser(this.source);
  final String source;
  final _tokens = <_Token>[];
  var _cursor = 0;
  List<Instruction>? _procedure;

  _Token get _current => _tokens[_cursor];
  Never _fail([CodeProblem problem = CodeProblem.syntax]) =>
      throw CodeIssue(problem, _current.line);

  Program parse() {
    if (source.length > 8000) throw const CodeIssue(CodeProblem.tooLarge, 1);
    final word = RegExp(r'[a-z_]+|[0-9]+|[(){};=]');
    var line = 1;
    var offset = 0;
    while (offset < source.length) {
      final char = source[offset];
      if (char.trim().isEmpty) {
        if (char == '\n') line++;
        offset++;
        continue;
      }
      if (source.startsWith('//', offset)) {
        while (offset < source.length && source[offset] != '\n') {
          offset++;
        }
        continue;
      }
      final match = word.matchAsPrefix(source, offset);
      if (match == null) throw CodeIssue(CodeProblem.syntax, line);
      _tokens.add(_Token(match[0]!, offset, line));
      offset = match.end;
    }
    _tokens.add(_Token('', source.length, line));
    final main = _body(0);
    return Program(main, procedure: _procedure ?? const []);
  }

  bool _take(String text) {
    if (_current.text != text) return false;
    _cursor++;
    return true;
  }

  void _expect(String text) {
    if (!_take(text)) _fail();
  }

  List<Instruction> _body(int depth) {
    if (depth > 16) _fail(CodeProblem.tooLarge);
    final result = <Instruction>[];
    while (_current.text.isNotEmpty && _current.text != '}') {
      final token = _current;
      final id = 'code:${token.offset}';
      _cursor++;
      switch (token.text) {
        case 'move' || 'turn_left' || 'turn_right' || 'star':
          _expect('(');
          final variableMove = token.text == 'move' && _take('steps');
          _expect(')');
          _expect(';');
          result.add(switch (token.text) {
            'move' => variableMove ? MoveSteps(blockId: id) : Move(blockId: id),
            'turn_left' => TurnLeft(blockId: id),
            'turn_right' => TurnRight(blockId: id),
            _ => Call(blockId: id),
          });
        case 'steps':
          _expect('=');
          final value = int.tryParse(_current.text);
          if (value == null || value < 1 || value > 9) {
            _fail(CodeProblem.number);
          }
          _cursor++;
          _expect(';');
          result.add(SetSteps(value, blockId: id));
        case 'repeat':
          _expect('(');
          final count = int.tryParse(_current.text);
          if (count == null || count < 1 || count > 9) {
            _fail(CodeProblem.number);
          }
          _cursor++;
          _expect(')');
          _expect('{');
          final children = _body(depth + 1);
          _expect('}');
          result.add(Repeat(count, children, blockId: id));
        case 'if_path_clear':
          _expect('{');
          final children = _body(depth + 1);
          _expect('}');
          if (_take('otherwise')) {
            _expect('{');
            final otherwise = _body(depth + 1);
            _expect('}');
            result.add(IfElsePathClear(children, otherwise, blockId: id));
          } else {
            result.add(IfPathClear(children, blockId: id));
          }
        case 'until_flag':
          _expect('{');
          final children = _body(depth + 1);
          _expect('}');
          result.add(RepeatUntilGoal(children, blockId: id));
        case 'define':
          if (depth != 0) throw CodeIssue(CodeProblem.nestedStar, token.line);
          if (_procedure != null) {
            throw CodeIssue(CodeProblem.duplicateStar, token.line);
          }
          _expect('star');
          _expect('{');
          _procedure = _body(depth + 1);
          _expect('}');
        default:
          throw CodeIssue(CodeProblem.syntax, token.line);
      }
    }
    if (depth == 0 && _current.text.isNotEmpty) _fail();
    return result;
  }
}
