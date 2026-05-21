import 'package:assignment/bmi_history_page.dart';
import 'package:assignment/bmi_page.dart';
import 'package:assignment/converter_page.dart';
import 'package:assignment/logout_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  String userName = "there";

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  void fetchUserName() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .single();

      setState(() {
        userName = data['name'] ?? "there";
      });
    } catch (e) {
      setState(() {
        userName = "there";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: const Icon(Icons.grid_view_rounded, color: Colors.white),

        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Logout",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LogoutPage()),
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "👋 Hi $userName!",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Welcome back!",
              style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 18),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const ConverterPage();
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.amber,
                ),
                icon: const Icon(Icons.currency_exchange_rounded),
                label: const Text(
                  "Converter Page",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 20),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const BmiCalculatorPage();
                      },
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text(
                  "BMI Calculator",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 20),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BmiHistoryPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text(
                  "BMI History",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
