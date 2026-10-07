import 'package:flutter/material.dart';
import 'package:cobalagi/features/editors/blocks/data/block.dart';
import 'package:cobalagi/features/editors/blocks/view/block_tile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:cobalagi/engine/program/instruction.dart';
import 'package:cobalagi/engine/program/validation.dart';
import 'package:cobalagi/features/editors/typed/cubit/typed_code_cubit.dart';
import 'package:cobalagi/features/editors/typed/data/typed_program.dart';
import 'package:cobalagi/core/widgets/glass_popups.dart';

class TypedCodeEditor extends StatefulWidget {
  const TypedCodeEditor({
    super.key,
    required this.enabled,
    this.activeBlockId,
    this.fitContent = false,
  });
  final bool enabled;
  final String? activeBlockId;

  /// Takes the height of its content, for a page that scrolls (phones).
  final bool fitContent;

  @override
  State<TypedCodeEditor> createState() => _TypedCodeEditorState();
}

class _TypedCodeEditorState extends State<TypedCodeEditor> {
  late final _controller = _CodeController(
    text: context.read<TypedCodeCubit>().state.source,
  );
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _insert(String snippet) {
    final value = _controller.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : start;
    final prefix = start > 0 && value.text[start - 1] != '\n' ? '\n' : '';
    final addition = '$prefix$snippet\n';
    final text = value.text.replaceRange(start, end, addition);
    if (text.length > 8000) return;
    final brace = addition.indexOf('{');
    final caret = brace < 0 ? start + addition.length : start + brace + 4;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret),
    );
    context.read<TypedCodeCubit>().edit(text);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cubit = context.watch<TypedCodeCubit>();
    final state = cubit.state;
    _controller.activeLine = widget.activeBlockId == null
        ? null
        : codeLine(state.source, widget.activeBlockId);
    final issue = state.issue;
    final programIssue = state.issues.firstOrNull;
    final message = issue != null
        ? switch (issue.problem) {
            CodeProblem.syntax => l.codeSyntax,
            CodeProblem.number => l.codeNumber,
            CodeProblem.duplicateStar => l.codeDuplicateStar,
            CodeProblem.nestedStar => l.codeNestedStar,
            CodeProblem.tooLarge => l.codeTooLarge,
          }
        : programIssue != null
        ? switch (programIssue) {
            DisallowedInstruction() => l.codeDisallowed,
            TooManyBlocks() => l.codeLimit,
            EmptyRepeat() ||
            EmptyCondition() ||
            EmptyUntil() => l.codeEmptyBody,
            EmptyProcedure() => l.codeEmptyStar,
            CallInProcedure() => l.codeRecursiveStar,
            CountOutOfRange() => l.codeNumber,
            UnsetSteps() => l.codeUnsetSteps,
          }
        : null;
    final snippets = <InstructionKind, (String, String)>{
      InstructionKind.move: (l.blockForward, 'move();'),
      InstructionKind.setSteps: (l.blockSetSteps, 'steps = 2;'),
      InstructionKind.moveSteps: (l.blockMoveSteps, 'move(steps);'),
      InstructionKind.turnLeft: (l.blockTurnLeft, 'turn_left();'),
      InstructionKind.turnRight: (l.blockTurnRight, 'turn_right();'),
      InstructionKind.repeat: (l.blockRepeat, 'repeat(2) {\n  \n}'),
      InstructionKind.ifPathClear: (
        l.blockIfPathClear,
        'if_path_clear {\n  \n}',
      ),
      InstructionKind.ifElse: (
        l.blockIfElse,
        'if_path_clear {\n  \n} otherwise {\n  \n}',
      ),
      InstructionKind.call: (l.blockStar, 'star();'),
      InstructionKind.untilGoal: (l.blockUntilGoal, 'until_flag {\n  \n}'),
    };
    return GlassSurface(
      padding: const EdgeInsets.all(12),
      child: ListView(
        // The panel pads itself; the screen's padding (such as glass bars)
        // belongs to the page, not to this list.
        padding: EdgeInsets.zero,
        // Phones scroll the whole page instead.
        shrinkWrap: widget.fitContent,
        physics: widget.fitContent
            ? const NeverScrollableScrollPhysics()
            : null,
        children: [
          TextField(
            key: const Key('typedCodeSource'),
            controller: _controller,
            focusNode: _focus,
            readOnly: !widget.enabled,
            minLines: 5,
            maxLines: 12,
            maxLength: 8000,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              height: 1.5,
            ),
            decoration: InputDecoration(
              labelText: l.codeSource,
              alignLabelWithHint: true,
              counterText: '',
            ),
            onChanged: cubit.edit,
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.activeBlockId != null
                  ? l.codeRunningLine(
                      codeLine(state.source, widget.activeBlockId),
                    )
                  : message != null
                  ? l.codeLine(
                      issue?.line ??
                          codeLine(state.source, programIssue?.blockId),
                      message,
                    )
                  : state.canRun
                  ? l.codeReady
                  : l.codeStart,
              style: TextStyle(
                color: message != null
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ),
          if (cubit.level.maxBlocks case final max?)
            Text('${state.program?.blockCount ?? 0} / $max'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in cubit.level.palette)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 64),
                  ),
                  onPressed: widget.enabled
                      ? () => _insert(snippets[kind]!.$2)
                      : null,
                  child: Text(
                    '${snippets[kind]!.$1}\n${snippets[kind]!.$2.split('\n').first}',
                  ),
                ),
              if (cubit.level.palette.contains(InstructionKind.call))
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 64),
                  ),
                  onPressed: widget.enabled
                      ? () => _insert('define star {\n  \n}')
                      : null,
                  child: Text(l.codeDefineStar),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.codeDrafts),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(64, 64)),
            onPressed: () => showGlassDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l.codeHelp),
                content: SingleChildScrollView(child: Text(l.codeGuide)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ),
                ],
              ),
            ),
            child: Text(l.codeHelp),
          ),
        ],
      ),
    );
  }
}

