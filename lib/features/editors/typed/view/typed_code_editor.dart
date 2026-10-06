import 'package:flutter/material.dart';
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
            EmptyRepeat() || EmptyCondition() => l.codeEmptyBody,
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
      InstructionKind.call: (l.blockStar, 'star();'),
    };
    return GlassSurface(
      padding: const EdgeInsets.all(12),
      child: ListView(
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
class _CodeController extends TextEditingController {
  _CodeController({super.text});
  int? activeLine;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (activeLine == null || (withComposing && value.composing.isValid)) {
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
            text: '${lines[i]}${i < lines.length - 1 ? '\n' : ''}',
            style: i + 1 == activeLine
                ? const TextStyle(backgroundColor: Color(0x66FFD54F))
                : null,
          ),
      ],
    );
  }
}
