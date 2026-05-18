import 'package:assignment/auth_gate.dart';
import 'package:assignment/bmi_page.dart';
import 'package:assignment/converter_page.dart';
import 'package:assignment/home_page.dart';
import 'package:assignment/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://uyncxaniomehxwpgfnns.supabase.co",
    anonKey: "sb_publishable_mQBwk3ESlB6-RczYV7C7hA_J4n0RNBZ",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // theme: ThemeData.dark(),
      home: AuthGate(),
    );
  }
}
