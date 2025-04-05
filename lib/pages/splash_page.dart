import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/pages/home_page.dart';
import 'package:flutter_sing_tools/utilities/utilities.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _init().then((_) => _safeGoHomePage());
  }

  Future<void> _init() async {
    await Future.wait([
      MyFileUtility.init(),
    ]);
  }

  void _safeGoHomePage() {
    if (mounted) {
      _goHomePage();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goHomePage();
    });
  }

  void _goHomePage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MyHomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    );
  }
}
