import 'package:assignment/bmi_history_page.dart';
import 'package:assignment/bmi_page.dart';
import 'package:assignment/converter_page.dart';
import 'package:assignment/logout_page.dart';
import 'package:assignment/main.dart';
import 'package:assignment/profile_page.dart';
import 'package:assignment/water_intake_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:assignment/sleep_tracker_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
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
    if (user == null) return;

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

  Widget homeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    final color = iconColor ?? colors.primary;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.color!.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = ThemeController.themeMode.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        leading: const Icon(Icons.grid_view_rounded),
        actions: [
          IconButton(
            tooltip: isDark ? "Light Mode" : "Dark Mode",
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                ThemeController.toggleTheme();
              });
            },
          ),
          // Profile icon shortcut
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: "Profile",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Logout",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogoutPage()),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi $userName 👋",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Welcome back",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Text(
                      "Choose an option",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Currency Converter ──
                    homeButton(
                      icon: Icons.currency_exchange_rounded,
                      title: "Currency Converter",
                      subtitle: "Convert live currency rates",
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConverterPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── BMI Calculator ──
                    homeButton(
                      icon: Icons.calculate_outlined,
                      title: "BMI Calculator",
                      subtitle: "Calculate your body mass index",
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BmiCalculatorPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── BMI History ──
                    homeButton(
                      icon: Icons.history_rounded,
                      title: "BMI History",
                      subtitle: "View, edit, and delete saved records",
                      iconColor: const Color(0xFF6C63FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BmiHistoryPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── Water Tracker (NEW) ──
                    homeButton(
                      icon: Icons.water_drop_outlined,
                      title: "Water Tracker",
                      subtitle: "Track your daily water intake",
                      iconColor: const Color(0xFF2196F3),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WaterIntakePage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    homeButton(
                      icon: Icons.bedtime_outlined,
                      title: "Sleep Tracker",
                      subtitle: "Log and track your sleep",
                      iconColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SleepTrackerPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
