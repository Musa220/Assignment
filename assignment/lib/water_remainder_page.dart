import 'package:assignment/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterReminderPage extends StatefulWidget {
  const WaterReminderPage({super.key});

  @override
  State<WaterReminderPage> createState() => _WaterReminderPageState();
}

class _WaterReminderPageState extends State<WaterReminderPage> {
  bool isReminderOn = false;
  int selectedInterval = 2;
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 22, minute: 0);
  int pendingCount = 0;
  bool isSaving = false;

  final List<int> intervalOptions = [1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    NotificationService.requestPermission(); // ✅ static call
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isReminderOn = prefs.getBool('water_reminder_on') ?? false;
      selectedInterval = prefs.getInt('water_reminder_interval') ?? 2;
      final startH = prefs.getInt('water_reminder_start_hour') ?? 8;
      final startM = prefs.getInt('water_reminder_start_minute') ?? 0;
      final endH = prefs.getInt('water_reminder_end_hour') ?? 22;
      final endM = prefs.getInt('water_reminder_end_minute') ?? 0;
      startTime = TimeOfDay(hour: startH, minute: startM);
      endTime = TimeOfDay(hour: endH, minute: endM);
    });
    _refreshPendingCount();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminder_on', isReminderOn);
    await prefs.setInt('water_reminder_interval', selectedInterval);
    await prefs.setInt('water_reminder_start_hour', startTime.hour);
    await prefs.setInt('water_reminder_start_minute', startTime.minute);
    await prefs.setInt('water_reminder_end_hour', endTime.hour);
    await prefs.setInt('water_reminder_end_minute', endTime.minute);
  }

  Future<void> _refreshPendingCount() async {
    final pending =
        await NotificationService.getPendingNotifications(); // ✅ static
    setState(() => pendingCount = pending.length);
  }

  Future<void> _applyReminder() async {
    setState(() => isSaving = true);

    try {
      if (isReminderOn) {
        await NotificationService.scheduleWaterReminder(
          // ✅ static
          intervalHours: selectedInterval,
          startTime: startTime,
          endTime: endTime,
        );
      } else {
        await NotificationService.cancelWaterReminders(); // ✅ static
      }

      await _saveSettings();
      await _refreshPendingCount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReminderOn
                ? '✅ Reminders set! Every $selectedInterval hour(s)'
                : '🔕 Reminders cancelled',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: isReminderOn ? const Color(0xFF2196F3) : Colors.grey,
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

    setState(() => isSaving = false);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
      helpText: isStart ? 'Select Start Time' : 'Select End Time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int get _reminderCount {
    int startM = startTime.hour * 60 + startTime.minute;
    int endM = endTime.hour * 60 + endTime.minute;
    int intervalM = selectedInterval * 60;
    if (endM <= startM) return 0;
    return ((endM - startM) ~/ intervalM) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Water Reminder 🔔', style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 48)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay Hydrated!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Get reminders to drink\nwater throughout the day',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Master toggle ──
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            (isReminderOn
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey)
                                .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isReminderOn
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        color: isReminderOn
                            ? const Color(0xFF2196F3)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Water Reminders',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isReminderOn ? 'Enabled' : 'Disabled',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isReminderOn
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isReminderOn,
                      activeColor: const Color(0xFF2196F3),
                      onChanged: (val) => setState(() => isReminderOn = val),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Settings (only active when ON) ──
            AnimatedOpacity(
              opacity: isReminderOn ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !isReminderOn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reminder Interval',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: intervalOptions.map((hour) {
                        final isSelected = selectedInterval == hour;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedInterval = hour),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF2196F3)
                                      : colors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2196F3)
                                        : Colors.grey.withOpacity(0.2),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$hour',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : null,
                                      ),
                                    ),
                                    Text(
                                      hour == 1 ? 'hour' : 'hours',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.grey,
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

                    const SizedBox(height: 24),

                    Text(
                      'Active Hours',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notifications only sent during this time',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _timeCard(
                            label: 'Start Time',
                            emoji: '🌅',
                            time: startTime,
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward,
                            color: colors.primary,
                          ),
                        ),
                        Expanded(
                          child: _timeCard(
                            label: 'End Time',
                            emoji: '🌙',
                            time: endTime,
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF2196F3),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You will receive ~$_reminderCount reminder(s) per day, every $selectedInterval hour(s) from ${_formatTime(startTime)} to ${_formatTime(endTime)}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF2196F3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Save button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _applyReminder,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isReminderOn
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                      ),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : isReminderOn
                      ? 'Save & Activate'
                      : 'Save (Reminders Off)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isReminderOn
                      ? const Color(0xFF2196F3)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Test notification ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.showTestNotification(); // ✅ static
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Test notification sent! 💧',
                        style: GoogleFonts.poppins(),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: Text(
                  'Send Test Notification',
                  style: GoogleFonts.poppins(),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            if (pendingCount > 0) ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '$pendingCount notification(s) scheduled',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _timeCard({
    required String label,
    required String emoji,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(time),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
