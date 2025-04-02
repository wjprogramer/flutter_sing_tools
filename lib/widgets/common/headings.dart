import 'package:flutter/material.dart';

class MyTitle extends StatelessWidget {
  const MyTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}
