import 'package:flutter/material.dart';

class Vista2 extends StatefulWidget {
  const Vista2({Key? key}) : super(key: key);

  @override
  State<Vista2> createState() => _Vista2State();
}

class _Vista2State extends State<Vista2> {
  String text = "Cliente 2";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CLiente 2'),
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
