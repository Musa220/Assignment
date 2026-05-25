import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BmiHistoryPage extends StatefulWidget {
  const BmiHistoryPage({super.key});

  @override
  State<BmiHistoryPage> createState() => _BmiHistoryPageState();
}

class _BmiHistoryPageState extends State<BmiHistoryPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  List<dynamic> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchBMIRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchBMIRecords() async {
    setState(() => isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final data = await supabase
          .from('bmi_records')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        records = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void deleteBMIRecord(String id) async {
    try {
      await supabase.from('bmi_records').delete().eq('id', id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("BMI record deleted")));
      fetchBMIRecords();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void updateBMIRecord(
    String id,
    double weight,
    double feet,
    double inch,
  ) async {
    try {
      double totalInches = (feet * 12) + inch;
      double heightMeter = totalInches * 0.0254;
      double bmi = weight / (heightMeter * heightMeter);

      String category;
      if (bmi < 18.5) {
        category = "Underweight";
      } else if (bmi <= 24.9) {
        category = "Healthy";
      } else if (bmi <= 29.9) {
        category = "Overweight";
      } else {
        category = "Obese";
      }

      await supabase
          .from('bmi_records')
          .update({
            'weight': weight,
            'feet': feet,
            'inch': inch,
            'bmi': bmi,
            'category': category,
          })
          .eq('id', id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("BMI record updated")));
      fetchBMIRecords();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void showEditDialog(Map<String, dynamic> record) {
    final weightCtrl = TextEditingController(text: record['weight'].toString());
    final feetCtrl = TextEditingController(text: record['feet'].toString());
    final inchCtrl = TextEditingController(text: record['inch'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit BMI Record",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Weight (kg)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: feetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Feet",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: inchCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Inch",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(weightCtrl.text) ?? 0;
              final feet = double.tryParse(feetCtrl.text) ?? 0;
              final inch = double.tryParse(inchCtrl.text) ?? 0;
              Navigator.pop(ctx);
              updateBMIRecord(record['id'], weight, feet, inch);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Record",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteBMIRecord(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String formatDate(String? d) {
    if (d == null) return '';
    final dt = DateTime.parse(d);
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  Color categoryColor(String? cat) {
    switch (cat) {
      case 'Underweight':
        return Colors.blue;
      case 'Healthy':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Build chart data from records (oldest first)
  List<FlSpot> get chartSpots {
    final reversed = records.reversed.toList();
    return List.generate(reversed.length, (i) {
      final bmi = (reversed[i]['bmi'] as num).toDouble();
      return FlSpot(i.toDouble(), bmi);
    });
  }

  Widget buildChart() {
    if (records.length < 2) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Text(
          'Need at least 2 records\nto show the chart',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    final spots = chartSpots;
    final bmiValues = spots.map((s) => s.y).toList();
    final minY = (bmiValues.reduce((a, b) => a < b ? a : b) - 2)
        .clamp(0, 50)
        .toDouble();
    final maxY = (bmiValues.reduce((a, b) => a > b ? a : b) + 2).toDouble();
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BMI Trend',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: colors.primary.withOpacity(0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text(
                        val.toStringAsFixed(0),
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        final rev = records.reversed.toList();
                        if (idx < 0 || idx >= rev.length) {
                          return const SizedBox.shrink();
                        }
                        final dt = DateTime.parse(rev[idx]['created_at']);
                        return Text(
                          '${dt.day}/${dt.month}',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: colors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withOpacity(0.25),
                          colors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Healthy range reference line at 22 (middle of healthy)
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 18.5),
                      FlSpot((spots.length - 1).toDouble(), 18.5),
                    ],
                    isCurved: false,
                    color: Colors.green.withOpacity(0.4),
                    barWidth: 1,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 24.9),
                      FlSpot((spots.length - 1).toDouble(), 24.9),
                    ],
                    isCurved: false,
                    color: Colors.orange.withOpacity(0.4),
                    barWidth: 1,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, 'Healthy range'),
              const SizedBox(width: 16),
              _legendDot(Colors.orange, 'Overweight'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 3, color: color.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("BMI History", style: GoogleFonts.poppins()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Chart'),
            Tab(icon: Icon(Icons.list_alt), text: 'Records'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── TAB 1: Chart ──
                SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildChart(),
                      const SizedBox(height: 20),
                      // Stats summary
                      if (records.isNotEmpty) ...[
                        Text(
                          'Summary',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard(
                              'Latest BMI',
                              (records.first['bmi'] as num).toStringAsFixed(1),
                              records.first['category'],
                              categoryColor(records.first['category']),
                            ),
                            const SizedBox(width: 12),
                            _statCard(
                              'Records',
                              '${records.length}',
                              'total saved',
                              colors.primary,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── TAB 2: Records list ──
                records.isEmpty
                    ? Center(
                        child: Text(
                          "No BMI records found",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final cat = record['category'] as String? ?? '';
                          final catColor = categoryColor(cat);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: catColor.withOpacity(0.15),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: catColor,
                                        fontWeight: FontWeight.bold,
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
                                              "BMI: ${(record['bmi'] as num).toStringAsFixed(2)}",
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
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
                                                color: catColor.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                cat,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: catColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Weight: ${record['weight']} kg  •  ${record['feet']}ft ${record['inch']}in",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "Date: ${formatDate(record['created_at'])}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        onPressed: () => showEditDialog(record),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            showDeleteDialog(record['id']),
                                      ),
                                    ],
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

  Widget _statCard(String title, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              sub,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
