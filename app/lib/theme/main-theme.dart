import 'package:flutter/material.dart';

final ThemeData mainTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Roboto',
  scaffoldBackgroundColor: const Color(
    0xFF121212,
  ), // Dark background similar to ECG monitor
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(
      255,
      5,
      133,
      48,
    ), // Slightly lighter blue for contrast
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  // cardTheme: CardTheme(
  //   color: const Color(0xFF1E1E1E), // Dark cards to match the theme
  //   elevation: 2,
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(12),
  //   ),
  // ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(color: Colors.white), // For the ECG data values
    bodyMedium: TextStyle(color: Colors.white70), // For labels
  ),
);
