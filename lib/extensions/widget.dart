import 'package:flutter/widgets.dart';

extension StateX on State {
  void safeSetState([VoidCallback? fn]) {
    fn?.call();
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {});
    }
  }
}