import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BmiHistoryPage extends StatefulWidget {
  const BmiHistoryPage({super.key});

  @override
  State<BmiHistoryPage> createState() {
    return _BmiHistoryPageState();
  }
}

class _BmiHistoryPageState extends State<BmiHistoryPage> {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> fetchBMIRecords() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    final data = await supabase
        .from('bmi_records')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return data;
  }

  void deleteBMIRecord(String id) async {
    try {
      await supabase.from('bmi_records').delete().eq('id', id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("BMI record deleted successfully")),
      );

      setState(() {});
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

      String category = "";

      if (bmi < 18.5) {
        category = "Underweight";
      } else if (bmi >= 18.5 && bmi <= 24.9) {
        category = "Healthy";
      } else if (bmi >= 25 && bmi <= 29.9) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("BMI record updated successfully")),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void showEditDialog(Map<String, dynamic> record) {
    TextEditingController weightController = TextEditingController(
      text: record['weight'].toString(),
    );

    TextEditingController feetController = TextEditingController(
      text: record['feet'].toString(),
    );

    TextEditingController inchController = TextEditingController(
      text: record['inch'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit BMI Record"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Weight",
                  suffixText: "kg",
                ),
              ),
              TextField(
                controller: feetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Feet",
                  suffixText: "ft",
                ),
              ),
              TextField(
                controller: inchController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Inch",
                  suffixText: "in",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                double weight = double.tryParse(weightController.text) ?? 0;
                double feet = double.tryParse(feetController.text) ?? 0;
                double inch = double.tryParse(inchController.text) ?? 0;

                Navigator.pop(context);

                updateBMIRecord(record['id'], weight, feet, inch);
              },
              child: const Text(
                "Update",
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Record"),
          content: const Text(
            "Are you sure you want to delete this BMI record?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteBMIRecord(id);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String formatDate(String? dateText) {
    if (dateText == null) {
      return "No date";
    }

    DateTime date = DateTime.parse(dateText);

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: Text("BMI History", style: GoogleFonts.lora()),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchBMIRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Text(
                "No BMI records found",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];

              return Card(
                color: Colors.deepPurple,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    "BMI: ${record['bmi'].toStringAsFixed(2)}",
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Weight: ${record['weight']} kg\n"
                      "Height: ${record['feet']} ft ${record['inch']} in\n"
                      "Category: ${record['category']}\n"
                      "Date: ${formatDate(record['created_at'])}",
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showEditDialog(record);
                        },
                        icon: const Icon(Icons.edit, color: Colors.amber),
                      ),
                      IconButton(
                        onPressed: () {
                          showDeleteDialog(record['id']);
                        },
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
