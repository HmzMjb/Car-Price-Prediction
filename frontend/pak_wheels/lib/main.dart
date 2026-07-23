import 'package:flutter/material.dart';
import 'prediction_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PakWheels Price Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE50000), // PakWheels red
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PredictionScreen(),
    );
  }
}
