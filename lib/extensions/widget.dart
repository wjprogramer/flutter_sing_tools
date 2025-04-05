import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

extension StateX on State {
  void safeSetState([VoidCallback? fn]) {
    fn?.call();
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {});
    }
  }
}

extension NumWidgetX on num {
  Widget get gap {
    return Gap(toDouble());
  }
}