import 'package:assignment/converter_page.dart';
import 'package:assignment/home_page.dart';
import 'package:assignment/login_page.dart';
import 'package:assignment/widgets/input_field.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}
