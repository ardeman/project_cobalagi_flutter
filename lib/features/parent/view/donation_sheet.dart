import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/entitlement/entitlement_cubit.dart';
import '../../../core/entitlement/entitlement_service.dart';
import '../../../core/entitlement/plan.dart';
import '../../../core/entitlement/purchased_code.dart';
import '../../../core/entitlement/store_rules.dart';
import 'package:cobalagi/core/widgets/glass_popups.dart';
import 'package:cobalagi/core/widgets/typing_dialog.dart';

/// Donation choices from the store. Shown only in the parent area, behind the
/// parent gate, as Google Play Families requires. App Store builds call them
/// tips and offer no unlock code ([StoreRules]); GitHub builds, which have no
/// store, link to the shop that sells codes instead.
Future<void> showDonationSheet(BuildContext context) => showGlassSheet(
  context: context,
  showDragHandle: true,
  builder: (_) => BlocProvider.value(
    value: context.read<EntitlementCubit>(),
    child: _DonationSheet(rules: context.read<StoreRules>()),
  ),
);

class _DonationSheet extends StatefulWidget {
  const _DonationSheet({required this.rules});

  final StoreRules rules;

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
    final rules = widget.rules;
    // Scrolls when the sheet is short, as on a phone held sideways.
    return SafeArea(
      child: SingleChildScrollView(
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
              plan == Plan.full
                  ? l10n.thanksForSupport
                  : rules.appStore
                  ? l10n.tipExplainer
                  : l10n.donateExplainer,
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
                  if (options.isEmpty && rules.allowsPurchasedCodes) {
                    return Column(
                      children: [
                        Text(
                          l10n.buyUnlockCodeExplainer,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => launchUrl(
                            StoreRules.shop,
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(l10n.buyUnlockCode),
                        ),
                      ],
                    );
                  }
                  if (options.isEmpty) {
                    return Text(
                      rules.appStore
                          ? l10n.tipsUnavailable
                          : l10n.donateUnavailable,
                    );
                  }
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
                    child: Text(
                      rules.appStore
                          ? l10n.restorePurchases
                          : l10n.restoreDonation,
                    ),
                  ),
                  if (rules.allowsUnlockCodes)
                    TextButton(
                      onPressed: () => showGlassDialog<void>(
                        context: context,
                        builder: (_) => BlocProvider.value(
                          value: context.read<EntitlementCubit>(),
                          child: _UnlockCodeDialog(rules: rules),
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

/// Unlocks the supporter plan with a code: one given to store reviewers, or
/// in GitHub builds one bought on the website.
class _UnlockCodeDialog extends StatefulWidget {
  const _UnlockCodeDialog({required this.rules});

  final StoreRules rules;

  @override
  State<_UnlockCodeDialog> createState() => _UnlockCodeDialogState();
}

class _UnlockCodeDialogState extends State<_UnlockCodeDialog> {
  final _code = TextEditingController();
  var _rejected = false;

  /// Whether the rejected code was bought on the website, which this build
  /// may not take (Google Play), so the parent learns it is for GitHub's app.
  var _githubOnly = false;

  Future<void> _submit() async {
    final accepted = await context.read<EntitlementCubit>().redeem(_code.text);
    if (!mounted) return;
    if (accepted) {
      Navigator.pop(context);
    } else {
      setState(() {
        _rejected = true;
        _githubOnly =
            !widget.rules.allowsPurchasedCodes &&
            PurchasedCodes.decode(_code.text) != null;
      });
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
    return TypingDialog(
      title: Text(l10n.haveUnlockCode),
      content: TextField(
        controller: _code,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: l10n.unlockCode,
          errorText: _githubOnly
              ? l10n.unlockCodeGithubOnly
              : _rejected
              ? l10n.unlockCodeRejected
              : null,
          errorMaxLines: 3,
        ),
        onChanged: (_) {
          if (_rejected) setState(() => _rejected = false);
        },
        onSubmitted: (_) => _submit(),
      ),
      confirmLabel: l10n.useUnlockCode,
      onConfirm: _submit,
      onCancel: () => Navigator.pop(context),
    );
  }
}
