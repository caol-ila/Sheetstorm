import 'package:flutter/material.dart';

void main() {
  runApp(const PdfLabelerApp());
}

class PdfLabelerApp extends StatelessWidget {
  const PdfLabelerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sheetstorm PDF Labeler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('PDF Labeler - Coming Soon'),
        ),
      ),
    );
  }
}
