import 'package:flutter/cupertino.dart';

/// Compact nav-bar gear used to open Settings from primary tabs.
class SettingsNavButton extends StatelessWidget {
  const SettingsNavButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: const Icon(CupertinoIcons.settings),
    );
  }
}
