import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SkincareApp());
}

class SkincareApp extends StatelessWidget {
  const SkincareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData();
    return MaterialApp(
      title: 'Skincare Routine',
      theme: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: Colors.deepPurple),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        textTheme: theme.textTheme.copyWith(
          titleLarge: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.black),
          labelMedium: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.black),
        ),
      ),
      home: const HomePage(),
    );
  }
}
