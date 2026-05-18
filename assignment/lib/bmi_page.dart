import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BmiCalculatorPage extends StatefulWidget {
  const BmiCalculatorPage({super.key});

  @override
  State<BmiCalculatorPage> createState() {
    return _BmiCalculatorPageState();
  }
}

class _BmiCalculatorPageState extends State<BmiCalculatorPage> {
  TextEditingController weightController = TextEditingController();
  TextEditingController feetController = TextEditingController();
  TextEditingController inchController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  double bmi = 0;
  String category = "";

  void calculateBMI() {
    double weight = double.tryParse(weightController.text) ?? 0;
    double feet = double.tryParse(feetController.text) ?? 0;
    double inch = double.tryParse(inchController.text) ?? 0;

    double totalInches = (feet * 12) + inch;
    double heightMeter = totalInches * 0.0254;

    bmi = weight / (heightMeter * heightMeter);

    if (bmi < 18.5) {
      category = "You are in Underweight category.";
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      category = "You are in Healthy category.";
    } else if (bmi >= 25 && bmi <= 29.9) {
      category = "You are in Overweight category.";
    } else {
      category = "You are in Obese category.";
    }
  }

  void saveBMIRecord() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (bmi == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please calculate BMI first")),
      );
      return;
    }

    try {
      await supabase.from('bmi_records').insert({
        'user_id': user.id,
        'weight': double.tryParse(weightController.text) ?? 0,
        'feet': double.tryParse(feetController.text) ?? 0,
        'inch': double.tryParse(inchController.text) ?? 0,
        'bmi': bmi,
        'category': category,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("BMI record saved successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BMI Calculator", style: GoogleFonts.lora()),
        centerTitle: true,
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SizedBox(
          height: 620,
          width: 340,
          child: Card(
            color: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "BMI Calculator",
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextFormField(
                      controller: weightController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Weight is required";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: "Enter Weight here (in kg)",
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(
                          Icons.monitor_weight_outlined,
                          color: Colors.white,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: feetController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Feet is required";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: "Enter Height here (feet)",
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.height, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: inchController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Inch is required";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: "Enter Height here (inches)",
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.height, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            calculateBMI();
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Calculate",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: saveBMIRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        "Save Record",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Container(
                      height: 60,
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          bmi == 0 ? "BMI:" : "BMI: ${bmi.toStringAsFixed(2)}",
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      category,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
