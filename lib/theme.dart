import 'package:flutter/material.dart';

class CalendarTheme {
  static const indigo = Color(0xFF536DFE);
  static const coral = Color(0xFFFF7A59);
  static ThemeData light = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: indigo), scaffoldBackgroundColor: const Color(0xFFF7F8FC), appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0), cardTheme: CardThemeData(elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22)))));
  static ThemeData dark = ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: indigo, brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF111421), appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0));
}