import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sing_tools/pages/splash_page.dart';

import 'app/bloc_observer.dart';

void main() async {
  Bloc.observer = const MyBlocObserver();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashPage(),
    );
  }
}
