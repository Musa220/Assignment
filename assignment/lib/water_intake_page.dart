import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WaterIntakePage extends StatefulWidget {
  const WaterIntakePage({super.key});

  @override
  State<WaterIntakePage> createState() => _WaterIntakePageState();
}

class _WaterIntakePageState extends State<WaterIntakePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  double totalIntake = 0; // in ml
  double dailyGoal = 2500; // default 2500ml
  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _waveAnim;

  final List<Map<String, dynamic>> quickAmounts = [
    {'label': 'Sip', 'ml': 50, 'icon': Icons.water_drop_outlined},
    {'label': 'Glass', 'ml': 250, 'icon': Icons.local_drink_outlined},
    {'label': 'Bottle', 'ml': 500, 'icon': Icons.water_outlined},
    {'label': 'Large', 'ml': 1000, 'icon': Icons.opacity},
  ];

  List<Map<String, dynamic>> todayLogs = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 1).animate(_animController);
    fetchTodayIntake();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> fetchTodayIntake() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final endOfDay = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
    ).toIso8601String();

    try {
      final data = await supabase
          .from('water_intake')
          .select()
          .eq('user_id', user.id)
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay)
          .order('created_at', ascending: false);

      double total = 0;
      for (var record in data) {
        total += (record['amount_ml'] as num).toDouble();
      }

      setState(() {
        totalIntake = total;
        todayLogs = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> addWater(int ml) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('water_intake').insert({
        'user_id': user.id,
        'amount_ml': ml,
      });

      setState(() => totalIntake += ml);
      fetchTodayIntake();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+$ml ml added! 💧'),
          backgroundColor: const Color(0xFF2196F3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> deleteLog(String id, double amount) async {
    try {
      await supabase.from('water_intake').delete().eq('id', id);
      fetchTodayIntake();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Log removed')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void showCustomAmountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Custom Amount',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount (ml)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final ml = int.tryParse(controller.text);
              if (ml != null && ml > 0) {
                Navigator.pop(ctx);
                addWater(ml);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showGoalDialog() {
    final controller = TextEditingController(
      text: dailyGoal.toInt().toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Set Daily Goal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Goal (ml)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = double.tryParse(controller.text);
              if (goal != null && goal > 0) {
                setState(() => dailyGoal = goal);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  double get progress => (totalIntake / dailyGoal).clamp(0.0, 1.0);

  Color get progressColor {
    if (progress < 0.4) return const Color(0xFFFF6B6B);
    if (progress < 0.7) return const Color(0xFFFFB347);
    return const Color(0xFF2196F3);
  }

  String get statusMessage {
    if (progress >= 1.0) return "🎉 Daily goal achieved!";
    if (progress >= 0.7) return "💪 Almost there, keep going!";
    if (progress >= 0.4) return "👍 Good progress!";
    return "💧 Start drinking water!";
  }

  String formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.parse(dateStr).toLocal();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Water Tracker 💧', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Set Goal',
            onPressed: showGoalDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTodayIntake,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1565C0),
                          const Color(0xFF42A5F5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${totalIntake.toInt()} ml',
                          style: GoogleFonts.poppins(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'of ${dailyGoal.toInt()} ml goal',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 14,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          statusMessage,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(progress * 100).toInt()}% completed',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Add Buttons
                  Text(
                    'Quick Add',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: quickAmounts.map((item) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => addWater(item['ml']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    item['icon'],
                                    color: colors.primary,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item['ml']}ml',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                  ),
                                  Text(
                                    item['label'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: colors.primary.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Custom amount button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: showCustomAmountDialog,
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Custom Amount',
                        style: GoogleFonts.poppins(),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Today's log
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Log",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${todayLogs.length} entries',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (todayLogs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No logs yet today.\nStart drinking! 💧',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...todayLogs.map((log) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF2196F3,
                            ).withOpacity(0.15),
                            child: const Icon(
                              Icons.water_drop,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          title: Text(
                            '${log['amount_ml']} ml',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            formatTime(log['created_at']),
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => deleteLog(
                              log['id'].toString(),
                              (log['amount_ml'] as num).toDouble(),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