/// Highlights the executing source line without changing the child's selection.
/// Commands coloured like their blocks, so code reads like the blocks a
/// child knows: forward green, turns blue and orange, repeat purple.
final _commandColours = <RegExp, BlockType>{
  RegExp(r'\bmove\(\s*steps\s*\)'): BlockType.moveSteps,
  RegExp(r'\bmove\b'): BlockType.forward,
  RegExp(r'\bturn_left\b'): BlockType.turnLeft,
  RegExp(r'\bturn_right\b'): BlockType.turnRight,
  RegExp(r'\brepeat\b'): BlockType.repeat,
  // An if with an otherwise takes the otherwise block's colour. Its rows
  // hold only actions, so no braces nest inside them.
  RegExp(r'\bif_path_clear\b(?=\s*\{[^{}]*\}\s*otherwise\b)'): BlockType.ifElse,
  RegExp(r'\botherwise\b'): BlockType.ifElse,
  RegExp(r'\bif_path_clear\b'): BlockType.ifPathClear,
  RegExp(r'\buntil_flag\b'): BlockType.untilGoal,
  RegExp(r'\b(star|define)\b'): BlockType.star,
  RegExp(r'\bsteps\b'): BlockType.setSteps,
};

/// [text] split into spans, commands in their block's colour (darkened a
/// little to read well on the light editor) and comments greyed.
@visibleForTesting
List<TextSpan> colouredCode(String text) {
  final colours = List<Color?>.filled(text.length, null);
  final comment = RegExp(r'//[^\n]*');
  for (final MapEntry(key: pattern, value: type) in _commandColours.entries) {
    for (final match in pattern.allMatches(text)) {
      for (var i = match.start; i < match.end; i++) {
        colours[i] ??= Color.lerp(type.color, const Color(0xFF000000), 0.18);
      }
    }
  }
  for (final match in comment.allMatches(text)) {
    for (var i = match.start; i < match.end; i++) {
      colours[i] = const Color(0xFF7A8A8A);
    }
  }
  final spans = <TextSpan>[];
  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    if (i == text.length || colours[i] != colours[start]) {
      final colour = colours[start];
      spans.add(
        TextSpan(
          text: text.substring(start, i),
          style: colour == null
              ? null
              : TextStyle(color: colour, fontWeight: FontWeight.w700),
        ),
      );
      start = i;
    }
  }
  return spans;
}

class _CodeController extends TextEditingController {
  _CodeController({super.text});
  int? activeLine;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // While the keyboard composes a word, keep the platform's own styling.
    if (withComposing && value.composing.isValid) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final lines = text.split('\n');
    return TextSpan(
      style: style,
      children: [
        for (var i = 0; i < lines.length; i++)
          TextSpan(
            style: i + 1 == activeLine
                ? const TextStyle(backgroundColor: Color(0x66FFD54F))
                : null,
            children: colouredCode(
              '${lines[i]}${i < lines.length - 1 ? '\n' : ''}',
            ),
          ),
      ],
    );
  }
}
