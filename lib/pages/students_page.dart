import 'package:flutter/cupertino.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Students'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('Students page'),
        ),
      ),
    );
  }
}
