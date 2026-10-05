import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';

/// Asks a multiplication question that young children can't answer, as Google
/// Play Families requires before settings and purchases. Returns true on success.
Future<bool> showParentGate(BuildContext context, {Random? random}) async {
  final rng = random ?? Random();
  final a = 3 + rng.nextInt(7);
  final b = 3 + rng.nextInt(7);
  final passed = await showDialog<bool>(
    context: context,
    builder: (_) => _ParentGateDialog(a: a, b: b),
  );
  return passed ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog({required this.a, required this.b});

  final int a;
  final int b;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _answer = TextEditingController();
  var _wrong = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _check() {
    if (int.tryParse(_answer.text.trim()) == widget.a * widget.b) {
      Navigator.pop(context, true);
    } else {
      setState(() => _wrong = true);
      _answer.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.askAGrownUp),
      content: TextField(
        key: const Key('parentGateAnswer'),
        controller: _answer,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.parentGateQuestion(widget.a, widget.b),
          errorText: _wrong ? l10n.parentGateWrong : null,
        ),
        onSubmitted: (_) => _check(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _check, child: Text(l10n.ok)),
      ],
    );
  }
}
