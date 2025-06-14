import 'package:flutter/material.dart';

class FSPadding extends StatelessWidget {
  const FSPadding({
    super.key,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 24,
    ),
    this.child,
  });

  final EdgeInsetsGeometry padding;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
