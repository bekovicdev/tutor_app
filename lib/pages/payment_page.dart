import 'package:flutter/cupertino.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Payment'),
      ),
      child: SafeArea(
        child: Center(
          child: Text('Payment page'),
        ),
      ),
    );
  }
}
