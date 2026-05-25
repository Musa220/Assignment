import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SleepTrackerPage extends StatefulWidget {
  const SleepTrackerPage({super.key});

  @override
  State<SleepTrackerPage> createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  TimeOfDay? sleepTime;
  TimeOfDay? wakeTime;
  String selectedQuality = 'Good';
  bool isSaving = false;
  bool isLoading = true;

  List<Map<String, dynamic>> sleepLogs = [];

  final List<Map<String, dynamic>> qualityOptions = [
    {'label': 'Poor', 'icon': '😞', 'color': Colors.red},
    {'label': 'Fair', 'icon': '😐', 'color': Colors.orange},
    {'label': 'Good', 'icon': '😊', 'color': Colors.blue},
    {'label': 'Excellent', 'icon': '😄', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchSleepLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchSleepLogs() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('sleep_logs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        sleepLogs = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Calculate duration between sleep and wake time
  double calculateDuration(TimeOfDay sleep, TimeOfDay wake) {
    int sleepMinutes = sleep.hour * 60 + sleep.minute;
    int wakeMinutes = wake.hour * 60 + wake.minute;

    // If wake time is before sleep time, add 24 hours (slept past midnight)
    if (wakeMinutes <= sleepMinutes) {
      wakeMinutes += 24 * 60;
    }

    return (wakeMinutes - sleepMinutes) / 60.0;
  }

  Future<void> saveSleepLog() async {
    if (sleepTime == null || wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please set both sleep and wake time!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => isSaving = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final sleepDt = DateTime(
      now.year,
      now.month,
      now.day,
      sleepTime!.hour,
      sleepTime!.minute,
    );
    final wakeDt = DateTime(
      now.year,
      now.month,
      now.day,
      wakeTime!.hour,
      wakeTime!.minute,
    );

    final duration = calculateDuration(sleepTime!, wakeTime!);

    try {
      await supabase.from('sleep_logs').insert({
        'user_id': user.id,
        'sleep_time': sleepDt.toIso8601String(),
        'wake_time': wakeDt.toIso8601String(),
        'duration_hours': duration,
        'quality': selectedQuality,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sleep log saved! 😴', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF6C63FF),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      setState(() {
        sleepTime = null;
        wakeTime = null;
        selectedQuality = 'Good';
        isSaving = false;
      });

      fetchSleepLogs();
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      await supabase.from('sleep_logs').delete().eq('id', id);
      fetchSleepLogs();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Log deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> pickTime(bool isSleepTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleepTime
          ? const TimeOfDay(hour: 22, minute: 0)
          : const TimeOfDay(hour: 7, minute: 0),
      helpText: isSleepTime ? 'Select Sleep Time' : 'Select Wake Time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isSleepTime) {
          sleepTime = picked;
        } else {
          wakeTime = picked;
        }
      });
    }
  }

  String formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String formatLogDate(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.parse(dateStr).toLocal();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String formatLogTime(String? dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.parse(dateStr).toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Color qualityColor(String? quality) {
    switch (quality) {
      case 'Poor':
        return Colors.red;
      case 'Fair':
        return Colors.orange;
      case 'Good':
        return Colors.blue;
      case 'Excellent':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String qualityEmoji(String? quality) {
    switch (quality) {
      case 'Poor':
        return '😞';
      case 'Fair':
        return '😐';
      case 'Good':
        return '😊';
      case 'Excellent':
        return '😄';
      default:
        return '😴';
    }
  }

  String durationText(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  // Average sleep from logs
  String get avgSleep {
    if (sleepLogs.isEmpty) return '--';
    double total = sleepLogs.fold(
      0,
      (sum, log) => sum + (log['duration_hours'] as num).toDouble(),
    );
    return durationText(total / sleepLogs.length);
  }

  // Best sleep from logs
  String get bestSleep {
    if (sleepLogs.isEmpty) return '--';
    double best = sleepLogs
        .map((l) => (l['duration_hours'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return durationText(best);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = (sleepTime != null && wakeTime != null)
        ? calculateDuration(sleepTime!, wakeTime!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sleep Tracker 😴', style: GoogleFonts.poppins()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bedtime_outlined), text: 'Log Sleep'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── TAB 1: Log Sleep ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sleep summary banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1B4B), Color(0xFF6C63FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.3),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Text('🌙', style: TextStyle(fontSize: 40)),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Track Your Sleep',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Recommended: 7–9 hours',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Stats row
                      if (sleepLogs.isNotEmpty) ...[
                        Row(
                          children: [
                            _statCard(
                              'Avg Sleep',
                              avgSleep,
                              Colors.purple,
                              Icons.bar_chart,
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              'Best Sleep',
                              bestSleep,
                              Colors.green,
                              Icons.star_outline,
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              'Total Logs',
                              '${sleepLogs.length}',
                              Colors.blue,
                              Icons.list_alt,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Time pickers
                      Text(
                        'Set Sleep Time',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _timePickerCard(
                              label: 'Sleep Time',
                              emoji: '🌙',
                              time: sleepTime,
                              color: const Color(0xFF1A1B4B),
                              onTap: () => pickTime(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timePickerCard(
                              label: 'Wake Time',
                              emoji: '☀️',
                              time: wakeTime,
                              color: const Color(0xFFF59E0B),
                              onTap: () => pickTime(false),
                            ),
                          ),
                        ],
                      ),

                      // Duration preview
                      if (duration != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _durationColor(duration).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _durationColor(duration).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: _durationColor(duration),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Duration: ${durationText(duration)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _durationColor(duration),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _durationFeedback(duration),
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Sleep quality
                      Text(
                        'Sleep Quality',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: qualityOptions.map((q) {
                          final isSelected = selectedQuality == q['label'];
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => selectedQuality = q['label'],
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (q['color'] as Color).withOpacity(
                                            0.15,
                                          )
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? q['color'] as Color
                                          : Colors.grey.withOpacity(0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        q['icon'],
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        q['label'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? q['color'] as Color
                                              : null,
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

                      const SizedBox(height: 28),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isSaving ? null : saveSleepLog,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            isSaving ? 'Saving...' : 'Save Sleep Log',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ── TAB 2: History ──
                sleepLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('😴', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 16),
                            Text(
                              'No sleep logs yet!\nStart tracking tonight.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sleepLogs.length,
                        itemBuilder: (context, index) {
                          final log = sleepLogs[index];
                          final duration = (log['duration_hours'] as num)
                              .toDouble();
                          final quality = log['quality'] as String?;
                          final qColor = qualityColor(quality);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Moon icon with color
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1A1B4B,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        qualityEmoji(quality),
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              durationText(duration),
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: qColor.withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                quality ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: qColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '🌙 ${formatLogTime(log['sleep_time'])}  →  ☀️ ${formatLogTime(log['wake_time'])}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          formatLogDate(log['created_at']),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () =>
                                        _showDeleteDialog(log['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Log',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text('Delete this sleep log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteLog(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _durationColor(double hours) {
    if (hours < 5) return Colors.red;
    if (hours < 7) return Colors.orange;
    if (hours <= 9) return Colors.green;
    return Colors.blue;
  }

  String _durationFeedback(double hours) {
    if (hours < 5) return '😟';
    if (hours < 7) return '😐';
    if (hours <= 9) return '😊';
    return '🌟';
  }

  Widget _timePickerCard({
    required String label,
    required String emoji,
    required TimeOfDay? time,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? formatTimeOfDay(time) : 'Tap to set',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: time != null ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
