import 'package:ecg_analysis2/Screens/home_screen.dart';
import 'package:ecg_analysis2/Screens/result-screen.dart';
import 'package:ecg_analysis2/theme/main-theme.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECG Analyzer',
      debugShowCheckedModeBanner: false,
      theme: mainTheme,
      initialRoute: "/",
      routes: {
        HomeScreen.path: (context) => const HomeScreen(),
        ResultScreen.path: (context) => const ResultScreen(),
      },
    );
  }
}
