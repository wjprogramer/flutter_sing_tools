import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    this.text,
    this.onPressed,
    this.page,

  });

  final String? text;

  final VoidCallback? onPressed;

  final Widget? page;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed ?? () {
        if (page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page!),
          );
        }
      },
      child: Text(text ?? ''),
    );
  }
}
