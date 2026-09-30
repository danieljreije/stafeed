import 'package:flutter/material.dart';
import 'app/features/home/home_screen.dart';

void main() {
  runApp(const StafeedApp());
}

class StafeedApp extends StatelessWidget {
  const StafeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stafeed',
      home: const HomeScreen(),
       debugShowCheckedModeBanner: false,
    );
  }
}
