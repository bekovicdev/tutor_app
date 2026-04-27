import 'package:flutter/cupertino.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Journal'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('Journal page'),
        ),
      ),
    );
  }
}
