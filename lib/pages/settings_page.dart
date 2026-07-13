import 'package:flutter/cupertino.dart';
import 'package:tutor_app/l10n/l10n_ext.dart';
import 'package:tutor_app/theme/ios26_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.userName,
    required this.onLogout,
    super.key,
  });

  final String userName;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.settings),
        border: appNavigationBarBorder,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.signedInAs(userName),
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton.filled(
                onPressed: onLogout,
                child: Text(l10n.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
