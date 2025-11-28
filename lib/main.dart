import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_time_tracker/screens/home_page.dart';
import 'package:study_time_tracker/theme/coffee_dark_theme.dart';
import 'package:study_time_tracker/theme/coffee_light_theme.dart';
import 'package:study_time_tracker/theme/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const StudyApp(),
    ),
  );
}
/* ------------------- MAIN APP & UI ------------------- */

class StudyApp extends StatelessWidget {
  const StudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Study Time Tracker',
          theme: theme.isDark ? coffeeDarkTheme : coffeeLightTheme,
          home: const HomePage(),
        );
      },
    );
  }
}
