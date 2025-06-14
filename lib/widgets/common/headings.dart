import 'package:flutter/material.dart';

class FSTitle extends StatelessWidget {
  const FSTitle(this.text, {
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        top: 18,
        bottom: 6,
      ),
      child: Text(
        text,
        style: theme.textTheme.titleMedium,
      ),
    );
  }
}
