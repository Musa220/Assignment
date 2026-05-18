import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  double bmi = 0;
  String category = "";

  void calculateBMI() {
    double weight = double.parse(weightController.text);
    double feet = double.parse(feetController.text);
    double inch = double.parse(inchController.text);

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
          height: 560,
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

                    SizedBox(height: 25),

                    TextFormField(
                      controller: weightController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Weight is required";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
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

                    SizedBox(height: 20),

                    TextFormField(
                      controller: feetController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Feet is required";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
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

                    SizedBox(height: 20),

                    TextFormField(
                      controller: inchController,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Inch is required";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
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

                    SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          calculateBMI();
                        }

                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 35,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        "Calculate",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                    SizedBox(height: 25),

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

                    SizedBox(height: 20),

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
