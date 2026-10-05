import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/entitlement/entitlement_cubit.dart';
import '../../../core/entitlement/entitlement_service.dart';
import '../../../core/entitlement/plan.dart';

/// Donation choices from the store. Shown only in the parent area, behind the
/// parent gate, as Google Play Families requires.
Future<void> showDonationSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  builder: (_) => BlocProvider.value(
    value: context.read<EntitlementCubit>(),
    child: const _DonationSheet(),
  ),
);

class _DonationSheet extends StatefulWidget {
  const _DonationSheet();

  @override
  State<_DonationSheet> createState() => _DonationSheetState();
}

class _DonationSheetState extends State<_DonationSheet> {
  late final Future<List<DonationOption>> _options = context
      .read<EntitlementCubit>()
      .service
      .donationOptions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final service = context.read<EntitlementCubit>().service;
    final plan = context.watch<EntitlementCubit>().state;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              plan == Plan.full
                  ? Icons.favorite_rounded
                  : Icons.volunteer_activism_rounded,
              size: 56,
              color: Colors.pink,
            ),
            const SizedBox(height: 12),
            Text(
              plan == Plan.full ? l10n.thanksForSupport : l10n.donateExplainer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            if (plan == Plan.free)
              FutureBuilder(
                future: _options,
                builder: (context, snapshot) {
                  final options = snapshot.data;
                  if (options == null) {
                    return const CircularProgressIndicator();
                  }
                  if (options.isEmpty) return Text(l10n.donateUnavailable);
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final option in options)
                        FilledButton(
                          onPressed: () => service.donate(option),
                          child: Text(option.price),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 12),
            if (plan == Plan.free)
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  TextButton(
                    onPressed: service.restore,
                    child: Text(l10n.restoreDonation),
                  ),
                  TextButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<EntitlementCubit>(),
                        child: const _UnlockCodeDialog(),
                      ),
                    ),
                    child: Text(l10n.haveUnlockCode),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Unlocks the supporter plan with a code, e.g. one given to store reviewers.
class _UnlockCodeDialog extends StatefulWidget {
  const _UnlockCodeDialog();

  @override
  State<_UnlockCodeDialog> createState() => _UnlockCodeDialogState();
}

class _UnlockCodeDialogState extends State<_UnlockCodeDialog> {
  final _code = TextEditingController();
  var _rejected = false;

  Future<void> _submit() async {
    final accepted = await context.read<EntitlementCubit>().redeem(_code.text);
    if (!mounted) return;
    if (accepted) {
      Navigator.pop(context);
    } else {
      setState(() => _rejected = true);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.haveUnlockCode),
      content: TextField(
        controller: _code,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: l10n.unlockCode,
          errorText: _rejected ? l10n.unlockCodeRejected : null,
        ),
        onChanged: (_) {
          if (_rejected) setState(() => _rejected = false);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.useUnlockCode)),
      ],
    );
  }
}
