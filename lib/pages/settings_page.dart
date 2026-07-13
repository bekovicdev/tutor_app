import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Settings'),
        border: appNavigationBarBorder,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Signed in as $userName',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 12),
              CupertinoButton.filled(
                onPressed: onLogout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
