import 'package:flutter/cupertino.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Schedule'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('Schedule page'),
        ),
      ),
    );
  }
}
