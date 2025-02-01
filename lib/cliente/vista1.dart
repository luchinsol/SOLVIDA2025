import 'package:flutter/material.dart';

class Vista1 extends StatefulWidget {
  const Vista1({Key? key}) : super(key: key);

  @override
  State<Vista1> createState() => _Vista1State();
}

class _Vista1State extends State<Vista1> {
  String text = "CLiente 1";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cliente 1'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
